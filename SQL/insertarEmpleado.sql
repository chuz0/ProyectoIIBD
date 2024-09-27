ALTER PROCEDURE [dbo].[InsertarEmpleado]
    @Puesto VARCHAR(128), 
    @ValorDocumentoIdentidad VARCHAR(128),  
    @Nombre VARCHAR(128), 
    @FechaContratacion DATE,
    @Username VARCHAR(128),
    @PostInIP VARCHAR(64),
    @OutResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Inicializamos el código de salida
        SET @OutResultCode = 0;
        
        -- Verificar si el empleado ya existe por Nombre
        IF EXISTS (SELECT 1 FROM dbo.Empleado WHERE Nombre = @Nombre)
        BEGIN
            SET @OutResultCode = 50005; -- Error por nombre duplicado

            -- Registrar en la bitácora el evento de error por nombre duplicado
            INSERT INTO dbo.bitacoraEvento(
                IdTipoEvento,
                IdUsuario,
                Fecha,
                Descripcion,
                PostInIP,
                PostTime
            ) VALUES (
                5, -- Evento de inserción no exitosa
                (SELECT Id FROM dbo.Usuario WHERE Username = @Username),
                GETDATE(),
                'Error: Nombre duplicado en la inserción del empleado',
                @PostInIP,
                GETDATE()
            );
        END
        ELSE
        BEGIN
            -- Verificar si el empleado ya existe por ValorDocumentoIdentidad
            IF EXISTS (SELECT 1 FROM dbo.Empleado WHERE ValorDocumentoIdentidad = @ValorDocumentoIdentidad)
            BEGIN
                SET @OutResultCode = 50004; -- Error por documento duplicado

                -- Registrar en la bitácora el evento de error por documento duplicado
                INSERT INTO dbo.bitacoraEvento(
                    IdTipoEvento,
                    IdUsuario,
                    Fecha,
                    Descripcion,
                    PostInIP,
                    PostTime
                ) VALUES (
                    5, -- Evento de inserción no exitosa
                    (SELECT Id FROM dbo.Usuario WHERE Username = @Username),
                    GETDATE(),
                    'Error: Documento de identidad duplicado en la inserción del empleado',
                    @PostInIP,
                    GETDATE()
                );
            END
            ELSE
            BEGIN
                -- Buscar el Id del puesto
                DECLARE @IdPuesto INT;
                SELECT @IdPuesto = Id FROM dbo.Puesto WHERE Nombre = @Puesto;
                
                -- Verificar si el puesto existe
                IF @IdPuesto IS NULL
                BEGIN
                    SET @OutResultCode = 50006; -- Error si el puesto no existe
                END
                ELSE
                BEGIN
                    BEGIN TRANSACTION;

                    -- Inserción del nuevo empleado
                    INSERT INTO dbo.Empleado (IdPuesto, ValorDocumentoIdentidad, Nombre, FechaContratacion)
                    VALUES (@IdPuesto, @ValorDocumentoIdentidad, @Nombre, @FechaContratacion);

                    -- Insertar en la bitácora el evento de éxito
                    INSERT INTO dbo.bitacoraEvento(
                        IdTipoEvento,
                        IdUsuario,
                        Fecha,
                        Descripcion,
                        PostInIP,
                        PostTime
                    ) VALUES (
                        6, -- Evento de inserción exitosa
                        (SELECT Id FROM dbo.Usuario WHERE Username = @Username),
                        GETDATE(),
                        'Inserción exitosa del empleado',
                        @PostInIP,
                        GETDATE()
                    );

                    COMMIT TRANSACTION;
                    SET @OutResultCode = 0; -- Éxito
                END
            END
        END

        -- Retornar el código de resultado
        SELECT @OutResultCode AS OutResultCode;

    END TRY
    BEGIN CATCH
        -- En caso de error, revertir la transacción y registrar el error
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END

        -- Registrar el error en la tabla DBErrors
        INSERT INTO dbo.DBErrors VALUES (
            SUSER_SNAME(),
            ERROR_NUMBER(),
            ERROR_STATE(),
            ERROR_SEVERITY(),
            ERROR_LINE(),
            ERROR_PROCEDURE(),
            ERROR_MESSAGE(),
            GETDATE()
        );

        -- Establecer un código de error genérico
        SET @OutResultCode = 50008;
        SELECT @OutResultCode AS OutResultCode;
    END CATCH;

    SET NOCOUNT OFF;
END;
GO

CREATE PROCEDURE [dbo].[GetPuestos]
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
    SELECT Nombre FROM dbo.Puesto;
    END TRY
    BEGIN CATCH
        INSERT INTO dbo.DBErrors VALUES (
            SUSER_SNAME(),
            ERROR_NUMBER(),
            ERROR_STATE(),
            ERROR_SEVERITY(),
            ERROR_LINE(),
            ERROR_PROCEDURE(),
            ERROR_MESSAGE(),
            GETDATE()
        );
    END CATCH;
    SET NOCOUNT Off;
END;
GO

CREATE PROCEDURE [dbo].[GetError]
    @Codigo INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
    SELECT Descripcion FROM dbo.Error
    WHERE Codigo = @Codigo;
    END TRY
    BEGIN CATCH
        INSERT INTO dbo.DBErrors VALUES (
            SUSER_SNAME(),
            ERROR_NUMBER(),
            ERROR_STATE(),
            ERROR_SEVERITY(),
            ERROR_LINE(),
            ERROR_PROCEDURE(),
            ERROR_MESSAGE(),
            GETDATE()
        );
    END CATCH;
    SET NOCOUNT Off;
END;
GO