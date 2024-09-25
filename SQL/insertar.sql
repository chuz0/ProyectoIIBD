CREATE PROCEDURE [dbo].[ListarEmpleado]
	@OutResulTCode INT OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
	
	SET @OutResulTCode=0;

	SELECT @OutResulTCode AS OutResulTCode;  -- Este codigo se agrega solo si hay problemas para obtener este  valor como parametros

	SELECT E.[Id]   -- En interfaces a usuario final no se muestra, ni en apis
		, E.[IdPuesto]
        , E.[ValorDocumentoIdentidad]
        , E.[Nombre]
        , E.[FechaContratacion]
        , E.[SaldoVacaciones]
        , E.[EsActivo]
	FROM dbo.Empleado E 
	ORDER BY E.Nombre;

	END TRY
	BEGIN CATCH
		INSERT INTO dbo.DBErrors	VALUES (
			SUSER_SNAME(),
			ERROR_NUMBER(),
			ERROR_STATE(),
			ERROR_SEVERITY(),
			ERROR_LINE(),
			ERROR_PROCEDURE(),
			ERROR_MESSAGE(),
			GETDATE()
		);

		SET @OutResulTCode=50005  ;  -- Codigo de error standar del profe para informar de un error capturado en el catch

	END CATCH;

	SET NOCOUNT Off;
END;