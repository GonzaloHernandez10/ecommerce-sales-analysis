-- ============================================
-- PROYECTO: Análisis E-Commerce Olist
-- BASE DE DATOS: MySQL
-- Fase 3: Análisis Exploratorio (EDA)
-- ============================================

-- ============================================
-- EDA 1: Estructura de la tabla orders 
-- Pregunta: ¿Cómo son los datos de la tabla ordenes?
-- ============================================
SELECT * FROM orders AS o ORDER BY RAND() LIMIT 50;

-- ============================================
-- EDA 2: Rango temporal de la tabla orders
-- Pregunta: ¿Cúal es el rango temporal de las ordenes?
-- ============================================
SELECT 
	MIN(o.order_purchase_timestamp) AS primera_orden,
	MAX(o.order_purchase_timestamp) AS ultima_orden
FROM orders AS o
WHERE o.order_purchase_timestamp IS NOT NULL;

-- Verificación de fechas ilógicas en las ordenes
SELECT COUNT(*) AS fechas_ilogicas
FROM orders AS o
WHERE o.order_delivered_customer_date < o.order_purchase_timestamp AND
o.order_status = 'delivered' AND 
o.order_delivered_customer_date IS NOT NULL;

-- ============================================
-- EDA 3: Distribución de estatus de la tabla orders
-- Pregunta: ¿Qué estatus tienen las ordenes y cuáles 
-- son relevantes para el análisis?
-- ============================================
SELECT o.order_status, 
		 COUNT(*) AS total_orders,
		 ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS porcentaje
FROM orders AS o
GROUP BY o.order_status
ORDER BY total_orders DESC;

-- ============================================
-- EDA 4: Nulos en columnas clave del análisis
-- Pregunta: ¿Qué tan completos están los datos en las 
-- columnas relevantes?
-- ============================================

-- Verificación de cuantas ordenes, con estatus 'delivered' o 'shipped', 
-- no tienen fecha de compra, fecha de entrega registrada o una fecha de 
-- de entrega estimada
SELECT 
	SUM(
		CASE WHEN o.order_purchase_timestamp IS NULL THEN 1 ELSE 0 END
	) AS nulo_fecha_compra,
	SUM(
		CASE WHEN o.order_delivered_customer_date IS NULL THEN 1 ELSE 0 END
	) AS nulo_fecha_entrega,
	SUM(
		CASE WHEN o.order_estimated_delivery_date IS NULL THEN 1 ELSE 0 END
	) AS nulo_fecha_estimada_compra
FROM orders AS o
WHERE o.order_status IN ('delivered', 'shipped');

-- Verificación de cuantos items no tienen precio o 
-- precio de envío registrado en base a las ordenes 
-- con estatus 'delivered' o 'shipped'
SELECT 
	SUM(
		CASE WHEN oi.price IS NULL THEN 1 ELSE 0 END
	) AS nulos_precio_item,
	SUM(
		CASE WHEN oi.freight_value IS NULL THEN 1 ELSE 0 END
	) AS nulos_envio_item
FROM orders AS o 
JOIN order_items AS oi 
ON o.order_id = oi.order_id
WHERE o.order_status IN ('delivered', 'shipped');

-- Verificar cuantos productos no tienen una categoría
-- registrada en base a las ordenes con estatus 
-- 'delivered'o'shipped'
SELECT 
	SUM(
		CASE WHEN p.product_category_name IS NULL THEN 1 ELSE 0 END
	) nulos_categoria
FROM order_items AS oi
JOIN products AS p ON oi.product_id = p.product_id
JOIN orders AS o ON o.order_id = oi.order_id
WHERE o.order_status IN ('delivered', 'shipped');

-- Verificación de cuentas ordenes, con estatus 'delivered' 
-- o 'shipped', no tienen una calificación registrada
SELECT COUNT(*) AS nulos_calificacion
FROM orders AS o
WHERE NOT EXISTS(
	SELECT 1
	FROM order_reviews AS orv
	WHERE o.order_id = orv.order_id
) AND o.order_status IN ('delivered','shipped');

-- Veficación de cuantos clientes no tienen una ciudad y 
-- estado asociado
SELECT 
	SUM(CASE WHEN c.customer_city IS NULL THEN 1 ELSE 0 END) AS ciudades_nulas,
	SUM(CASE WHEN c.customer_state IS NULL THEN 1 ELSE 0 END) AS estados_nulos 
FROM orders AS o 
JOIN customers AS c ON o.customer_id = c.customer_id
WHERE o.order_status IN ('delivered', 'shipped');

-- Verificación de posibles métodos de pago faltantes 
-- por fallas en sistema u otras causas
SELECT 
	SUM(CASE WHEN op.payment_type IS NULL THEN 1 ELSE 0 END) AS tipos_pago_nulos,
	SUM(CASE WHEN op.payment_installments IS NULL THEN 1 ELSE 0 END) AS cuotas_nulas
FROM orders AS o
JOIN order_payments AS op ON o.order_id = op.order_id
WHERE o.order_status IN ('delivered', 'shipped'); 

-- Verificación de valores faltantes en las traducciones 
-- de las categorias
SELECT 
	SUM(CASE WHEN ct.product_category_name_english IS NULL THEN 1 ELSE 0 END) AS categorias_nulas
FROM category_translation AS ct; 


-- ============================================
-- EDA 5: Revisión de rangos en precios
-- Pregunta: ¿Hay precios anómalos como ceros, valores negativos 
-- o valores extremos en los precios?
-- ============================================

-- Verificación de los valores en la columna price
SELECT 
	ROUND(MIN(oi.price)) AS minimo_precio,
	ROUND(MAX(oi.price)) AS maximo_precio,
	ROUND(AVG(oi.price)) AS promedio_precio,
	COUNT(CASE WHEN oi.price = 0 THEN 1 END) AS ceros_precio,
	COUNT(CASE WHEN oi.price < 0 THEN 1 END) AS negativos_precio 
FROM order_items AS oi
JOIN orders AS o ON oi.order_id = o.order_id
WHERE o.order_status IN ('delivered', 'shipped');

-- Cálculo de la mediana en price
SET @rowcount = 0;
SET @total = (
    SELECT COUNT(*)
    FROM order_items AS oi
    JOIN orders AS o ON oi.order_id = o.order_id
    WHERE o.order_status IN ('delivered', 'shipped')
    AND oi.price > 0
);

SELECT ROUND(AVG(price), 2) AS mediana_precio
FROM (
    SELECT oi.price, @rowcount := @rowcount + 1 AS fila
    FROM order_items AS oi
    JOIN orders AS o ON oi.order_id = o.order_id
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
	COUNT(CASE WHEN oi.freight_value = 0 THEN 1 END) AS ceros_precio_envio,
	COUNT(CASE WHEN oi.freight_value < 0 THEN 1 END) AS negativos_precio_envio
FROM order_items AS oi
JOIN orders AS o ON oi.order_id = o.order_id
WHERE o.order_status IN ('delivered', 'shipped');

-- Cálculo de la mediana en freight_value
SET @rowcount = 0;
SET @total = (
    SELECT COUNT(*)
    FROM order_items AS oi
    JOIN orders AS o ON oi.order_id = o.order_id
    WHERE o.order_status IN ('delivered', 'shipped')
    AND oi.freight_value > 0
);

SELECT ROUND(AVG(freight_value), 2) AS mediana_flete
FROM (
    SELECT oi.freight_value, @rowcount := @rowcount + 1 AS fila
    FROM order_items AS oi
    JOIN orders AS o ON oi.order_id = o.order_id
    WHERE o.order_status IN ('delivered', 'shipped')
    AND oi.freight_value > 0
    ORDER BY oi.freight_value
) AS datos_ordenados
WHERE fila IN (FLOOR((@total + 1) / 2), CEIL((@total + 1) / 2));

-- ============================================
-- EDA 6: Revisión de las ordenes y sus calificaciones
-- Pregunta: ¿Qué calificaciones existen y cómo se distribuyen?
-- ============================================
SELECT orw.review_score,
		COUNT(*) AS total_puntuacion,
		ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS total_puntuacion_porcentaje
FROM order_reviews AS orw
JOIN orders AS o ON orw.order_id = o.order_id
WHERE o.order_status IN ('delivered', 'shipped')
GROUP BY orw.review_score
ORDER BY orw.review_score DESC;

-- ============================================
-- EDA 7: Revisión de duplicados en tablas clave
-- Pregunta: ¿Existen registros duplicados en las tablas clave del análisis?
-- ============================================

-- ¿Hay ordenes duplicadas?
SELECT o.order_id, COUNT(*) AS repeticiones
FROM orders AS o
GROUP BY o.order_id
HAVING COUNT(*) > 1;

-- ¿Hay clientes duplicados?
SELECT c.customer_id, COUNT(*) AS repeticiones
FROM customers AS c
GROUP BY c.customer_id
HAVING COUNT(*) > 1;

-- ¿Hay items duplicados?
SELECT oi.order_id, oi.order_item_id, COUNT(*) AS repeticiones 
FROM order_items AS oi
GROUP BY oi.order_id, oi.order_item_id
HAVING COUNT(*) > 1;

-- ¿Hay ordenes pagadas duplicadas?
SELECT op.order_id, op.payment_sequential, COUNT(*) AS repeticiones 
FROM order_payments AS op
GROUP BY op.order_id, op.payment_sequential
HAVING COUNT(*) > 1;

-- ¿Hay reseñas duplicadas?
SELECT orr.review_id, COUNT(*) AS repeticiones
FROM order_reviews AS orr
GROUP BY orr.review_id 
HAVING COUNT(*) > 1;

-- ============================================
-- EDA 8: Validación de confiabilidad en los ingresos
-- Pregunta: ¿El total esperado de ingresos (price + freight_value) coincide con
-- el total registrado en los pagos (payment_value)? ¿Son confiables los datos de
-- ingresos para el análisis?
-- ============================================

-- Creación de CTE's que calculen el total esperado, el total pagado y la diferencia entre totales
WITH 
	precio_esperado AS (
		SELECT oi.order_id, SUM(oi.price + oi.freight_value) AS total 
		FROM order_items AS oi
		GROUP BY oi.order_id
	),
	precio_pagado AS (
		SELECT op.order_id, SUM(op.payment_value) AS total
		FROM order_payments AS op 
		GROUP BY op.order_id
	),
	diferencias AS (
		SELECT ABS(pe.total - pp.total) AS diferencia
		FROM orders AS o 
		JOIN precio_esperado AS pe ON o.order_id = pe.order_id
		JOIN precio_pagado AS pp ON o.order_id = pp.order_id
		WHERE o.order_status IN ('delivered', 'shipped')
	)
-- Verificación de las órdenes con diferencia, la diferencia máxima y la diferencia promedio
SELECT 
	COUNT(*) AS ordenes_con_diferencia,
   ROUND(MAX(diferencia), 2) AS diferencia_maxima,
   ROUND(AVG(diferencia), 2) AS diferencia_promedio
FROM diferencias AS d 
WHERE d.diferencia > 1; 

-- Creación de CTE's que calculen el total esperado, el total pagado y las órdenes que fueron pagadas con
-- vaucher
WITH 
	precio_esperado AS (
		SELECT oi.order_id, SUM(oi.price + oi.freight_value) AS total
		FROM order_items AS oi
		GROUP BY oi.order_id
	),
	precio_pagado AS (
		SELECT op.order_id, 
				 SUM(op.payment_value) AS total, 
				 SUM(CASE WHEN op.payment_type = 'voucher' THEN op.payment_value ELSE 0 END) AS total_vaucher
		FROM order_payments AS op
		GROUP BY op.order_id
	)
-- Verificación del total de órdenes que fueron pagadas con vaucher y total que no fueron pagadas con 
-- vaucher
SELECT 
	COUNT(*) AS ordenes_con_diferencia,
	SUM(CASE WHEN pp.total_vaucher > 0 THEN 1 ELSE 0 END) AS con_vaucher,
	SUM(CASE WHEN pp.total_vaucher = 0 THEN 1 ELSE 0 END) AS sin_vaucher
FROM orders AS o
JOIN precio_esperado AS pe ON o.order_id = pe.order_id
JOIN precio_pagado AS pp ON o.order_id = pp.order_id
WHERE o.order_status IN ('delivered', 'shipped') AND ABS(pe.total - pp.total) > 1;

-- Creación de CTE's que calculen el total esperado, el total pagado, los métodos de pago y las cuotas de
-- pago
WITH 
	precio_esperado AS (
		SELECT oi.order_id, SUM(oi.price + oi.freight_value) AS total
      FROM order_items AS oi
      GROUP BY oi.order_id
	),
	precio_pagado AS (
		SELECT op.order_id,
			 	 SUM(op.payment_value) AS total,
             GROUP_CONCAT(op.payment_type) AS metodos_pago,
         	 MAX(op.payment_installments) AS cuotas_maximas
   	FROM order_payments AS op
      GROUP BY op.order_id
	)
-- Verificación de la diferencia entre el total esperado y el total pagado, así como el método de pago y 
-- las cuotas de pago
SELECT 
	o.order_id,
	ROUND(pe.total, 2) AS total_esperado,
   ROUND(pp.total, 2) AS total_pagado,
	ROUND(ABS(pe.total - pp.total), 2) AS diferencia,
   pp.metodos_pago,
   pp.cuotas_maximas
FROM orders AS o
JOIN precio_esperado AS pe ON o.order_id = pe.order_id
JOIN precio_pagado AS pp ON o.order_id = pp.order_id
WHERE o.order_status IN ('delivered', 'shipped') AND ABS(pe.total - pp.total) > 1
ORDER BY diferencia DESC
LIMIT 10;
	








