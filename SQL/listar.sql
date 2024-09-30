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