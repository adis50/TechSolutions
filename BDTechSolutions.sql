IF DB_ID('BDTechSolutions') IS NULL
    CREATE DATABASE BDTechSolutions;
GO
USE BDTechSolutions;
GO

-- Limpiar tablas si ya existían de pruebas anteriores
IF OBJECT_ID('DetalleVenta') IS NOT NULL DROP TABLE DetalleVenta;
IF OBJECT_ID('Venta') IS NOT NULL DROP TABLE Venta;
IF OBJECT_ID('Producto') IS NOT NULL DROP TABLE Producto;
IF OBJECT_ID('Cliente') IS NOT NULL DROP TABLE Cliente;
IF OBJECT_ID('Usuario') IS NOT NULL DROP TABLE Usuario;
GO

-- 1. Tabla Usuario (Login, Niveles de Acceso y Validación por Hardware)
CREATE TABLE Usuario (
    IdUsuario      INT IDENTITY(1,1) PRIMARY KEY,
    NombreUsuario  VARCHAR(30)  NOT NULL UNIQUE,
    Clave          VARCHAR(100) NOT NULL,
    NombreCompleto VARCHAR(100) NOT NULL,
    Rol            VARCHAR(20)  NOT NULL, -- 'Administrador' o 'Vendedor'
    HardwareId     VARCHAR(100) NULL,     -- Serial de placa/CPU para validación de hardware
    Activo         BIT          NOT NULL DEFAULT 1
);
GO

-- 2. Tabla Cliente
CREATE TABLE Cliente (
    IdCliente  INT IDENTITY(1,1) PRIMARY KEY,
    Documento  VARCHAR(15)  NOT NULL UNIQUE,
    Nombres    VARCHAR(120) NOT NULL,
    Telefono   VARCHAR(20)  NULL,
    Correo     VARCHAR(100) NULL,
    Activo     BIT          NOT NULL DEFAULT 1
);
GO

-- 3. Tabla Producto
CREATE TABLE Producto (
    IdProducto INT IDENTITY(1,1) PRIMARY KEY,
    Codigo     VARCHAR(20)   NOT NULL UNIQUE,
    Nombre     VARCHAR(120)  NOT NULL,
    Categoria  VARCHAR(50)   NOT NULL,
    Precio     DECIMAL(10,2) NOT NULL,
    Stock      INT           NOT NULL,
    Activo     BIT           NOT NULL DEFAULT 1
);
GO

-- 4. Tabla Venta (Cabecera)
CREATE TABLE Venta (
    IdVenta           INT IDENTITY(1,1) PRIMARY KEY,
    NumeroComprobante VARCHAR(20)   NOT NULL UNIQUE,
    Fecha             DATETIME      NOT NULL DEFAULT GETDATE(),
    IdCliente         INT           NOT NULL FOREIGN KEY REFERENCES Cliente(IdCliente),
    IdUsuario         INT           NOT NULL FOREIGN KEY REFERENCES Usuario(IdUsuario),
    Total             DECIMAL(10,2) NOT NULL,
    Estado            VARCHAR(20)   NOT NULL DEFAULT 'EMITIDA'
);
GO

-- 5. Tabla DetalleVenta (Para transacciones y control de stock)
CREATE TABLE DetalleVenta (
    IdDetalle      INT IDENTITY(1,1) PRIMARY KEY,
    IdVenta        INT           NOT NULL FOREIGN KEY REFERENCES Venta(IdVenta),
    IdProducto     INT           NOT NULL FOREIGN KEY REFERENCES Producto(IdProducto),
    Cantidad       INT           NOT NULL,
    PrecioUnitario DECIMAL(10,2) NOT NULL,
    Subtotal       DECIMAL(10,2) NOT NULL
);
GO

-- ==========================================================
-- DATOS INICIALES PARA TECH SOLUTIONS
-- ==========================================================
INSERT INTO Usuario (NombreUsuario, Clave, NombreCompleto, Rol, HardwareId, Activo) VALUES
('admin',    '1234', 'Adis Lescano Reyna', 'Administrador', NULL, 1),
('vendedor', '1234', 'Carlos Mendoza',     'Vendedor',      NULL, 1);

INSERT INTO Cliente (Documento, Nombres, Telefono, Correo, Activo) VALUES
('74859612',    'Juan Pérez Gómez',          '987654321', 'jperez@gmail.com', 1),
('20512345678', 'Inversiones Andinas S.A.C.', '014567890', 'compras@andinas.pe', 1),
('45128963',    'María Fernanda Torres',     '912345678', 'mtorres@outlook.com', 1);

INSERT INTO Producto (Codigo, Nombre, Categoria, Precio, Stock, Activo) VALUES
('TECH-001', 'Laptop Lenovo ThinkPad E14',    'Laptops',     3450.00, 12, 1),
('TECH-002', 'Monitor LG UltraGear 24"',      'Monitores',    780.00, 20, 1),
('TECH-003', 'Teclado Mecánico Logitech G413','Periféricos',  260.00, 35, 1),
('TECH-004', 'Mouse Inalámbrico MX Master 3S','Periféricos',  420.00, 18, 1),
('TECH-005', 'SSD NVMe Kingston 1TB',         'Componentes',  310.00,  4, 1);

-- Venta de prueba inicial para que los reportes tengan datos desde el inicio
INSERT INTO Venta (NumeroComprobante, Fecha, IdCliente, IdUsuario, Total, Estado)
VALUES ('B001-00001', GETDATE(), 1, 1, 1040.00, 'EMITIDA');

INSERT INTO DetalleVenta (IdVenta, IdProducto, Cantidad, PrecioUnitario, Subtotal) VALUES
(1, 2, 1, 780.00, 780.00),
(1, 3, 1, 260.00, 260.00);
GO

-- ==========================================================
-- PROCEDIMIENTOS ALMACENADOS PARA REPORTES CON PARÁMETROS
-- ==========================================================
IF OBJECT_ID('sp_ReporteVentasPorFecha') IS NOT NULL DROP PROCEDURE sp_ReporteVentasPorFecha;
GO
CREATE PROCEDURE sp_ReporteVentasPorFecha
    @FechaInicio DATE,
    @FechaFin    DATE
AS
BEGIN
    SELECT 
        v.IdVenta,
        v.NumeroComprobante,
        v.Fecha,
        c.Documento,
        c.Nombres AS Cliente,
        u.NombreCompleto AS Vendedor,
        v.Total,
        v.Estado
    FROM Venta v
    INNER JOIN Cliente c ON v.IdCliente = c.IdCliente
    INNER JOIN Usuario u ON v.IdUsuario = u.IdUsuario
    WHERE CAST(v.Fecha AS DATE) BETWEEN @FechaInicio AND @FechaFin
    ORDER BY v.Fecha DESC;
END
GO

IF OBJECT_ID('sp_ReporteProductosStock') IS NOT NULL DROP PROCEDURE sp_ReporteProductosStock;
GO
CREATE PROCEDURE sp_ReporteProductosStock
    @StockMaximo INT
AS
BEGIN
    SELECT 
        IdProducto,
        Codigo,
        Nombre,
        Categoria,
        Precio,
        Stock
    FROM Producto
    WHERE Activo = 1 AND Stock <= @StockMaximo
    ORDER BY Stock ASC;
END
GO

-- Verificación rápida
SELECT * FROM Usuario;
SELECT * FROM Producto;
EXEC sp_ReporteVentasPorFecha '2026-01-01', '2026-12-31';
