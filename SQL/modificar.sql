ALTER PROCEDURE ModificarEmpleadoPorDocumento
    @ValorDocumentoIdentidadAnterior VARCHAR(128),
    @ValorDocumentoIdentidadNuevo VARCHAR(128),
    @NombreAnterior VARCHAR(128),
    @NombreNuevo VARCHAR(128),
    @PuestoNuevo VARCHAR(128),
    @SaldoVacaciones INT,
    @Username VARCHAR(128),
    @PostInIP VARCHAR(64),
    @OutResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        SET @OutResultCode = 0;

        IF @ValorDocumentoIdentidadAnterior <> @ValorDocumentoIdentidadNuevo AND 
           EXISTS (SELECT 1 FROM dbo.Empleado WHERE ValorDocumentoIdentidad = @ValorDocumentoIdentidadNuevo)
        BEGIN
            SET @OutResultCode = 50006;
        END

        IF @NombreAnterior <> @NombreNuevo AND 
           EXISTS (SELECT 1 FROM dbo.Empleado WHERE Nombre = @NombreNuevo AND Nombre <> @NombreAnterior)
        BEGIN
            SET @OutResultCode = 50007;
        END

        IF @OutResultCode = 0
        BEGIN
            DECLARE @IdPuestoNuevo INT;
            SELECT @IdPuestoNuevo = Id FROM dbo.Puesto WHERE Nombre = @PuestoNuevo;

            DECLARE @PuestoAnterior VARCHAR(128), @SaldoVacacionesAnterior INT;
            SELECT 
                @PuestoAnterior = P.Nombre,
                @SaldoVacacionesAnterior = E.SaldoVacaciones
            FROM dbo.Empleado E
            INNER JOIN dbo.Puesto P ON E.IdPuesto = P.Id
            WHERE E.ValorDocumentoIdentidad = @ValorDocumentoIdentidadAnterior;

            BEGIN TRANSACTION;

            UPDATE dbo.Empleado
            SET 
                ValorDocumentoIdentidad = @ValorDocumentoIdentidadNuevo,
                Nombre = @NombreNuevo,
                IdPuesto = @IdPuestoNuevo
            WHERE ValorDocumentoIdentidad = @ValorDocumentoIdentidadAnterior;

            INSERT INTO dbo.bitacoraEvento (
                IdTipoEvento, IdUsuario, Fecha, Descripcion, PostInIP, PostTime
            ) VALUES (
                8,
                (SELECT Id FROM dbo.Usuario WHERE Username = @Username),
                GETDATE(),
                CONCAT('Modificación de empleado: [ValorDocumentoAntes: ', @ValorDocumentoIdentidadAnterior, 
                    ', NombreAntes: ', @NombreAnterior, 
                    ', PuestoAntes: ', @PuestoAnterior, 
                    ', ValorDocumentoDespues: ', @ValorDocumentoIdentidadNuevo, 
                    ', NombreDespues: ', @NombreNuevo, 
                    ', PuestoDespues: ', @PuestoNuevo, 
                    ', SaldoVacaciones: ', @SaldoVacaciones, ']'),
                @PostInIP,
                GETDATE()
            );

            COMMIT TRANSACTION;
        END
        ELSE
        BEGIN
            INSERT INTO dbo.bitacoraEvento (
                IdTipoEvento, IdUsuario, Fecha, Descripcion, PostInIP, PostTime
            ) VALUES (
                7, 
                (SELECT Id FROM dbo.Usuario WHERE Username = @Username),
                GETDATE(),
                CONCAT('Error en modificación de empleado: ', @OutResultCode, 
                    ' [ValorDocumentoAntes: ', @ValorDocumentoIdentidadAnterior, 
                    ', NombreAntes: ', @NombreAnterior, 
                    ', PuestoAntes: ', @PuestoAnterior, 
                    ', ValorDocumentoDespues: ', @ValorDocumentoIdentidadNuevo, 
                    ', NombreDespues: ', @NombreNuevo, 
                    ', PuestoDespues: ', @PuestoNuevo, 
                    ', SaldoVacaciones: ', @SaldoVacaciones, ']'),
                @PostInIP,
                GETDATE()
            );

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
        ROLLBACK TRANSACTION;

        SET @OutResultCode = 50008;
    END CATCH;

    SET NOCOUNT OFF;
END;
GO
