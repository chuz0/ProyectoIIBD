CREATE TABLE dbo.Puesto
( 
    id INT IDENTITY (1, 1) PRIMARY KEY 
    , Nombre VARCHAR(128) NOT NULL 
    , SalarioxHora MONEY
 );
GO

CREATE TABLE dbo.Empleado
(
    Id INT IDENTITY(1,1) PRIMARY KEY, 
    IdPuesto INT NOT NULL FOREIGN KEY REFERENCES Puesto(Id), 
    ValorDocumentoIdentidad VARCHAR(128) NOT NULL,  
    Nombre VARCHAR(128) NOT NULL, 
    FechaContratacion DATE NOT NULL, 
    SaldoVacaciones INT NOT NULL DEFAULT 0, 
    EsActivo BIT NOT NULL DEFAULT 1 
);
GO

CREATE TABLE dbo.TipoMovimiento
(
    Id INT PRIMARY KEY, 
    Nombre VARCHAR(128), 
    TipoAccion VARCHAR(128)
);
GO

CREATE TABLE dbo.Movimiento
(
    Id INT IDENTITY(1,1) PRIMARY KEY, 
    IdEmpleado INT NOT NULL FOREIGN KEY REFERENCES Empleado(Id), 
    IdTipoMovimiento INT NOT NULL FOREIGN KEY REFERENCES TipoMovimiento(Id), 
    Fecha DATETIME NOT NULL, 
    Monto INT NOT NULL, 
    NuevoSaldo INT NOT NULL, 
    IdPostByUser INT NOT NULL FOREIGN KEY REFERENCES Usuario(Id), 
    PostInIP VARCHAR(64) NOT NULL, 
    PostTime DATETIME NOT NULL
);
GO

CREATE TABLE dbo.Usuario
(
    Id INT PRIMARY KEY, 
    Username VARCHAR(128), 
    Pass VARCHAR(128)
);
GO

CREATE TABLE dbo.TipoEvento
(
    Id INT PRIMARY KEY, 
    Nombre VARCHAR(128)
);
GO

CREATE TABLE dbo.Error
(
    Id INT IDENTITY(1,1) PRIMARY KEY, 
    Codigo INT NOT NULL,
    Descripcion VARCHAR(128) NOT NULL,
);
GO