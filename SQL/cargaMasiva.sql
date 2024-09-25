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

        -- Insertar en la tabla Movimiento
        INSERT INTO dbo.Movimiento (IdEmpleado, IdTipoMovimiento, Fecha, Monto, NuevoSaldo, IdPostByUser, PostInIP, PostTime)
        SELECT 
            (SELECT Id FROM dbo.Empleado WHERE ValorDocumentoIdentidad = Movimiento.value('@ValorDocId', 'VARCHAR(128)')),
            (SELECT Id FROM dbo.TipoMovimiento WHERE Nombre = Movimiento.value('@IdTipoMovimiento', 'VARCHAR(128)')),
            Movimiento.value('@Fecha', 'DATETIME'),
            Movimiento.value('@Monto', 'INT'),
            Movimiento.value('@Monto', 'INT'),  -- Ajustar el nuevo saldo correctamente según la lógica
            (SELECT Id FROM dbo.Usuario WHERE Username = Movimiento.value('@PostByUser', 'VARCHAR(128)')),
            Movimiento.value('@PostInIP', 'VARCHAR(64)'),
            Movimiento.value('@PostTime', 'DATETIME')
        FROM @xmlData.nodes('/Datos/Movimientos/movimiento') AS T(Movimiento);

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