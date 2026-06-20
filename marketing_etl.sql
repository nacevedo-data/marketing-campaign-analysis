---------------------------------------------------------------------------
-- Crear la Base de Datos --
---------------------------------------------------------------------------
Create Database  mkt_campaign;
use mkt_campaign;
---------------------------------------------------------------------------
-- Vamos a crear el siguiente Star Schema: --
# fact_purchases
#    ↕
# dim_customer — dim_campaign — dim_date
---------------------------------------------------------------------------
-- Crear Dimensiones --
---------------------------------------------------------------------------
CREATE TABLE dim_customer(
    customer_id INT PRIMARY KEY,
    Age INT,
    Education VARCHAR(50),
    Marital_Status VARCHAR(50),
    Has_Children INT,
    Income DECIMAL(10,2),
    Dt_Customer DATE
);
    
CREATE TABLE dim_campaign(
	campaign_id INT PRIMARY KEY,
	campaign_name VARCHAR(50)
    );

CREATE TABLE dim_fecha (
    date_id DATE PRIMARY KEY,
    year INT,
    month INT,
    day INT,
    quarter INT,
    day_of_week VARCHAR(20)
);

-- Crear Tabla de hechos --
CREATE TABLE fact_purchases(
    purchase_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT,
    campaign_id INT,
    date_id DATE,

    -- Métricas
    Recency INT,
    MntWines INT,
    MntFruits INT,
    MntMeatProducts INT,
    MntFishProducts INT,
    MntSweetProducts INT,
    MntGoldProds INT,
    NumDealsPurchases INT,
    NumWebPurchases INT,
    NumCatalogPurchases INT,
    NumStorePurchases INT,
    NumWebVisitsMonth INT,
    AcceptedCmp3 INT,
    AcceptedCmp4 INT,
    AcceptedCmp5 INT,
    AcceptedCmp1 INT,
    AcceptedCmp2 INT,
    Complain INT,
    Response INT,

    -- FK
    FOREIGN KEY (customer_id) REFERENCES dim_customer(customer_id),
    FOREIGN KEY (campaign_id) REFERENCES dim_campaign(campaign_id),
    FOREIGN KEY (date_id) REFERENCES dim_fecha(date_id)
   );

# Agregar columna total_spending (Gasto total)
ALTER TABLE fact_purchases ADD total_spending INT;
ALTER TABLE fact_purchases ADD Total_Campaigns_Accepted INT;

SET SQL_SAFE_UPDATES = 0;

UPDATE fact_purchases
SET Total_Spending = MntWines + MntFruits + MntMeatProducts 
                   + MntFishProducts + MntSweetProducts + MntGoldProds;

UPDATE fact_purchases
SET Total_Campaigns_Accepted = AcceptedCmp3 + AcceptedCmp4 + AcceptedCmp5 + AcceptedCmp1 + AcceptedCmp2 + Response
;                   

CREATE TABLE staging_marketing(
	ID VARCHAR(100),
	Year_Birth VARCHAR(100),
	Education VARCHAR(100),
	Marital_Status VARCHAR(100),
	Income VARCHAR(100),
	Kidhome VARCHAR(100),
	Teenhome VARCHAR(100),
	Dt_Customer VARCHAR(100),
	Recency VARCHAR(100),
	MntWines VARCHAR(100),
	MntFruits VARCHAR(100),
	MntMeatProducts VARCHAR(100),
	MntFishProducts VARCHAR(100),
	MntSweetProducts VARCHAR(100),
	MntGoldProds VARCHAR(100),
	NumDealsPurchases VARCHAR(100),
	NumWebPurchases VARCHAR(100),
	NumCatalogPurchases VARCHAR(100),
	NumStorePurchases VARCHAR(100),
	NumWebVisitsMonth VARCHAR(100),
	AcceptedCmp3 VARCHAR(100),
	AcceptedCmp4 VARCHAR(100),
	AcceptedCmp5 VARCHAR(100),
	AcceptedCmp1 VARCHAR(100),
	AcceptedCmp2 VARCHAR(100),
	Complain VARCHAR(100),
    Z_CostContact VARCHAR(100),
	Z_Revenue VARCHAR(100),
	Response VARCHAR(100),
	Age VARCHAR(100),
	Total_Spending VARCHAR(100),
	Total_Campaigns_Accepted VARCHAR(100),
	Has_Children VARCHAR(100)
    );

SET GLOBAL local_infile = 1; # Activa el LOAD DATA LOCAL INFILE
    
LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/marketing_campaign_clean.csv'
INTO TABLE staging_marketing
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(ID, Year_Birth, Education, Marital_Status, Income, Kidhome, Teenhome, Dt_Customer, Recency, MntWines, MntFruits, MntMeatProducts, MntFishProducts, MntSweetProducts, MntGoldProds,
NumDealsPurchases, NumWebPurchases, NumCatalogPurchases, NumStorePurchases, NumWebVisitsMonth, AcceptedCmp3, AcceptedCmp4, AcceptedCmp5, AcceptedCmp1, AcceptedCmp2,
Complain, Z_CostContact, Z_Revenue, Response, Age, Total_Spending, Total_Campaigns_Accepted, Has_Children)
;

# Verificacion
SELECT COUNT(*) FROM staging_marketing;
# Se cargaron 2236 filas, coincide con el shape final del df limpio.
---------------------------------------------------------------------------
-- Carga de los datos --
---------------------------------------------------------------------------
INSERT INTO dim_customer
SELECT ID, Age, Education, Marital_Status, Has_Children, Income, Dt_Customer 
FROM staging_marketing
;
# Verificacion de carga
SELECT COUNT(*) FROM dim_customer;

INSERT INTO dim_campaign (campaign_id, campaign_name) VALUES
(1, 'Campaign 1'),
(2, 'Campaign 2'),
(3, 'Campaign 3'),
(4, 'Campaign 4'),
(5, 'Campaign 5'),
(6, 'Last Campaign');

# Verificacion de carga
SELECT COUNT(*) FROM dim_campaign;
# Se cargaron 6 filas

INSERT INTO dim_fecha
SELECT DISTINCT 
    Dt_Customer,
    YEAR(Dt_Customer),
    MONTH(Dt_Customer),
    DAY(Dt_Customer),
    QUARTER(Dt_Customer),
    dayname(Dt_Customer)
FROM staging_marketing;

# Verificacion de carga
SELECT COUNT(*) FROM dim_fecha;
# Se cargaron 663 filas

# En la staging no existe una columna campaign_id directamente. Las campañas están representadas como columnas separadas: AcceptedCmp1, AcceptedCmp2, etc.
# Esto es un desafío de modelado. 
# En este proyecto no vamos a usar campaign_id en la fact table y dejaremos las columnas AcceptedCmp1 a AcceptedCmp5 y Response directamente como métricas

ALTER TABLE fact_purchases DROP FOREIGN KEY fact_purchases_ibfk_2;
ALTER TABLE fact_purchases DROP COLUMN campaign_id;

INSERT INTO fact_purchases 
(customer_id, date_id, Recency, MntWines, MntFruits, MntMeatProducts, 
MntFishProducts, MntSweetProducts, MntGoldProds, NumDealsPurchases, 
NumWebPurchases, NumCatalogPurchases, NumStorePurchases, NumWebVisitsMonth, 
AcceptedCmp3, AcceptedCmp4, AcceptedCmp5, AcceptedCmp1, AcceptedCmp2, 
Complain, Response)
SELECT 
ID, Dt_Customer, Recency, MntWines, MntFruits, MntMeatProducts,
MntFishProducts, MntSweetProducts, MntGoldProds, NumDealsPurchases,
NumWebPurchases, NumCatalogPurchases, NumStorePurchases, NumWebVisitsMonth,
AcceptedCmp3, AcceptedCmp4, AcceptedCmp5, AcceptedCmp1, AcceptedCmp2,
Complain, Response
FROM staging_marketing;

# Verificacion de carga
SELECT COUNT(*) FROM fact_purchases;
# Se cargaron 2236 filas

-- Resumen de la Etapa 2:
# ✅ Base de datos mkt_campaign creada
# ✅ Star schema diseñado: fact_purchases + 3 dimensiones
# ✅ Tabla staging cargada con 2236 registros
# ✅ dim_customer — 2236 filas
# ✅ dim_campaign — 6 filas
# ✅ dim_fecha — 663 filas
# ✅ fact_purchases — 2236 filas

--------------------------------------------------------------------------------------------------
-- Consultas de Negocio --
--------------------------------------------------------------------------------------------------
# 1. ¿Cuál es el gasto promedio total por nivel educativo?

SELECT 
    dc.Education,
    AVG(total_spending) AS gasto_promedio
FROM fact_purchases fp
JOIN dim_customer dc ON fp.customer_id = dc.customer_id
GROUP BY Education
ORDER BY gasto_promedio DESC;

-- Conclusión -- 
# Gasto promedio por nivel educativo. Los clientes con PhD lideran el gasto promedio con $669, seguidos por Graduation ($620) y Master ($572). 
# Los clientes con nivel Basic se encuentran muy por debajo con $81 promedio, lo que refleja una correlación directa entre nivel educativo e ingreso disponible.

--

# 2. ¿Cuál es la tasa de aceptación de la última campaña (Response) por estado civil?
SELECT 
	dc.Marital_Status,
    AVG(Response) AS aceptacion_last_campaign
FROM fact_purchases fp
JOIN dim_customer dc ON fp.customer_id = dc.customer_id
GROUP BY Marital_Status
ORDER BY aceptacion_last_campaign DESC;

--  Conclusión -- 
# Tasa de aceptación de la última campaña por estado civil. Los clientes Widow (viudos) presentan la mayor tasa de aceptación con un 24.7%, seguidos por Single (22.4%) y Divorced (20.8%).
# Los clientes Married (11.3%) y Together (10.4%) muestran la menor respuesta, posiblemente asociado a mayores responsabilidades económicas del hogar.

--

# 3. ¿Qué canal usa más cada segmento educativo?
SELECT 
	dc.Education, 
    AVG(NumDealsPurchases) AS Ofertas, 
    AVG(NumWebPurchases) AS Web, 
    AVG(NumCatalogPurchases) AS Catalogo, 
    AVG(NumStorePurchases) AS Tienda, 
    AVG(NumWebVisitsMonth) AS Visitas_Web
FROM fact_purchases fp
JOIN dim_customer dc ON fp.customer_id = dc.customer_id
GROUP BY Education
;

--  Conclusión -- 
# Canal preferido por nivel educativo. La tienda física es el canal dominante en todos los segmentos educativos. Los clientes PhD lideran en compras web (4.42) y catálogo (2.96).
# Los clientes Basic, a pesar de tener las mayores visitas web (6.87), registran las menores compras — lo que sugiere intención de compra sin conversión, posiblemente a la espera de ofertas.

--

# 4. ¿Los clientes con hijos prefieren un canal específico?
SELECT 
	dc.Has_Children, 
    AVG(NumDealsPurchases) AS Ofertas, 
    AVG(NumWebPurchases) AS Web, 
    AVG(NumCatalogPurchases) AS Catalogo, 
    AVG(NumStorePurchases) AS Tienda, 
    AVG(NumWebVisitsMonth) AS Visitas_Web
FROM fact_purchases fp
JOIN dim_customer dc ON fp.customer_id = dc.customer_id
GROUP BY Has_Children
;

--  Conclusión --
# Canal preferido según presencia de hijos. Los clientes sin hijos lideran en tienda física (7.27) y catálogo (4.75), comprando a precio full.
# Los clientes con hijos presentan mayor uso de ofertas (2.79) y más visitas web (6.05) con menor conversión, lo que sugiere búsqueda activa de descuentos antes de comprar.

--

# 5. ¿Qué canal genera más compras en promedio?
SELECT 
	AVG(NumDealsPurchases) AS Ofertas, 
    AVG(NumWebPurchases) AS Web, 
    AVG(NumCatalogPurchases) AS Catalogo, 
    AVG(NumStorePurchases) AS Tienda, 
    AVG(NumWebVisitsMonth) AS Visitas_Web
FROM fact_purchases
;

--  Conclusión --
#  Ranking general de canales. La tienda física lidera con 5.79 compras promedio por cliente, seguida por la web con 4.09, visitas web con 5.32, catálogo con 2.66 y ofertas con 2.33.

--------------------------------------------------------------------------------------------------
-- Descarga de los archivos --
--------------------------------------------------------------------------------------------------
SELECT 'customer_id', 'Age', 'Education', 'Marital_Status', 'Has_Children', 'Income', 'Dt_Customer'
UNION ALL
SELECT customer_id, Age, Education, Marital_Status, Has_Children, 
       REPLACE(Income, '.', ','),
       Dt_Customer
FROM dim_customer
INTO OUTFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/dim_customer.csv'
FIELDS TERMINATED BY ';' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n';

SELECT 'campaign_id', 'campaign_name'
UNION ALL SELECT * FROM dim_campaign
INTO OUTFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/dim_campaign.csv'
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n';

SELECT 'date_id', 'year', 'month', 'day', 'quarter', 'day_of_week'
UNION ALL SELECT * FROM dim_fecha
INTO OUTFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/dim_fecha.csv'
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n';

SELECT 'purchase_id', 'customer_id', 'date_id', 'Recency', 'MntWines', 'MntFruits', 'MntMeatProducts', 'MntFishProducts', 'MntSweetProducts', 'MntGoldProds', 'NumDealsPurchases', 'NumWebPurchases', 'NumCatalogPurchases', 'NumStorePurchases', 'NumWebVisitsMonth', 'AcceptedCmp3', 'AcceptedCmp4', 'AcceptedCmp5', 'AcceptedCmp1', 'AcceptedCmp2', 'Complain', 'Response', 'Total_Spending', 'Total_Campaigns_Accepted'
UNION ALL SELECT * FROM fact_purchases
INTO OUTFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/fact_purchases.csv'
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n';

