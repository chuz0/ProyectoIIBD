from datetime import datetime
from flask import Flask, jsonify, redirect, render_template, request, url_for
import pyodbc
from flask_cors import CORS

app = Flask(__name__)
CORS(app)
1
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
    print(time)

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

# Ruta para ejecutar el procedimiento almacenado
@app.route('/insertar_empleado', methods=['POST'])
def insertar_empleado():
    puesto = request.json.get('puesto')
    valor_documento_identidad = request.json.get('valor_documento_identidad')
    nombre = request.json.get('nombre')
    fecha_contratacion = request.json.get('fecha_contratacion')
    username = request.json.get('username')
    post_in_ip = request.json.get('post_in_ip')
    post_time = request.json.get('post_time')

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
                    @PostTime = ?,
		            @OutResulTCode = @OutResulTCode OUTPUT

                SELECT	@OutResulTCode as N'@OutResultCode'
                """, (puesto, valor_documento_identidad, nombre, fecha_contratacion, username, post_in_ip, post_time))

        # Obtener el valor del código de resultado
        out_result_code = cursor.fetchone()[0]

        # Confirmar la transacción si todo es exitoso
        conn.commit()
    except Exception as e:
        return jsonify({'error': str(e)}), 500
    finally:
        # Cerrar el cursor y la conexión
        cursor.close()
        conn.close()

    # Devolver el código de resultado como respuesta
    return jsonify({'OutResultCode': out_result_code})


# Ruta para obtener los empleados
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


if __name__ == '__main__':
    app.run(debug=True)