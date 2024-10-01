ALTER PROCEDURE CargarDatosDesdeXML
    @xmlData XML
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Insertar en la tabla Puesto
        INSERT INTO dbo.Puesto (Nombre, SalarioxHora)
        SELECT 
            Puesto.value('@Nombre', 'VARCHAR(128)'),
            Puesto.value('@SalarioxHora', 'MONEY')
        FROM @xmlData.nodes('/Datos/Puestos/Puesto') AS T(Puesto);

        -- Insertar en la tabla TipoEvento
        INSERT INTO dbo.TipoEvento (Id, Nombre)
        SELECT 
            TipoEvento.value('@Id', 'INT'),
            TipoEvento.value('@Nombre', 'VARCHAR(128)')
        FROM @xmlData.nodes('/Datos/TiposEvento/TipoEvento') AS T(TipoEvento);

        -- Insertar en la tabla TipoMovimiento
        INSERT INTO dbo.TipoMovimiento (Id, Nombre, TipoAccion)
        SELECT 
            TipoMovimiento.value('@Id', 'INT'),
            TipoMovimiento.value('@Nombre', 'VARCHAR(128)'),
            TipoMovimiento.value('@TipoAccion', 'VARCHAR(128)')
        FROM @xmlData.nodes('/Datos/TiposMovimientos/TipoMovimiento') AS T(TipoMovimiento);

        -- Insertar en la tabla Usuario
        INSERT INTO dbo.Usuario (Id, Username, Pass)
        SELECT 
            Usuario.value('@Id', 'INT'),
            Usuario.value('@Nombre', 'VARCHAR(128)'),
            Usuario.value('@Pass', 'VARCHAR(128)')
        FROM @xmlData.nodes('/Datos/Usuarios/usuario') AS T(Usuario);

        -- Insertar en la tabla Empleado
        INSERT INTO dbo.Empleado (IdPuesto, ValorDocumentoIdentidad, Nombre, FechaContratacion)
        SELECT 
            (SELECT Id FROM dbo.Puesto WHERE Nombre = Empleado.value('@Puesto', 'VARCHAR(128)')),
            Empleado.value('@ValorDocumentoIdentidad', 'VARCHAR(128)'),
            Empleado.value('@Nombre', 'VARCHAR(128)'),
            Empleado.value('@FechaContratacion', 'DATE')
        FROM @xmlData.nodes('/Datos/Empleados/empleado') AS T(Empleado);

        -- Insertar los movimientos en la tabla Movimiento y calcular el saldo en una sola operación
        INSERT INTO dbo.Movimiento (IdEmpleado, IdTipoMovimiento, Fecha, Monto, NuevoSaldo, IdPostByUser, PostInIP, PostTime)
        SELECT 
            E.Id AS IdEmpleado,
            TM.Id AS IdTipoMovimiento,
            M.Movimiento.value('@Fecha', 'DATETIME') AS Fecha,
            M.Movimiento.value('@Monto', 'INT') AS Monto,
            -- Calcular el nuevo saldo al insertar
            (E.SaldoVacaciones + 
             CASE 
                 WHEN TM.TipoAccion = 'Credito' THEN M.Movimiento.value('@Monto', 'INT')
                 WHEN TM.TipoAccion = 'Debito' THEN -M.Movimiento.value('@Monto', 'INT')
                 ELSE 0
             END) AS NuevoSaldo,
            (SELECT Id FROM dbo.Usuario WHERE Username = M.Movimiento.value('@PostByUser', 'VARCHAR(128)')) AS IdPostByUser,
            M.Movimiento.value('@PostInIP', 'VARCHAR(64)') AS PostInIP,
            M.Movimiento.value('@PostTime', 'DATETIME') AS PostTime
        FROM @xmlData.nodes('/Datos/Movimientos/movimiento') AS M(Movimiento)
        INNER JOIN dbo.Empleado E ON E.ValorDocumentoIdentidad = M.Movimiento.value('@ValorDocId', 'VARCHAR(128)')
        INNER JOIN dbo.TipoMovimiento TM ON TM.Nombre = M.Movimiento.value('@IdTipoMovimiento', 'VARCHAR(128)');

        -- Actualizar los saldos de vacaciones de todos los empleados de una sola vez
        UPDATE E
        SET SaldoVacaciones = E.SaldoVacaciones + 
            (SELECT SUM(CASE 
                            WHEN TM.TipoAccion = 'Credito' THEN M.Movimiento.value('@Monto', 'INT') 
                            WHEN TM.TipoAccion = 'Debito' THEN -M.Movimiento.value('@Monto', 'INT') 
                            ELSE 0
                        END)
             FROM @xmlData.nodes('/Datos/Movimientos/movimiento') AS M(Movimiento)
             INNER JOIN dbo.TipoMovimiento TM ON TM.Nombre = M.Movimiento.value('@IdTipoMovimiento', 'VARCHAR(128)')
             WHERE E.ValorDocumentoIdentidad = M.Movimiento.value('@ValorDocId', 'VARCHAR(128)'))
        FROM dbo.Empleado E;

        -- Insertar en la tabla Error
        INSERT INTO dbo.Error (Codigo, Descripcion)
        SELECT 
            Error.value('@Codigo', 'INT'),
            Error.value('@Descripcion', 'VARCHAR(128)')
        FROM @xmlData.nodes('/Datos/Error/error') AS T(Error);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        -- Manejar el error
        INSERT INTO dbo.DBErrors (UserName, Number, State, Severity, Line, [Procedure], Message, DateTime)
        VALUES (
            SYSTEM_USER,
            ERROR_NUMBER(),
            ERROR_STATE(),
            ERROR_SEVERITY(),
            ERROR_LINE(),
            ERROR_PROCEDURE(),
            ERROR_MESSAGE(),
            GETDATE()
        );
    END CATCH;
END;
GO
