CREATE TABLE dbo.monitoreo_ventas (
    MonitoreoID INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT,
    ProductName NVARCHAR(255),
    TotalUnidadesVendidas BIGINT,
    FechaSuperaUmbral DATETIME DEFAULT GETDATE()
);

--------------------------------------------------------------------
--2.- Crear o reemplazar el trigger de monitoreo
ALTER TRIGGER trg_MonitoreoVentas
ON dbo.sales_limpio
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Inserta en la tabla de monitoreo los productos que acaban de superar las 200,000 unidades
    INSERT INTO dbo.monitoreo_ventas (ProductID, ProductName, TotalUnidadesVendidas, FechaSuperaUmbral)
    SELECT 
        p.ProductID,
        p.ProductName,
        SUM(s.Quantity) AS TotalUnidadesVendidas,
        GETDATE()
    FROM dbo.sales_limpio s
    JOIN inserted i ON s.ProductID = i.ProductID
    JOIN dbo.products p ON s.ProductID = p.ProductID
    GROUP BY p.ProductID, p.ProductName
    HAVING 
        SUM(s.Quantity) > 200000
        AND NOT EXISTS (
            SELECT 1 
            FROM dbo.monitoreo_ventas mv 
            WHERE mv.ProductID = p.ProductID
        );
END;
GO

-- 2?? Registrar una nueva venta
INSERT INTO dbo.sales_limpio (SalesPersonID, CustomerID, ProductID, Quantity, TotalPrice, Discount, SalesDate)
VALUES (9, 84, 103, 1876, 1200, 0, GETDATE());
GO

-- 3?? Verificar que la venta fue registrada correctamente
SELECT *
FROM dbo.sales_limpio
WHERE SalesPersonID = 9
  AND CustomerID = 84
  AND ProductID = 103
ORDER BY SalesDate DESC;
GO

-- 4?? Consultar la tabla de monitoreo (resultado del trigger)
SELECT *
FROM dbo.monitoreo_ventas
ORDER BY FechaSuperaUmbral DESC;






---------------------------------------------------------------------
--3.- Reemplazar trigger de monitoreo
ALTER TRIGGER trg_MonitoreoVentas
ON dbo.sales_limpio
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Inserta en la tabla de monitoreo los productos que acaban de superar las 200,000 unidades
    INSERT INTO dbo.monitoreo_ventas (ProductID, ProductName, TotalUnidadesVendidas, FechaSuperaUmbral)
    SELECT 
        p.ProductID,
        p.ProductName,
        SUM(s.Quantity) AS TotalUnidadesVendidas,
        GETDATE()
    FROM dbo.sales_limpio s
    JOIN inserted i ON s.ProductID = i.ProductID
    JOIN dbo.products p ON s.ProductID = p.ProductID
    GROUP BY p.ProductID, p.ProductName
    HAVING 
        SUM(s.Quantity) > 200000
        AND NOT EXISTS (
            SELECT 1 
            FROM dbo.monitoreo_ventas mv 
            WHERE mv.ProductID = p.ProductID
        );
END;
GO


-- 2?? Registrar una nueva venta (NO incluir SalesID manualmente)
INSERT INTO dbo.sales_limpio (SalesPersonID, CustomerID, ProductID, Quantity, TotalPrice, Discount, SalesDate)
VALUES (9, 84, 103, 1876, 1200, 0, GETDATE());
GO


-- 3?? Verificar que la venta se registró correctamente
SELECT 
    NewSalesID,  -- Nueva columna autoincremental
    SalesPersonID,
    CustomerID,
    ProductID,
    Quantity,
    Discount,
    TotalPrice,
    SalesDate
FROM dbo.sales_limpio
WHERE SalesPersonID = 9
  AND CustomerID = 84
  AND ProductID = 103
ORDER BY SalesDate DESC;
GO


-- 4?? Consultar la tabla de monitoreo (efecto del trigger)
SELECT *
FROM dbo.monitoreo_ventas
ORDER BY FechaSuperaUmbral DESC;
GO

------------------------------------------------------------------------------------------
--3.-OPTIMIZACION DE CONSULTAS (CLIENTES UNICOS )

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT 
    p.ProductName,
    COUNT(DISTINCT s.CustomerID) AS ClientesUnicos
FROM dbo.sales_limpio AS s
JOIN dbo.products AS p
    ON s.ProductID = p.ProductID
GROUP BY p.ProductName
ORDER BY ClientesUnicos DESC;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
-----------------------------------------------------------------------------------------
-- Índice individual sobre ProductID
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_sales_limpio_ProductID' 
      AND object_id = OBJECT_ID('dbo.sales_limpio')
)
CREATE NONCLUSTERED INDEX IX_sales_limpio_ProductID
ON dbo.sales_limpio(ProductID);
GO

-- Índice compuesto ProductID + CustomerID
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_sales_limpio_ProductID_CustomerID' 
      AND object_id = OBJECT_ID('dbo.sales_limpio')
)
CREATE NONCLUSTERED INDEX IX_sales_limpio_ProductID_CustomerID
ON dbo.sales_limpio(ProductID, CustomerID);
GO

-- Índice en tabla products
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE name = 'IX_products_ProductID' 
      AND object_id = OBJECT_ID('dbo.products')
)
CREATE NONCLUSTERED INDEX IX_products_ProductID
ON dbo.products(ProductID);
GO


----------------------------------------------------------------------------
--OPTIMIZACION DE CONSULTAS (CLIENTES UNICOS )

SET STATISTICS IO ON;
SET STATISTICS TIME ON;

SELECT 
    p.ProductName,
    COUNT(DISTINCT s.CustomerID) AS ClientesUnicos
FROM dbo.sales_limpio AS s
JOIN dbo.products AS p
    ON s.ProductID = p.ProductID
GROUP BY p.ProductName
ORDER BY ClientesUnicos DESC;

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;

------------------------------------------------------------------------------

--OPTIMIZACION DE CONSULTA DE 5 PRODUCTOS MAS VENDIDOS 
WITH TotalPorProducto AS (
    SELECT 
        p.ProductID,
        p.ProductName,
        SUM(s.Quantity) AS TotalCantidad
    FROM dbo.sales_limpio s
    JOIN dbo.products p ON s.ProductID = p.ProductID
    GROUP BY p.ProductID, p.ProductName
),
Top5Productos AS (
    SELECT TOP 5 *
    FROM TotalPorProducto
    ORDER BY TotalCantidad DESC
),
VendedorPorProducto AS (
    SELECT 
        s.ProductID,
        e.EmployeeID,
        e.FirstName + ' ' + e.LastName AS Vendedor,
        SUM(s.Quantity) AS CantidadVendida,
        ROW_NUMBER() OVER (PARTITION BY s.ProductID ORDER BY SUM(s.Quantity) DESC) AS rn
    FROM dbo.sales_limpio s
    JOIN dbo.employees e ON s.SalesPersonID = e.EmployeeID
    WHERE s.ProductID IN (SELECT ProductID FROM Top5Productos)
    GROUP BY s.ProductID, e.EmployeeID, e.FirstName, e.LastName
)
SELECT 
    t.ProductID,
    t.ProductName,
    t.TotalCantidad AS TotalVendido,
    v.Vendedor,
    v.CantidadVendida AS UnidadesVendedorTop
FROM Top5Productos t
JOIN VendedorPorProducto v ON t.ProductID = v.ProductID
WHERE v.rn = 1
ORDER BY t.TotalCantidad DESC;

----------------------------------------------------------------------------------
---INDICES NO AGRUPADOS (NONCLUSTERED).
IF NOT EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = 'IX_sales_limpio_ProductID' 
      AND object_id = OBJECT_ID('dbo.sales_limpio')
)
CREATE NONCLUSTERED INDEX IX_sales_limpio_ProductID
ON dbo.sales_limpio(ProductID);
GO


--------------------------------------------------------------------------
--RESULTADOS 
WITH TotalPorProducto AS (
    SELECT 
        p.ProductID,
        p.ProductName,
        SUM(s.Quantity) AS TotalCantidad
    FROM dbo.sales_limpio s
    JOIN dbo.products p ON s.ProductID = p.ProductID
    GROUP BY p.ProductID, p.ProductName
),
Top5Productos AS (
    SELECT TOP 5 *
    FROM TotalPorProducto
    ORDER BY TotalCantidad DESC
),
VendedorPorProducto AS (
    SELECT 
        s.ProductID,
        e.EmployeeID,
        e.FirstName + ' ' + e.LastName AS Vendedor,
        SUM(s.Quantity) AS CantidadVendida,
        ROW_NUMBER() OVER (PARTITION BY s.ProductID ORDER BY SUM(s.Quantity) DESC) AS rn
    FROM dbo.sales_limpio s
    JOIN dbo.employees e ON s.SalesPersonID = e.EmployeeID
    WHERE s.ProductID IN (SELECT ProductID FROM Top5Productos)
    GROUP BY s.ProductID, e.EmployeeID, e.FirstName, e.LastName
)
SELECT 
    t.ProductID,
    t.ProductName,
    t.TotalCantidad AS TotalVendido,
    v.Vendedor,
    v.CantidadVendida AS UnidadesVendedorTop
FROM Top5Productos t
JOIN VendedorPorProducto v ON t.ProductID = v.ProductID
WHERE v.rn = 1
ORDER BY t.TotalCantidad DESC;

