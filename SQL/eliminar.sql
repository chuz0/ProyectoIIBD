ALTER PROCEDURE [dbo].[IntentoBorrado]
    @ValorDocumentoIdentidad VARCHAR(128),
    @Username VARCHAR(128),
    @PostInIP VARCHAR(64),
    @Confirmacion INT,
    @OutResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SET @OutResultCode = 0;
        DECLARE @NombreEmpleado VARCHAR(128);
        DECLARE @PuestoEmpleado VARCHAR(128);
        DECLARE @SaldoVacaciones INT;


        IF EXISTS (SELECT 1 FROM dbo.Empleado WHERE ValorDocumentoIdentidad = @ValorDocumentoIdentidad)

        SELECT 
                @NombreEmpleado = E.Nombre,
                @PuestoEmpleado = P.Nombre,
                @SaldoVacaciones = E.SaldoVacaciones
        FROM dbo.Empleado E
        INNER JOIN dbo.Puesto P ON E.IdPuesto = P.Id
        WHERE E.ValorDocumentoIdentidad = @ValorDocumentoIdentidad;        

        BEGIN
            IF @Confirmacion = 0
                BEGIN
                    INSERT INTO dbo.bitacoraEvento(
                        IdTipoEvento,
                        IdUsuario,
                        Fecha,
                        Descripcion,
                        PostInIP,
                        PostTime
                    ) VALUES (
                        8,
                        (SELECT Id FROM dbo.Usuario WHERE Username = @Username),
                        GETDATE(),
                        CONCAT('Intento de borrado: [ValorDocumento: ', @ValorDocumentoIdentidad,                             ', Nombre: ', @NombreEmpleado, 
                        ', Puesto: ', @PuestoEmpleado, 
                        ', SaldoVacaciones: ', @SaldoVacaciones, ']'),
                        @PostInIP,
                        GETDATE()
                    );
                END
        ELSE
            BEGIN
                UPDATE dbo.Empleado 
                SET EsActivo = 0 
                WHERE ValorDocumentoIdentidad = @ValorDocumentoIdentidad;
                SET @OutResultCode = 0;


                INSERT INTO dbo.bitacoraEvento(
                    IdTipoEvento,
                    IdUsuario,
                    Fecha,
                    Descripcion,
                    PostInIP,
                    PostTime
                ) VALUES (
                    9,
                    (SELECT Id FROM dbo.Usuario WHERE Username = @Username),
                    GETDATE(),
                    CONCAT('Borrado: [ValorDocumento: ', @ValorDocumentoIdentidad, 
                    ', Nombre: ', @NombreEmpleado, 
                    ', Puesto: ', @PuestoEmpleado, 
                    ', SaldoVacaciones: ', @SaldoVacaciones, ']'),
                    @PostInIP,
                    GETDATE()
                );
            END
        END 
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
        SET @OutResultCode = 50008;
    END CATCH
    SET NOCOUNT OFF;
END
GO