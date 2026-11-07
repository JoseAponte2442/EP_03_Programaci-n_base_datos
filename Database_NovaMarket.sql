---Creación de database
CREATE DATABASE NovaMarket;
GO

USE NovaMarket;
GO
---Tabla  Clientes
CREATE TABLE Clientes
(
    IdCliente INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(100) NOT NULL,
    Telefono VARCHAR(20) NULL
);
GO

---Tabla Productos

CREATE TABLE Productos
(
    IdProducto INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(100) NOT NULL,
    Precio DECIMAL(10,2) NOT NULL,
    Stock INT NOT NULL
);
GO

---Tabla operaciones

CREATE TABLE Operaciones
(
    IdOperacion INT IDENTITY(1,1) PRIMARY KEY,
    IdProducto INT NOT NULL,
    Estado VARCHAR(20) NOT NULL,
    Descripcion VARCHAR(200) NULL,

    CONSTRAINT FK_Operaciones_Productos
        FOREIGN KEY (IdProducto)
        REFERENCES Productos(IdProducto)
);
GO
