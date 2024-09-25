CREATE PROCEDURE [dbo].[InsertarEmpleado]
    @Puesto VARCHAR(128) , 
    @ValorDocumentoIdentidad VARCHAR(128),  
    @Nombre VARCHAR(128), 
    @FechaContratacion DATE,
    @Username VARCHAR(128),
    @PostInIP VARCHAR(64),
    @PostTime DATETIME,
    @OutResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY

    SET @OutResultCode=0;

    IF EXISTS (SELECT 1 FROM dbo.Empleado WHERE Nombre = @Nombre)

    BEGIN
        SET @OutResultCode=50005; 
    END

    ELSE

    BEGIN
    IF EXISTS (SELECT 1 FROM dbo.Empleado WHERE ValorDocumentoIdentidad = @ValorDocumentoIdentidad)
    BEGIN
        SET @OutResultCode=50004; 
    END

    ELSE
    BEGIN
        DECLARE @IdPuesto INT;
        SELECT @IdPuesto = Id FROM dbo.Puesto WHERE Nombre = @Puesto;
        BEGIN TRANSACTION;
        
        INSERT INTO dbo.Empleado
        (
            IdPuesto, 
            ValorDocumentoIdentidad,  
            Nombre, 
            FechaContratacion
        )
        VALUES
        (
            @IdPuesto, 
            @ValorDocumentoIdentidad,  
            @Nombre, 
            @FechaContratacion
        );
        SET @OutResultCode=0;
        BEGIN
        COMMIT TRANSACTION;
        BEGIN
    
        SELECT @OutResultCode AS OutResultCode;
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
        'Insercion no exitosa',
        @PostInIP,
        @PostTime
    );

    END
        END
    END--2DO ELSE
    END--1ER ELSE


    IF @OutResultCode=0
    BEGIN
        SELECT @OutResultCode AS OutResultCode;  
    END
    ELSE
    IF @OutResultCode=50004
    BEGIN
    
        SELECT @OutResultCode AS OutResultCode;
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
        'Insercion no exitosa',
        @PostInIP,
        @PostTime
    );

    END
    ELSE
    IF @OutResultCode=50005
    BEGIN
        SELECT @OutResultCode AS OutResultCode;
        BEGIN
    
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
        'Insercion no exitosa',
        @PostInIP,
        @PostTime
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


    END CATCH;

    SET NOCOUNT Off;
END;