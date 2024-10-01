ALTER PROCEDURE [dbo].[ListarEmpleado]
    @OutResulTCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
    
        SET @OutResulTCode = 0;

        SELECT E.[Id]  
               , E.[ValorDocumentoIdentidad]
               , E.[Nombre]
               , P.[Nombre] AS Puesto
               , E.[FechaContratacion]
               , E.[SaldoVacaciones]
               , E.[EsActivo] 
        FROM dbo.Empleado E
        INNER JOIN dbo.Puesto P ON E.IdPuesto = P.Id
        WHERE E.EsActivo = 1 
        ORDER BY E.Nombre;

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

        SET @OutResulTCode = 50008; 
    END CATCH;

    SET NOCOUNT OFF;
END;
GO

ALTER PROCEDURE [dbo].[ListarMovimientoByDocumentoIdentidad]
    @ValorDocumentoIdentidad VARCHAR(128),
    @OutResulTCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY

        DECLARE @IdEmpleado INT;

        SELECT @IdEmpleado = E.[Id]
        FROM dbo.Empleado E
        WHERE E.ValorDocumentoIdentidad = @ValorDocumentoIdentidad;

        SET @OutResulTCode = 0;

        SELECT E.[Nombre] AS Empleado
               , TM.[Nombre] AS TipoMovimiento
               , M.[Fecha]
               , M.[Monto]
               , M.[NuevoSaldo]
               , U.[Username] AS PostByUser
               , M.[PostInIP]
               , M.[PostTime]
        FROM dbo.Movimiento M
        INNER JOIN dbo.TipoMovimiento TM ON M.IdTipoMovimiento = TM.Id
        INNER JOIN dbo.Usuario U ON M.IdPostByUser = U.Id
        INNER JOIN dbo.Empleado E ON M.IdEmpleado = E.Id
        WHERE M.IdEmpleado = @IdEmpleado
        ORDER BY M.Fecha DESC;

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

        SET @OutResulTCode = 50008; 
    END CATCH;

    SET NOCOUNT OFF;
END;
GO