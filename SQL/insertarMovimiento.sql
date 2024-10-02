CREATE PROCEDURE [dbo].[InsertarMovimiento]
    @ValorDocumentoIdentidad VARCHAR(128),
    @TipoMovimiento VARCHAR(128),
    @Monto INT,
    @Username VARCHAR(128),
    @PostInIP VARCHAR(64),
    @OutResultCode INT OUTPUT
AS
BEGIN
    DECLARE @NuevoSaldo INT;
    DECLARE @CopiaMonto INT;
    SET NOCOUNT ON;

    BEGIN TRY

    SET @CopiaMonto = @Monto;

    SELECT @NuevoSaldo = SaldoVacaciones FROM dbo.Empleado WHERE ValorDocumentoIdentidad = @ValorDocumentoIdentidad;

    SET @NuevoSaldo = @NuevoSaldo + 
                     CASE 
                         WHEN (SELECT TipoAccion FROM dbo.TipoMovimiento WHERE Nombre = @TipoMovimiento) = 'Credito' THEN @Monto
                         WHEN (SELECT TipoAccion FROM dbo.TipoMovimiento WHERE Nombre = @TipoMovimiento) = 'Debito' THEN -@Monto
                         ELSE 0
                     END;
                    
    IF @NuevoSaldo < 0
    BEGIN
        SET @OutResultCode = 50011;
    END
    ELSE
    BEGIN
        UPDATE dbo.Empleado 
        SET SaldoVacaciones = @NuevoSaldo 
        WHERE ValorDocumentoIdentidad = @ValorDocumentoIdentidad;
        INSERT INTO dbo.Movimiento (IdEmpleado, IdTipoMovimiento, Fecha, 
        Monto, NuevoSaldo, IdPostByUser, PostInIP, PostTime)
        VALUES ((SELECT Id FROM dbo.Empleado WHERE ValorDocumentoIdentidad = @ValorDocumentoIdentidad), 
                (SELECT Id FROM dbo.TipoMovimiento WHERE Nombre = @TipoMovimiento), 
                GETDATE(), 
                @CopiaMonto, 
                @NuevoSaldo, 
                (SELECT Id FROM dbo.Usuario WHERE Username = @Username), 
                @PostInIP, 
                GETDATE());
        SET @OutResultCode = 0;
    END
    
    IF @OutResultCode = 0
    BEGIN
        INSERT INTO dbo.bitacoraEvento(
                IdTipoEvento,
                IdUsuario,
                Fecha,
                Descripcion,
                PostInIP,
                PostTime
            ) VALUES (
                14,
                (SELECT Id FROM dbo.Usuario WHERE Username = @Username),
                GETDATE(),
                CONCAT('Insersión de movimiento, ValorDocumentoIdentidad: ', @ValorDocumentoIdentidad,
                ', Nombre: ', (SELECT Nombre FROM dbo.Empleado WHERE ValorDocumentoIdentidad = @ValorDocumentoIdentidad),
                'Nuevo Saldo: ', @NuevoSaldo,
                 ',TipoMovimiento: ', @TipoMovimiento, ', Monto: ', @CopiaMonto),
                @PostInIP,
                GETDATE()
            );
    END
    ELSE
    IF @OutResultCode = 50011
    BEGIN
        INSERT INTO dbo.bitacoraEvento(
                IdTipoEvento,
                IdUsuario,
                Fecha,
                Descripcion,
                PostInIP,
                PostTime
            ) VALUES (
                13,
                (SELECT Id FROM dbo.Usuario WHERE Username = @Username),
                GETDATE(),
                CONCAT('Error: ,',(SELECT Descripcion FROM dbo.Error Where Codigo = @OutResultCode),
                ' ValorDocumentoIdentidad: ', @ValorDocumentoIdentidad,
                ', Nombre: ', (SELECT Nombre FROM dbo.Empleado WHERE ValorDocumentoIdentidad = @ValorDocumentoIdentidad),
                'Nuevo Saldo: ', @NuevoSaldo,
                 ',TipoMovimiento: ', @TipoMovimiento, ', Monto: ', @CopiaMonto),
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

        SET @OutResultCode = 50008;
    END CATCH
    SET NOCOUNT OFF;
END
GO


    
