ALTER PROCEDURE ValidarCredenciales
    @username VARCHAR(64),
    @password VARCHAR(64),
    @PostInIP VARCHAR(64),
    @PostTime DATETIME,
    @OutResultCode INT OUTPUT
AS
BEGIN

    SET @OutResultCode=0;
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM dbo.Usuario WHERE username = @username AND pass = @password)
    BEGIN
        SET @OutResultCode=0;
        BEGIN TRANSACTION;
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
        @PostTime);
        COMMIT TRANSACTION;
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
        1,
        GETDATE(),
        CONCAT('Login Fallido: ', @OutResultCode),
        @PostInIP,
        @PostTime
    );
    END
    SET NOCOUNT OFF;
END
GO

CREATE PROCEDURE logout
    @username VARCHAR(64),
    @PostInIP VARCHAR(64)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    INSERT INTO dbo.bitacoraEvento(
        IdTipoEvento,
        IdUsuario,
        Fecha,
        Descripcion,
        PostInIP,
        PostTime
    ) VALUES (
        4,
        (SELECT Id FROM dbo.Usuario WHERE Username = @username),
        GETDATE(),
        'Logout',
        @PostInIP,
        GETDATE()
    );
    COMMIT TRANSACTION;
    SET NOCOUNT OFF;
END
GO