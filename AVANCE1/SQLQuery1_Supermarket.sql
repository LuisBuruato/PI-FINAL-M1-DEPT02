

--1.-  Cinco productos más vendidos y el vendedor que más unidades vendió de cada uno
WITH TotalPorProducto AS (
    SELECT 
        p.ProductID,
        p.ProductName,
        SUM(s.Quantity) AS TotalCantidad
    FROM [dbo].[sales_limpio] s
    JOIN [dbo].[products] p ON s.ProductID = p.ProductID
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
    FROM [dbo].[sales_limpio] s
    JOIN [dbo].[employees] e ON s.SalesPersonID = e.EmployeeID
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

------------------------------------------------------------------------------------


--2.- Vendedores que son máximos en los 5 productos más vendidos
WITH TotalPorProducto AS (
    SELECT 
        p.ProductID,
        p.ProductName,
        SUM(s.Quantity) AS TotalCantidad
    FROM [dbo].[sales_limpio] s
    JOIN [dbo].[products] p ON s.ProductID = p.ProductID
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
    FROM [dbo].[sales_limpio] s
    JOIN [dbo].[employees] e ON s.SalesPersonID = e.EmployeeID
    WHERE s.ProductID IN (SELECT ProductID FROM Top5Productos)
    GROUP BY s.ProductID, e.EmployeeID, e.FirstName, e.LastName
),
MaxVendedores AS (
    SELECT 
        v.Vendedor
    FROM VendedorPorProducto v
    WHERE v.rn = 1
)
-- 2️⃣ Contar cuántas veces aparece cada vendedor
SELECT 
    Vendedor,
    COUNT(*) AS VecesComoTopVendedor
FROM MaxVendedores
GROUP BY Vendedor
HAVING COUNT(*) > 1  -- solo los que aparecen más de una vez
ORDER BY VecesComoTopVendedor DESC;

-------------------------------------------------------------------------

--3.- Top 5 productos y su vendedor top con porcentaje de participación
WITH TotalPorProducto AS (
    SELECT 
        p.ProductID,
        p.ProductName,
        SUM(s.Quantity) AS TotalCantidad
    FROM [dbo].[sales_limpio] s
    JOIN [dbo].[products] p ON s.ProductID = p.ProductID
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
    FROM [dbo].[sales_limpio] s
    JOIN [dbo].[employees] e ON s.SalesPersonID = e.EmployeeID
    WHERE s.ProductID IN (SELECT ProductID FROM Top5Productos)
    GROUP BY s.ProductID, e.EmployeeID, e.FirstName, e.LastName
)
SELECT 
    t.ProductID,
    t.ProductName,
    t.TotalCantidad AS TotalVendido,
    v.Vendedor,
    v.CantidadVendida AS UnidadesVendedorTop,
    CAST(v.CantidadVendida * 100.0 / t.TotalCantidad AS DECIMAL(5,2)) AS PorcentajeVentas
FROM Top5Productos t
JOIN VendedorPorProducto v ON t.ProductID = v.ProductID
WHERE v.rn = 1
ORDER BY PorcentajeVentas DESC;

------------------------------------------------------------------------------------------------
-- 4.- Total de clientes
WITH TotalClientes AS (
    SELECT COUNT(DISTINCT CustomerID) AS TotalClientes
    FROM [dbo].[sales_limpio]
),

-- 2️⃣ Top 5 productos más vendidos
TotalPorProducto AS (
    SELECT 
        p.ProductID,
        p.ProductName,
        SUM(s.Quantity) AS TotalCantidad
    FROM [dbo].[sales_limpio] s
    JOIN [dbo].[products] p ON s.ProductID = p.ProductID
    GROUP BY p.ProductID, p.ProductName
),
Top5Productos AS (
    SELECT TOP 5 *
    FROM TotalPorProducto
    ORDER BY TotalCantidad DESC
),

-- 3️⃣ Clientes únicos por producto
ClientesPorProducto AS (
    SELECT 
        s.ProductID,
        COUNT(DISTINCT s.CustomerID) AS ClientesUnicos
    FROM [dbo].[sales_limpio] s
    WHERE s.ProductID IN (SELECT ProductID FROM Top5Productos)
    GROUP BY s.ProductID
)

-- 4️⃣ Resultado final con porcentaje sobre total de clientes
SELECT 
    t.ProductID,
    t.ProductName,
    c.ClientesUnicos,
    tc.TotalClientes,
    CAST(c.ClientesUnicos * 100.0 / tc.TotalClientes AS DECIMAL(5,2)) AS PorcentajeClientes
FROM Top5Productos t
JOIN ClientesPorProducto c ON t.ProductID = c.ProductID
CROSS JOIN TotalClientes tc
ORDER BY PorcentajeClientes DESC;

--------------------------------------------------------------------------------------------------

--5.- Top 5 productos más vendidos y su categoría
WITH TotalPorProducto AS (
    SELECT 
        p.ProductID,
        p.ProductName,
        p.CategoryID,
        SUM(s.Quantity) AS TotalCantidad
    FROM [dbo].[sales_limpio] s
    JOIN [dbo].[products] p ON s.ProductID = p.ProductID
    GROUP BY p.ProductID, p.ProductName, p.CategoryID
),
Top5Productos AS (
    SELECT TOP 5 *
    FROM TotalPorProducto
    ORDER BY TotalCantidad DESC
),

-- 2️⃣ Total vendido por categoría
TotalPorCategoria AS (
    SELECT 
        p.CategoryID,
        SUM(s.Quantity) AS TotalCategoria
    FROM [dbo].[sales_limpio] s
    JOIN [dbo].[products] p ON s.ProductID = p.ProductID
    GROUP BY p.CategoryID
),

-- 3️⃣ Proporción de cada producto respecto a su categoría usando función de ventana
ProporcionProductoCategoria AS (
    SELECT 
        t.ProductID,
        t.ProductName,
        t.CategoryID,
        t.TotalCantidad,
        c.TotalCategoria,
        CAST(t.TotalCantidad * 100.0 / c.TotalCategoria AS DECIMAL(5,2)) AS PorcentajeCategoria,
        RANK() OVER (PARTITION BY t.CategoryID ORDER BY t.TotalCantidad DESC) AS RankingCategoria
    FROM Top5Productos t
    JOIN TotalPorCategoria c ON t.CategoryID = c.CategoryID
)

-- 4️⃣ Resultado final con categoría y proporción
SELECT 
    p.ProductID,
    p.ProductName,
    p.CategoryID,
    p.TotalCantidad AS UnidadesVendidas,
    p.TotalCategoria AS TotalCategoria,
    p.PorcentajeCategoria,
    p.RankingCategoria
FROM ProporcionProductoCategoria p
ORDER BY p.PorcentajeCategoria DESC;

------------------------------------------------------------------------------
--6.- Total vendido por producto
WITH TotalPorProducto AS (
    SELECT 
        p.ProductID,
        p.ProductName,
        p.CategoryID,
        SUM(s.Quantity) AS TotalCantidad
    FROM [dbo].[sales_limpio] s
    JOIN [dbo].[products] p ON s.ProductID = p.ProductID
    GROUP BY p.ProductID, p.ProductName, p.CategoryID
),

-- 2️⃣ Total vendido por categoría
TotalPorCategoria AS (
    SELECT 
        p.CategoryID,
        SUM(s.Quantity) AS TotalCategoria
    FROM [dbo].[sales_limpio] s
    JOIN [dbo].[products] p ON s.ProductID = p.ProductID
    GROUP BY p.CategoryID
),

-- 3️⃣ Ranking dentro de la categoría usando función de ventana
RankingPorCategoria AS (
    SELECT 
        tp.ProductID,
        tp.ProductName,
        tp.CategoryID,
        tp.TotalCantidad,
        tc.TotalCategoria,
        CAST(tp.TotalCantidad * 100.0 / tc.TotalCategoria AS DECIMAL(5,2)) AS PorcentajeCategoria,
        RANK() OVER (PARTITION BY tp.CategoryID ORDER BY tp.TotalCantidad DESC) AS RankingCategoria
    FROM TotalPorProducto tp
    JOIN TotalPorCategoria tc ON tp.CategoryID = tc.CategoryID
)

-- 4️⃣ Seleccionamos los 10 productos con más unidades vendidas en todo el catálogo
SELECT TOP 10
    r.ProductID,
    r.ProductName,
    r.CategoryID,
    r.TotalCantidad AS UnidadesVendidas,
    r.TotalCategoria AS TotalCategoria,
    r.PorcentajeCategoria,
    r.RankingCategoria
FROM RankingPorCategoria r
ORDER BY r.TotalCantidad DESC;


SELECT COUNT(*) AS TotalVendedores
FROM [dbo].[employees];

SELECT 
    e.EmployeeID,
    e.FirstName + ' ' + e.LastName AS Vendedor
FROM [dbo].[employees] e
ORDER BY Vendedor;

-- Total de vendedores
SELECT COUNT(*) AS TotalVendedores
FROM [dbo].[employees];

------------------------------------------------------
-- Cinco productos más vendidos y el vendedor que más unidades vendió de cada uno, mostrando ProductID y CategoryID primero
WITH TotalPorProducto AS (
    SELECT 
        p.ProductID,
        p.CategoryID,           -- 🔹 Agregado
        p.ProductName,
        SUM(s.Quantity) AS TotalCantidad
    FROM [dbo].[sales_limpio] s
    JOIN [dbo].[products] p ON s.ProductID = p.ProductID
    GROUP BY p.ProductID, p.CategoryID, p.ProductName
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
    FROM [dbo].[sales_limpio] s
    JOIN [dbo].[employees] e ON s.SalesPersonID = e.EmployeeID
    WHERE s.ProductID IN (SELECT ProductID FROM Top5Productos)
    GROUP BY s.ProductID, e.EmployeeID, e.FirstName, e.LastName
)
SELECT 
    t.ProductID,             -- 🔹 Primero
    t.CategoryID,            -- 🔹 Luego
    t.ProductName,
    t.TotalCantidad AS TotalVendido,
    v.Vendedor,
    v.CantidadVendida AS UnidadesVendedorTop
FROM Top5Productos t
JOIN VendedorPorProducto v ON t.ProductID = v.ProductID
WHERE v.rn = 1
ORDER BY t.TotalCantidad DESC;

