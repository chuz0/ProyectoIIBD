CREATE PROCEDURE ValidarCredenciales
    @username VARCHAR(64),
    @password VARCHAR(64),
    @PostInIP VARCHAR(64),
    @PostTime DATETIME,
    @OutResultCode INT OUTPUT
AS
BEGIN

    SET @OutResultCode=0;
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM usuario WHERE username = @username AND pass = @password)
    BEGIN
        SET @OutResultCode=0;
        INSERT INTO dbo.bitacoraEvento(
        IdTipoEvento,
        IdUsuario,
        Fecha,
        Descripcion,
        PostInIP,
        PostTime
    ) VALUES (
        1,
        (SELECT Id FROM dbo.Usuario WHERE Username = @username),
        GETDATE(),
        'Login Exitoso',
        @PostInIP,
        @PostTime
    );
    END
    ELSE
    BEGIN
        SET @OutResultCode=50002;
        INSERT INTO dbo.bitacoraEvento(
        IdTipoEvento,
        IdUsuario,
        Fecha,
        Descripcion,
        PostInIP,
        PostTime
    ) VALUES (
        2,
        (SELECT Id FROM dbo.Usuario WHERE Username = @username),
        GETDATE(),
        'Login No Exitoso',
        @PostInIP,
        @PostTime
    );
    END
END
GO