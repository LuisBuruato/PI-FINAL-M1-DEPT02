# PI-FINAL-M1-DEPT02.

# Proyecto Integrador: Análisis de Ventas SUPERMARKET

## 📚 Descripción
Este proyecto integra información de ventas, productos, clientes, empleados, ciudades y países para generar un **dataset final listo para análisis y modelado ML**.  
Se realizaron los avances 1, 2, 3 y 4, incorporando limpieza, transformación, agregación, ingeniería de variables y optimización de consultas.

---

## 🛠 Avances

### Avance 1: Análisis inicial de ventas
- Se identificaron los **cinco productos más vendidos** y los **vendedores con mayor volumen** por producto.
- Consultas SQL optimizadas con `JOIN`, `GROUP BY` y `ROW_NUMBER()`.
- Objetivo: entender las tendencias de ventas y desempeño de los vendedores.

**Ejemplo de consulta:**
```sql
-- Cinco productos más vendidos y su vendedor top
WITH TotalPorProducto AS (
    SELECT 
        p.ProductID,
        p.ProductName,
        SUM(s.Quantity) AS TotalCantidad
    FROM dbo.sales_limpio s
    JOIN dbo.products p ON s.ProductID = p.ProductID
    GROUP BY p.ProductID, p.ProductName
)
SELECT TOP 5 * 
FROM TotalPorProducto
ORDER BY TotalCantidad DESC;


Avance 2: Limpieza y enriquecimiento del dataset

Se calcularon variables importantes:

TotalPriceCalculated = Quantity * Price * (1 - Discount)

Variables de tiempo: HoraVenta, DiaSemana, TipoDia

Variables de experiencia del vendedor: Edad_Contratacion, Experiencia_Anios

Se unieron tablas de clientes, ciudades y países.


Avance 3: Análisis de ventas

Se aplicaron algoritmos clásicos para encontrar periodos de 5 días consecutivos con mayor volumen de ventas.

Se implementaron métodos de fuerza bruta y optimizado con pandas.

Se utilizaron ventanas deslizantes (rolling) y operaciones vectoriales.

Se realizó un análisis de ventas por tipo de día: entre semana vs fin de semana.


Avance 4: Dataset final y preparación para ML

Se creó dataset_final con columnas relevantes:

Variables numéricas: Quantity, Discount, Price, HoraVenta, DiaSemana, Edad_Contratacion, Experiencia_Anios

Variables categóricas: TipoDia, CityName, CountryName (convertidas a One-Hot Encoding)

Estandarización de variables numéricas usando StandardScaler.

Guardado del dataset final para modelado:

output_path = r"C:\Users\luisb\Desktop\PROY. INTEGR 1\AVANCE4.csv"
dataset_final.to_csv(output_path, index=False)

🏗 Pipeline de Datos

flowchart TD
    A[Sales] --> B[Merge con Products]
    B --> C[Calculo TotalPriceCalculated]
    C --> D[Variables temporales: HoraVenta, DiaSemana, TipoDia]
    D --> E[Merge con Employees]
    E --> F[Calculo Edad_Contratacion y Experiencia_Anios]
    F --> G[Merge con Customers, Cities y Countries]
    G --> H[Selección de columnas relevantes]
    H --> I[One-Hot Encoding de variables categóricas]
    I --> J[Estandarización de variables numéricas]
    J --> K[Dataset Final listo para ML]


📝 Conclusión

El proyecto permite:

Analizar tendencias de ventas y desempeño de vendedores.

Preparar un dataset limpio y estandarizado para modelado ML.

Optimizar consultas y trabajar con grandes volúmenes de datos mediante índices y merges eficientes.



