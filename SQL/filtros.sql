CREATE PROCEDURE GetFiltroEmpleadosNombre
    @nombre VARCHAR(64),
    @Username VARCHAR(128),
    @PostInIP VARCHAR(64),
    @PostTime DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    SELECT E.[Id]  
       , E.[ValorDocumentoIdentidad]
       , E.[Nombre]
	   , P.[Nombre] AS Puesto
       , E.[FechaContratacion]
       , E.[SaldoVacaciones]
       , E.[EsActivo] 
    FROM dbo.Empleado E
    INNER JOIN dbo.Puesto P ON E.IdPuesto = P.Id
    WHERE E.Nombre LIKE '%' + @nombre + '%'
    ORDER BY E.Nombre ASC;
    BEGIN TRANSACTION;
    INSERT INTO dbo.bitacoraEvento(
        IdTipoEvento,
        IdUsuario,
        Fecha,
        Descripcion,
        PostInIP,
        PostTime
    ) VALUES (
        11,
        (SELECT Id FROM dbo.Usuario WHERE Username = @Username),
        GETDATE(),
        @nombre,
        @PostInIP,
        @PostTime
    );
    COMMIT TRANSACTION;
END
GO

CREATE PROCEDURE dbo.filtroEmpDoc
    @valorDocumento int,
    @Username VARCHAR(128),
    @PostInIP VARCHAR(64),
    @PostTime DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    SELECT E.[Id]  
       , E.[ValorDocumentoIdentidad]
       , E.[Nombre]
	   , P.[Nombre] AS Puesto
       , E.[FechaContratacion]
       , E.[SaldoVacaciones]
       , E.[EsActivo] 
    FROM dbo.Empleado E
    INNER JOIN dbo.Puesto P ON E.IdPuesto = P.Id
    WHERE CAST(ValorDocumentoIdentidad AS VARCHAR(20)) LIKE '%' + CAST(@valorDocumento AS VARCHAR(20)) + '%'
    ORDER BY nombre ASC;
    BEGIN TRANSACTION;
    INSERT INTO dbo.bitacoraEvento(
        IdTipoEvento,
        IdUsuario,
        Fecha,
        Descripcion,
        PostInIP,
        PostTime
    ) VALUES (
        12,
        (SELECT Id FROM dbo.Usuario WHERE Username = @Username),
        GETDATE(),
        @valorDocumento,
        @PostInIP,
        @PostTime
    );
    COMMIT TRANSACTION;
END
GO