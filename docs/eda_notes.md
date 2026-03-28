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

**Columnas relevantes:** Para este punto, se determinaron las columnas `order_purchase_timestamp` y `order_delivered_customer_date` de la tabla orders, `price` y `freight_value` de la tabla order_items y `product_category_name` de la tabla products como columnas relevantes.

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
| fecha_compra | 0 | Sin problema. Todas las órdenes tienen fecha de compra. |
| fecha_entrega | 1,115 | 1,107 corresponden a órdenes con status `shipped` sin entrega confirmada. Los 8 restantes son órdenes `delivered` con fecha de entrega ausente, estos 8 registros representan una anomalía. |
| precio_item | 0 | Sin problema. Todos los ítems tienen precio registrado. |
| envio_item | 0 | Sin problema. Todos los ítems tienen valor de flete registrado. |
| categoria_producto | 1,564 | Productos sin categoría asignada en el dataset fuente. Representa ítems cuya categoría no fue registrada por el vendedor. |
| calificacion_cliente | 61,113 | Órdenes sin reseña asociada. Comportamiento normal, no todos los clientes dejan calificación. |

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
  bajo el contexto del 37.4% de los clientes que dejaron si dejaron una reseña
  (36,472 de 97,585 órdenes válidas), no al total.
  
---
