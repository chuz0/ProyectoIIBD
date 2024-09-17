CREATE TABLE dbo.Puesto
( 
    id INT IDENTITY (1, 1) PRIMARY KEY 
    , Nombre VARCHAR(128) NOT NULL 
    , SalarioxHora MONEY
 );
GO

CREATE TABLE dbo.Empleado
(
    Id INT IDENTITY (1,1) PRIMARY KEY, 
    IdPuesto INT FOREIGN KEY REFERENCES Puesto(Id), 
    ValorDocumentoIdentidad VARCHAR(128), 
    Nombre VARCHAR(128), 
    FechaContratacion DATE, 
    SaldoVacaciones INT, 
    EsActivo BIT
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
    Id INT PRIMARY KEY, 
    IdEmpleado INT FOREIGN KEY REFERENCES Empleado(Id), 
    IdTipoMovimiento INT FOREIGN KEY REFERENCES TipoMovimiento(Id), 
    Fecha DATETIME, 
    Monto INT, 
    NuevoSaldo INT, 
    IdPostByUser INT FOREIGN KEY REFERENCES Usuario(Id), 
    PostInIP VARCHAR(128), 
    PostTime DATETIME
);
GO

CREATE TABLE dbo.Usuario
(
    Id INT PRIMARY KEY, 
    Username VARCHAR(128), 
    Contrasena VARCHAR(128)
);
GO