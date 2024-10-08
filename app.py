from datetime import datetime
from flask import Flask, jsonify, redirect, render_template, request, url_for
import pyodbc
from flask_cors import CORS

app = Flask(__name__)
CORS(app)
# Configuración de la conexión a la base de datos
def get_db_connection():
    connection = pyodbc.connect(
        'DRIVER={ODBC Driver 17 for SQL Server};'
        #'SERVER=DESKTOP-HUTR52P;'
        'SERVER=ERICKPC;'
        'DATABASE=proyecto2;'
        'UID=hola;' 
        'PWD=12345678'
    )
    return connection

@app.route('/')
def index():
    return render_template('login.html')

@app.route('/login', methods=['GET'])
def login():
    username = request.args.get('usuario')
    password = request.args.get('contrasena')

    conn = get_db_connection()
    cursor = conn.cursor()

    ip = request.remote_addr
    time = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

    try:
        cursor.execute("""
                DECLARE	@return_value int,
		        @OutResultCode int

                EXEC	@return_value = [dbo].[ValidarCredenciales]
		        @username = ?,
		        @password = ?,
		        @PostInIP = ?,
		        @PostTime = ?,
		        @OutResultCode = @OutResultCode OUTPUT

                SELECT	@OutResultCode as N'@OutResultCode'
                """, (username, password, ip, time))

        out_result_code = cursor.fetchone()[0]
        print(out_result_code)


        conn.commit()

        if out_result_code == 0:
            return redirect(url_for('pagina_principal', username=username))
        else:
            return jsonify({'OutResultCode': out_result_code})
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        conn.close()

@app.route('/pagina_principal/<username>')
def pagina_principal(username):
    return render_template('index.html', username=username)

@app.route('/insertaremp', methods=['GET'])
def abrir_insertar_empleado():
    username = request.args.get('username')
    return render_template('insertaremp.html', username=username)

@app.route('/logout')
def logout():
    username = request.args.get('username')
    ip = request.remote_addr

    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("""
        DECLARE @return_value int

        EXEC @return_value = [dbo].[logout]
            @username = ?,
            @PostInIP = ?

        SELECT 'Return Value' = @return_value
    """, (username, ip))

    conn.commit()
    cursor.close()
    conn.close()
    return render_template('login.html')

@app.route('/puestos', methods=['GET'])
def listar_puestos():
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute("""EXEC	[dbo].[GetPuestos]""")

        puestos = cursor.fetchall()
        cursor.nextset()

        puestos_lista = []

        for puesto in puestos:
            puestos_lista.append({
                'Nombre': puesto[0]
            })

        return jsonify({'Puestos': puestos_lista})
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        conn.close()

# Ruta para ejecutar el procedimiento almacenado
@app.route('/insertar_empleado', methods=['POST'])
def insertar_empleado():
    puesto = request.json.get('Puesto')
    valor_documento_identidad = request.json.get('valorDocumento')
    nombre = request.json.get('nombre')
    fecha_contratacion = request.json.get('fechaContratacion')
    username = request.json.get('username')
    post_in_ip = request.remote_addr

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        # Declarar y ejecutar el procedimiento almacenado con OUTPUT
        cursor.execute("""
                DECLARE	@return_value int,
		            @OutResulTCode int

                EXEC	@return_value = [dbo].[InsertarEmpleado]
		            @Puesto = ?,
		            @ValorDocumentoIdentidad = ?,
                    @Nombre = ?,
                    @FechaContratacion = ?,
                    @Username = ?,
                    @PostInIP = ?,
		            @OutResulTCode = @OutResulTCode OUTPUT

                SELECT	@OutResulTCode as N'@OutResultCode'
                """, (puesto, valor_documento_identidad, nombre, fecha_contratacion, username, post_in_ip))

        # Obtener el valor del código de resultado
        out_result_code = cursor.fetchone()[0]
        print(out_result_code)
        if out_result_code !=0:
            cursor.execute("""EXEC	[dbo].[GetError]
		    @Codigo = ?""", (out_result_code))
            error = cursor.fetchone()[0]
            print(error)
            conn.commit()
            cursor.close()
            conn.close()
            return jsonify({'OutResultCode': out_result_code, 'Error': error})
        else:
            conn.commit()
            cursor.close()
            conn.close()
            return jsonify({'OutResultCode': out_result_code})
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/listar_empleados', methods=['GET'])
def listar_empleados():
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute("""
            DECLARE @OutResultCode INT;

            EXEC [dbo].[ListarEmpleado]
            @OutResultCode = @OutResultCode OUTPUT;

            SELECT @OutResultCode AS OutResultCode;
        """)

        empleados = cursor.fetchall()

        cursor.nextset() 
        out_result_code = cursor.fetchone()[0]

        empleados_lista = []
        for empleado in empleados:
            empleados_lista.append({
                'Id': empleado[0],
                'ValorDocumentoIdentidad': empleado[1],
                'Nombre': empleado[2],
                'Puesto': empleado[3],
                'FechaContratacion': empleado[4].strftime('%d-%m-%Y'),
                'SaldoVacaciones': empleado[5],
                'EsActivo': empleado[6],
            })

        conn.commit()

        return jsonify({'OutResultCode': out_result_code, 'Empleados': empleados_lista})

    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        conn.close()

@app.route('/empleados/filtro', methods=['GET'])
def filtro_doc():
    bus = request.args.get('search')
    user = request.args.get('username')
    conn = get_db_connection()
    cursor = conn.cursor()
    ip = request.remote_addr
    time = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    empleados_json = []
    if bus.isdigit():
        cursor.execute("""
        EXEC [dbo].[filtroEmpDoc]
        @valorDocumento = ?,
        @Username = ?,
        @PostInIP = ?,
        @PostTime = ?
        """, (bus, user, ip, time))  # Coloca los parámetros correctamente

    else:
        cursor.execute("""
        EXEC [dbo].[GetFiltroEmpleadosNombre]
        @nombre = ?,
        @Username = ?,
        @PostInIP = ?,
        @PostTime = ?
        """, (bus, user, ip, time))
    empleados = cursor.fetchall()
    
    for empleado in empleados:
        empleado_json = {
            'Id': empleado[0],
            'ValorDocumentoIdentidad': empleado[1],
            'Nombre': empleado[2],
            'Puesto': empleado[3],
            'FechaContratacion': empleado[4].strftime('%d-%m-%Y'),
            'SaldoVacaciones': empleado[5],
            'EsActivo': empleado[6]
        }
        empleados_json.append(empleado_json)
    conn.commit()
    cursor.close()
    return jsonify(empleados_json)

@app.route('/modificaremp/getEmpleado', methods=['GET'])
def get_empleado():
    search = request.args.get('search')
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("""
        EXEC [dbo].[getEmpleadoById]
        @Id = ?
    """, (search))
    empleado = cursor.fetchone()
    empleado_json = {
        'Id': empleado[0],
        'ValorDocumentoIdentidad': empleado[1],
        'Nombre': empleado[2],
        'Puesto': empleado[3],
        'FechaContratacion': empleado[4].strftime('%Y-%m-%d'),
        'SaldoVacaciones': empleado[5],
        'EsActivo': empleado[6]
    }
    conn.commit()
    cursor.close()
    return jsonify(empleado_json)

@app.route('/modificaremp', methods=['GET'])
def abrir_modificar_empleado():
    username = request.args.get('username')
    documento = request.args.get('documento')
    return render_template('modificaremp.html', username=username, documento=documento)

@app.route('/modificaremp', methods=['POST'])
def modificar_empleado():
    puesto = request.json.get('Puesto')
    valorDocumentoAnterior = request.json.get('valorDocumentoAnterior')
    valorDocumentoNuevo = request.json.get('valorDocumentoNuevo')
    nombreAnterior = request.json.get('nombreAnterior')
    nombreNuevo = request.json.get('nombreNuevo')
    saldoVacaciones = request.json.get('saldoVacaciones')
    username = request.json.get('username')
    post_in_ip = request.remote_addr

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute("""
                DECLARE	@return_value int,
                    @OutResulTCode int

                EXEC	@return_value = [dbo].[ModificarEmpleadoPorDocumento]
		            @ValorDocumentoIdentidadAnterior = ?,
		            @ValorDocumentoIdentidadNuevo = ?,
		            @NombreAnterior = ?,
		            @NombreNuevo = ?,
		            @PuestoNuevo = ?,
		            @SaldoVacaciones = ?,
		            @Username = ?,
		            @PostInIP = ?,
		            @OutResultCode = @OutResultCode OUTPUT

                SELECT	@OutResulTCode as N'@OutResultCode'
                """, (valorDocumentoAnterior, valorDocumentoNuevo, nombreAnterior, nombreNuevo, puesto, saldoVacaciones, username, post_in_ip))

        out_result_code = cursor.fetchone()[0]

        if out_result_code !=0:
            cursor.execute("""EXEC	[dbo].[GetError]
            @Codigo = ?""", (out_result_code))
            error = cursor.fetchone()[0]
            conn.commit()
            cursor.close()
            conn.close()
            return jsonify({'OutResultCode': out_result_code, 'Error': error})
        else:
            conn.commit()
            cursor.close()
            conn.close()
            return jsonify({'OutResultCode': out_result_code})
    
    finally:
        print()
        

@app.route('/eliminaremp', methods=['POST'])
def eliminar_empleado():
    documento = request.json.get('valorDocumento')
    username = request.json.get('username')
    confrimacion = request.json.get('confirmacion')
    post_in_ip = request.remote_addr

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute("""
                DECLARE	@return_value int,
                    @OutResulTCode int

                EXEC	@return_value = [dbo].[IntentoBorrado]
                    @ValorDocumentoIdentidad = ?,
                    @Username = ?,
                    @Confirmacion = ?,
                    @PostInIP = ?,
                    @OutResultCode = @OutResultCode OUTPUT

                SELECT	@OutResulTCode as N'@OutResultCode'
                """, (documento, username, confrimacion, post_in_ip))

        out_result_code = cursor.fetchone()[0]

        if out_result_code !=0:
            cursor.execute("""EXEC	[dbo].[GetError]
            @Codigo = ?""", (out_result_code))
            error = cursor.fetchone()[0]
            conn.commit()
            cursor.close()
            conn.close()
            return jsonify({'OutResultCode': out_result_code, 'Error': error})
        else:
            conn.commit()
            cursor.close()
            conn.close()
            return jsonify({'OutResultCode': out_result_code})
 
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    
    finally:
        print()  

@app.route('/movimientoemp', methods=['GET'])
def abrir_movimiento_empleado():
    username = request.args.get('username')
    documento = request.args.get('documento')
    return render_template('movimientos.html', username=username, documento=documento)

@app.route('/getMovimientos', methods=['GET'])
def get_movimientos():
    documento = request.args.get('documento')
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("""
        DECLARE	@OutResultCode int

        EXEC	[dbo].[ListarMovimientoByDocumentoIdentidad]
		    @ValorDocumentoIdentidad = ?,
		    @OutResultCode = @OutResultCode OUTPUT

        SELECT	@OutResultCode as N'@OutResultCode'
    """, (documento))
    movimientos = cursor.fetchall()
    movimientos_json = []
    for movimiento in movimientos:
        movimiento_json = {
            'Nombre': movimiento[0],
            'Tipo': movimiento[1],
            'Fecha': str(movimiento[2].strftime('%d/%m/%Y')),
            'Monto': movimiento[3],
            'NuevoSaldo': movimiento[4],
            'Username': movimiento[5],
            'PostInIP': movimiento[6],
            'PostTime': movimiento[7].strftime('%H:%M:%S')
        }
        movimientos_json.append(movimiento_json)
    conn.commit()
    cursor.close()
    return jsonify(movimientos_json)

@app.route('/insertmovimiento', methods=['GET'])
def abrir_insertar_movimiento_empleado():
    username = request.args.get('username')
    documento = request.args.get('documento')
    return render_template('insertarMovimiento.html', username=username, documento=documento)

@app.route('/insertarMovimiento', methods=['POST'])
def insertar_movimiento():
    documento = request.json.get('documento')
    tipo = request.json.get('tipo')
    monto = request.json.get('monto')
    username = request.json.get('username')
    post_in_ip = request.remote_addr

    print(documento,tipo,monto,username)
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute("""
                DECLARE	@OutResulTCode int

                EXEC   [dbo].[InsertarMovimiento]
                    @ValorDocumentoIdentidad = ?,
                    @TipoMovimiento = ?,
                    @Monto = ?,
                    @Username = ?,
                    @PostInIP = ?,
                    @OutResultCode = @OutResultCode OUTPUT

                SELECT	@OutResulTCode as N'@OutResultCode'
                """, (documento, tipo, monto, username, post_in_ip))

        out_result_code = cursor.fetchone()[0]

        if out_result_code !=0:
            cursor.execute("""EXEC	[dbo].[GetError]
            @Codigo = ?""", (out_result_code))
            error = cursor.fetchone()[0]
            conn.commit()
            cursor.close()
            conn.close()
            return jsonify({'OutResultCode': out_result_code, 'Error': error})
        else:
            conn.commit()
            cursor.close()
            conn.close()
            return jsonify({'OutResultCode': out_result_code})
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/tipoMovs', methods=['GET'])
def listar_movimientos():
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        cursor.execute("""EXEC	[dbo].[GetTiposMovimiento]""")

        tms = cursor.fetchall()
        cursor.nextset()

        tipos = []

        for tm in tms:
            tipos.append({
                'nombre': tm[0]
            })

        return jsonify({'TipoMovimientos': tipos})
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        conn.close()

if __name__ == '__main__':
    app.run(debug=True)