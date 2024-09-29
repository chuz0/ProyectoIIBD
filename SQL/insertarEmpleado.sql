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
        SET @OutResultCode = 0;
        
        IF EXISTS (SELECT 1 FROM dbo.Empleado WHERE Nombre = @Nombre)
        BEGIN
            SET @OutResultCode = 50005;

            INSERT INTO dbo.bitacoraEvento(
                IdTipoEvento,
                IdUsuario,
                Fecha,
                Descripcion,
                PostInIP,
                PostTime
            ) VALUES (
                5,
                (SELECT Id FROM dbo.Usuario WHERE Username = @Username),
                GETDATE(),
                'Error: Nombre duplicado en la inserción del empleado',
                @PostInIP,
                GETDATE()
            );
        END
        ELSE
        BEGIN
            IF EXISTS (SELECT 1 FROM dbo.Empleado WHERE ValorDocumentoIdentidad = @ValorDocumentoIdentidad)
            BEGIN
                SET @OutResultCode = 50004;

                INSERT INTO dbo.bitacoraEvento(
                    IdTipoEvento,
                    IdUsuario,
                    Fecha,
                    Descripcion,
                    PostInIP,
                    PostTime
                ) VALUES (
                    5,
                    (SELECT Id FROM dbo.Usuario WHERE Username = @Username),
                    GETDATE(),
                    'Error: Documento de identidad duplicado en la inserción del empleado',
                    @PostInIP,
                    GETDATE()
                );
            END
            ELSE
            BEGIN
                DECLARE @IdPuesto INT;
                SELECT @IdPuesto = Id FROM dbo.Puesto WHERE Nombre = @Puesto;
                
                IF @IdPuesto IS NULL
                BEGIN
                    SET @OutResultCode = 50008;
                END
                ELSE
                BEGIN
                    BEGIN TRANSACTION;

                    INSERT INTO dbo.Empleado (IdPuesto, ValorDocumentoIdentidad, Nombre, FechaContratacion)
                    VALUES (@IdPuesto, @ValorDocumentoIdentidad, @Nombre, @FechaContratacion);

                    INSERT INTO dbo.bitacoraEvento(
                        IdTipoEvento,
                        IdUsuario,
                        Fecha,
                        Descripcion,
                        PostInIP,
                        PostTime
                    ) VALUES (
                        6,
                        (SELECT Id FROM dbo.Usuario WHERE Username = @Username),
                        GETDATE(),
                        'Inserción exitosa del empleado',
                        @PostInIP,
                        GETDATE()
                    );

                    COMMIT TRANSACTION;
                    SET @OutResultCode = 0; 
                END
            END
        END

        SELECT @OutResultCode AS OutResultCode;

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END

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

        SET @OutResultCode = 50008;
        SELECT @OutResultCode AS OutResultCode;
    END CATCH;

    SET NOCOUNT OFF;
END;
GO

ALTER PROCEDURE [dbo].[GetPuestos]
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
    SELECT Nombre FROM dbo.Puesto
    ORDER BY Nombre;
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