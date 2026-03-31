# Notas de EDA — Análisis E-Commerce Olist

Este documento registra los hallazgos del análisis exploratorio de datos (EDA)
realizado sobre el dataset de Olist. Cada entrada documenta la pregunta planteada,
el hallazgo obtenido y la decisión analítica derivada.

---

### EDA 1 — Estructura de la tabla orders

**Pregunta:** ¿Cómo son los datos de la tabla orders?

**Query:**
```sql
SELECT * FROM orders AS o ORDER BY RAND() LIMIT 10;
```

**Hallazgo:**
La tabla orders contiene 8 columnas: `order_id`, `customer_id`, `order_status`,
`order_purchase_timestamp`, `order_approved_at`, `order_delivered_carrier_date`,
`order_delivered_customer_date` y `order_estimated_delivery_date`. Las fechas siguen
el formato `YYYY-MM-DD HH:MM:SS`. Algunas columnas de fecha presentan valores nulos
visibles en el muestreo aleatorio, particularmente en `order_delivered_customer_date`
y `order_delivered_carrier_date`, lo que sugiere órdenes que no completaron el ciclo
de entrega.

**Decisión analítica:**
Se identifican las columnas de fecha de entrega como candidatas a revisión de nulos. 
El muestreo aleatorio con `ORDER BY RAND()` se usa para evitar el sesgo de inspeccionar 
únicamente las primeras filas del dataset.

---

### EDA 2 — Rango temporal de la tabla orders

**Pregunta:** ¿Cuál es el rango temporal de las órdenes?

**Query:**
```sql
SELECT
    MIN(o.order_purchase_timestamp) AS primera_orden,
    MAX(o.order_purchase_timestamp) AS ultima_orden
FROM orders AS o
WHERE o.order_purchase_timestamp IS NOT NULL;
```

**Hallazgo:**
El dataset cubre un periodo de aproximadamente 25 meses:

| Campo | Valor |
|---|---|
| primera_orden | 2016-09-04 21:15:19 |
| ultima_orden  | 2018-10-17 17:30:18 |

**Decisión analítica:**
Tres consideraciones para el análisis temporal:

- Los meses de septiembre a diciembre de 2016 representan el periodo de arranque
  de Olist y tienen volúmenes bajos que no reflejan el negocio maduro. Se conservan
  en el análisis pero se interpretan con ese contexto.
- Octubre de 2018 es el último mes del dataset y está incompleto, por lo que
  su volumen no es comparable con meses anteriores. Se considerará este factor
  al interpretar la tendencia al final del periodo.

---

### EDA 3 — Distribución de estatus de la tabla orders

**Pregunta:** ¿Qué estatus tienen las órdenes y cuáles son relevantes para el análisis?

**Query:**
```sql
SELECT o.order_status,
       COUNT(*) AS total_orders,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS porcentaje
FROM orders AS o
GROUP BY o.order_status
ORDER BY total_orders DESC;
```

**Hallazgo:**

| order_status | total_orders | porcentaje |
|---|---|---|
| delivered | 96,478 | 97.02% |
| shipped | 1,107 | 1.11% |
| canceled | 625 | 0.63% |
| unavailable | 609 | 0.61% |
| invoiced | 314 | 0.32% |
| processing | 301 | 0.30% |
| created | 5 | 0.01% |
| approved | 2 | 0.00% |

El 97.02% de las órdenes tienen estado `delivered`. Los estados `invoiced`,
`processing`, `created` y `approved` representan órdenes en etapas administrativas
previas al despacho o la entrega, sin valor comercial concretado. Los estados `canceled` y
`unavailable` representan transacciones que no generaron valor real.

**Decisión analítica:**
Se toman únicamente `delivered` y `shipped` como órdenes con valor
comercial válido. `shipped` representa órdenes reales, pagadas y en tránsito hacia
el cliente. Se excluyen `canceled`, `unavailable`, `invoiced`, `processing`,
`created` y `approved`, ya que no representan ventas concretadas.

Esto implica excluir 1,856 órdenes (1.87% del total), quedando 97,585 órdenes
válidas para el análisis.

**Nota:** Las queries que involucren tiempo de entrega o calificaciones de clientes
filtrarán únicamente `delivered`, ya que las órdenes con status `shipped` no tienen
fecha de entrega confirmada ni reseña asociada al momento del análisis.

---

### EDA 4 — Nulos en columnas clave del análisis

**Pregunta:** ¿Qué tan completos están los datos en las columnas relevantes para
el análisis?

**Columnas relevantes:** Para este punto, se determinaron las columnas `order_purchase_timestamp` y `order_delivered_customer_date` de la tabla `orders`, `price` y `freight_value` de la tabla `order_items` y `product_category_name` de la tabla `products` como columnas relevantes.

**Queries:**
```sql
-- Verificación de cuantas ordenes, con estatus 'delivered' o 'shipped', 
-- no tienen fecha de compra o fecha de entrega registrada
SELECT
    SUM(CASE WHEN o.order_purchase_timestamp IS NULL THEN 1 ELSE 0 END) AS nulo_fecha_compra,
    SUM(CASE WHEN o.order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS nulo_fecha_entrega
FROM orders AS o
WHERE o.order_status IN ('delivered', 'shipped');

-- Verificación de cuantos items no tienen precio o precio de envío registrado en
-- base a las ordenes con estatus 'delivered' o 'shipped'
SELECT
    SUM(CASE WHEN oi.price         IS NULL THEN 1 ELSE 0 END) AS nulos_precio_item,
    SUM(CASE WHEN oi.freight_value IS NULL THEN 1 ELSE 0 END) AS nulos_envio_item
FROM orders AS o
JOIN order_items AS oi ON o.order_id = oi.order_id
WHERE o.order_status IN ('delivered', 'shipped');

-- Verificar cuantos productos no tienen una categoría registrada en base a las ordenes con
-- estatus 'delivered' o 'shipped'
SELECT
    SUM(CASE WHEN p.product_category_name IS NULL THEN 1 ELSE 0 END) AS nulos_categoria
FROM order_items AS oi
JOIN products AS p ON oi.product_id = p.product_id
JOIN orders AS o   ON o.order_id    = oi.order_id
WHERE o.order_status IN ('delivered', 'shipped');

-- Verificación de cuentas ordenes, con estatus 'delivered' o 'shipped', no tienen una
-- calificación registrada
SELECT COUNT(*) AS nulos_calificacion
FROM orders AS o
WHERE NOT EXISTS (
    SELECT 1
    FROM order_reviews AS orv
    WHERE o.order_id = orv.order_id
)
AND o.order_status IN ('delivered', 'shipped');
```

**Hallazgos:**

| Columna verificada | Nulos | Interpretación |
|---|---|---|
| order_purchase_timestamp | 0 | Sin problema. Todas las órdenes tienen fecha de compra. |
| order_delivered_customer_date | 1,115 | 1,107 corresponden a órdenes con status `shipped` sin entrega confirmada. Los 8 restantes son órdenes `delivered` con fecha de entrega ausente, estos 8 registros representan una anomalía. |
| price | 0 | Sin problema. Todos los ítems tienen precio registrado. |
| freight_value | 0 | Sin problema. Todos los ítems tienen valor de flete registrado. |
| product_category_name | 1,564 | Productos sin categoría asignada en el dataset fuente. Representa ítems cuya categoría no fue registrada por el vendedor. |
| nulos_calificacion | 61,113 | Órdenes sin reseña asociada. Comportamiento normal, no todos los clientes dejan calificación. |

**Nota técnica sobre la query de calificaciones:**
Se utilizó `NOT EXISTS` con subconsulta en lugar de `LEFT JOIN ... WHERE IS NULL`
porque `NOT EXISTS` es más eficiente, se detiene al encontrar el primer match,
y evita el comportamiento impredecible de `NOT IN` cuando existen valores nulos en la
subconsulta.

**Decisiones analíticas:**

- Las queries que involucren tiempo de entrega filtrarán adicionalmente por
  `order_delivered_customer_date IS NOT NULL` para excluir los 1,115 registros
  sin fecha de entrega.
- Las queries que involucren categoría excluirán los 1,564 productos sin
  categoría con `WHERE product_category_name IS NOT NULL`. Para queries de
  ingresos totales o volumen estos registros sí se incluyen ya que su precio
  es válido para el análisis.
- Las conclusiones sobre satisfacción de clientes en el Acto 2 se presentarán
  bajo el contexto del 37.4% de los clientes que si dejaron una reseña
  (36,472 de 97,585 órdenes válidas), no al total.

---

### EDA 5 — Revisión de rangos y distribución de precios

**Pregunta:** ¿Los valores de precio y precio de envío tienen rangos coherentes con el negocio?
¿Existen valores anómalos que distorsionen el análisis?

**Queries:**
```sql
-- Verificación de los valores en la columna price
SELECT 
	ROUND(MIN(oi.price)) AS minimo_precio,
	ROUND(MAX(oi.price)) AS maximo_precio,
	ROUND(AVG(oi.price)) AS promedio_precio,
	COUNT(CASE WHEN oi.price = 0 THEN 1 END) AS ceros_precio 
FROM order_items AS oi
JOIN orders AS o ON oi.order_id = o.order_id
WHERE o.order_status IN ('delivered', 'shipped');

-- Cálculo de la mediana en price
SET @rowcount = 0;
SET @total = (
    SELECT COUNT(*)
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_status IN ('delivered', 'shipped')
    AND oi.price > 0
);

SELECT ROUND(AVG(price), 2) AS mediana_precio
FROM (
    SELECT oi.price, @rowcount := @rowcount + 1 AS fila
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_status IN ('delivered', 'shipped')
    AND oi.price > 0
    ORDER BY oi.price
) AS datos_ordenados
WHERE fila IN (FLOOR((@total + 1) / 2), CEIL((@total + 1) / 2));

-- Verificación de los valores en la columna freight_value 
SELECT 
	ROUND(MIN(oi.freight_value)) AS minimo_precio_envio,
	ROUND(MAX(oi.freight_value)) AS maximo_precio_envio,
	ROUND(AVG(oi.freight_value)) AS promedio_precio_envio,
	COUNT(CASE WHEN oi.freight_value = 0 THEN 1 END) AS ceros_precio_envio 
FROM order_items AS oi
JOIN orders AS o ON oi.order_id = o.order_id
WHERE o.order_status IN ('delivered', 'shipped');

-- Cálculo de la mediana en freight_value
SET @rowcount = 0;
SET @total = (
    SELECT COUNT(*)
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_status IN ('delivered', 'shipped')
      AND oi.freight_value > 0
);

SELECT ROUND(AVG(freight_value), 2) AS mediana_flete
FROM (
    SELECT oi.freight_value, @rowcount := @rowcount + 1 AS fila
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_status IN ('delivered', 'shipped')
    AND oi.freight_value > 0
    ORDER BY oi.freight_value
) AS datos_ordenados
WHERE fila IN (FLOOR((@total + 1) / 2), CEIL((@total + 1) / 2));
```

**Nota:** Todos los valores monetarios están expresados en **reales brasileños (BRL)**.
Al momento del análisis, 1 BRL ≈ 3.5 MXN.

**Hallazgos:**

| Métrica | price (BRL) | freight_value (BRL) |
|---|---|---|
| Mínimo | 1 | 0 |
| Máximo | 6,735 | 410 |
| Promedio | 120 | 20 |
| Mediana | 44.95 | 8.14 |
| Valores en cero | 0 | 383 |

**Justificación estadística del cálculo de mediana**

El promedio aritmético es una medida de tendencia central sensible a valores
atípicos (outliers). Cuando una distribución de datos no es simétrica, el
promedio se desplaza en la dirección de los valores extremos, dejando de
representar al valor "típico" del conjunto.

Para evaluar si el promedio es una medida representativa se compara contra la
mediana, que por definición divide al conjunto ordenado en dos mitades iguales
y no se ve afectada por los valores extremos.

**Criterio de asimetría:**
- Si promedio ≈ mediana → distribución simétrica, el promedio es representativo.
- Si promedio > mediana → asimetría positiva (cola hacia la derecha), el promedio
  está inflado por valores altos.
- Si promedio < mediana → asimetría negativa (cola hacia la izquierda), el promedio
  está deprimido por valores bajos.

**Resultado del análisis:**

| Columna | Mediana | Promedio | Asimetría |
|---|---|---|---|
| price | 44.95 BRL | 120 BRL | Positiva pronunciada |
| freight_value | 8.14 BRL | 20 BRL | Positiva pronunciada |

En ambos casos el promedio casi **triplica** la mediana, lo que confirma una
**distribución con asimetría positiva pronunciada y cola larga hacia la derecha**.
Esto significa que la mayoría de los productos se venden a precios cercanos a la
mediana (44.95 BRL), pero una minoría de productos con precios muy altos eleva
considerablemente el promedio.

**Interpretación de negocio:**

- Los 383 precios de envío con valor 0 se interpretan como envíos gratuitos, práctica
  común en e-commerce. No son anomalías sino una decisión comercial del vendedor.
- El precio de envío máximo de 410 BRL no es un error. Brasil tiene una extensión territorial
  de 8.5 millones de km² y estados del norte como Amazonas, Roraima y Amapá están
  a más de 3,000 km de los centros de distribución principales. Los precios de envío altos
  pueden ser consecuencia directa de la geografía del país.
- El precio mínimo de 1 BRL genera ruido pero no se excluye del análisis.
  Puede representar productos promocionales o accesorios de bajo costo legítimos.

**Decisiones analíticas:**

- Al reportar ingresos promedio por categoría en el Acto 1 se complementará con
  la mediana para ofrecer una medida representativa más robusta ante la presencia de outliers.
- Los 383 envíos gratuitos se incluyen en el cálculo de ingresos totales ya que
  representan transacciones reales, solo que sin costo de flete para el cliente.
- No se excluye ningún registro por precio, los valores extremos son parte del
  comportamiento real del negocio y su análisis es valioso para el Acto 3.

---

### EDA 6 — Distribución de calificaciones de clientes

**Pregunta:** ¿Qué calificaciones existen y cómo se distribuyen?

**Query:**
```sql
SELECT orw.review_score,
		COUNT(*) AS total_puntuacion,
		ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS total_puntuacion_porcentaje
FROM order_reviews AS orw
JOIN orders AS o ON orw.order_id = o.order_id
WHERE o.order_status IN ('delivered', 'shipped')
GROUP BY orw.review_score
ORDER BY orw.review_score DESC;
```

**Hallazgos:**

| Calificación | Total reseñas | Porcentaje |
|---|---|---|
| 5 — Muy satisfecho | 21,618 | 59.14% |
| 4 — Satisfecho | 7,012 | 19.18% |
| 3 — Indiferente | 3,060 | 8.37% |
| 2 — Insatisfecho | 1,144 | 3.13% |
| 1 — Muy insatisfecho | 3,720 | 10.18% |

**Segmentación de reseñas por sentimiento:**

| Segmento | Calificaciones | Porcentaje |
|---|---|---|
| Positivo | 4 y 5 | 78.32% |
| Neutro | 3 | 8.37% |
| Negativo | 1 y 2 | 13.31% |

Se utiliza el criterio estricto para la segmentación: una calificación de 3 sobre
5 en e-commerce indica una experiencia que no cumplió expectativas aunque tampoco
fue desastrosa, por lo que se clasifica como neutra y no como positiva.

**Interpretación estadística y de negocio:**

La distribución de calificaciones presenta una concentración marcada en el extremo
positivo. El 59.14% de los clientes otorgó la calificación máxima. Sin embargo,
el 13.31% de reseñas negativas (calificaciones 1 y 2) representa el segmento de mayor interés analítico: Esto se podria interpretarse con el **principio de pareto**, identificar qué factores influyen en ese 13% de insatisfacción permitiría resolver el problema que afecta a la mayoría de los clientes inconformes.

Es relevante destacar que la calificación 1 (10.18%) supera ampliamente a la
calificación 2 (3.13%), lo que sugiere que cuando un cliente está insatisfecho,
su experiencia tiende a ser muy negativa y no moderadamente negativa. Esto refuerza
la hipótesis de que el problema de insatisfacción tiene causas concretas e
identificables, no una degradación gradual de la experiencia.

**Decisiones analíticas:**

- Las queries de análisis de satisfacción usarán el criterio estricto:
  calificaciones 4 y 5 = positivas, 3 = neutra, 1 y 2 = negativas.
- Al cruzar calificaciones con categorías y tiempos de entrega en el Acto 2
  se filtrará únicamente `order_status = 'delivered'`, ya que las órdenes
  `shipped` no tienen reseña asociada.
- Todos los porcentajes se calculan sobre el total de reseñas disponibles
  (36,554), no sobre el total de órdenes válidas (97,585), ya que el 62.6%
  de las órdenes no tiene reseña asociada — contexto documentado en el EDA 4.

---
