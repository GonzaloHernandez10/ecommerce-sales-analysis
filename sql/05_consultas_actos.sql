-- =================================================================================================================================================================================================
-- ACTO 1
-- =================================================================================================================================================================================================

-- Pregunta 1 - ¿Cuál es el ingreso total y número de órdenes por mes?
SELECT 
    DATE_FORMAT(vw.order_purchase_timestamp, '%Y-%m') as mes,
    ROUND(SUM(vw.price + vw.freight_value), 2) AS total_ingresos,
    COUNT(DISTINCT vw.order_id) AS total_ordenes
FROM vw_orders_clean AS vw
WHERE vw.order_purchase_timestamp IS NOT NULL
GROUP BY DATE_FORMAT(vw.order_purchase_timestamp, '%Y-%m')
ORDER BY DATE_FORMAT(vw.order_purchase_timestamp, '%Y-%m');

-- Pregunta 2 - ¿Cuáles son las 10 categorías con más ingresos?
SELECT 
    vw.product_category_name_english,
    COUNT(DISTINCT vw.order_id) AS total,
    ROUND(SUM(vw.price + vw.freight_value), 2) AS total_ingresos
FROM vw_orders_clean AS vw
WHERE vw.product_category_name_english IS NOT NULL
GROUP BY vw.product_category_name_english
ORDER BY total_ingresos DESC
LIMIT 10;

-- Pregunta 3 - ¿Cuál es el ticket promedio por categoría?
SELECT
    vw.product_category_name_english,
    ROUND(SUM(vw.price + vw.freight_value) / COUNT(DISTINCT vw.order_id), 2) AS ticket_promedio
FROM vw_orders_clean AS vw
WHERE vw.product_category_name_english IS NOT NULL
GROUP BY vw.product_category_name_english
ORDER BY ticket_promedio DESC;

-- =================================================================================================================================================================================================
-- ACTO 2
-- =================================================================================================================================================================================================

-- Pregunta 1 - ¿Cómo se distribuyen las calificaciones de clientes?
SELECT 
    vw.review_score,
    COUNT(DISTINCT vw.order_id) AS distribucion,
    ROUND(COUNT(DISTINCT vw.order_id) * 100 / SUM(COUNT(DISTINCT vw.order_id)) OVER(), 2) AS distribucion_porcentaje
FROM vw_orders_clean AS vw
WHERE vw.order_status = 'delivered' AND vw.review_score IS NOT NULL
GROUP BY vw.review_score
ORDER BY vw.review_score DESC;

-- Pregunta 2 - ¿Qué categorías tienen peor calificación promedio?
SELECT 
    vw.product_category_name_english,
    ROUND(AVG(vw.review_score), 2) AS calificacion_promedio
FROM vw_orders_clean AS vw
WHERE vw.product_category_name_english IS NOT NULL AND vw.review_score IS NOT NULL AND vw.order_status = 'delivered'
GROUP BY vw.product_category_name_english
HAVING COUNT(DISTINCT vw.order_id) > 50
ORDER BY calificacion_promedio ASC
LIMIT 10;

-- Pregunta 3 - ¿Cuántos días tarda en promedio cada categoría en entregarse?
SELECT 
    vw.product_category_name_english,
    AVG(DATEDIFF(vw.order_delivered_customer_date, vw.order_purchase_timestamp)) AS dias_entrega_promedio
FROM vw_orders_clean AS vw
WHERE 
    vw.order_status = 'delivered' AND 
    vw.product_category_name_english IS NOT NULL AND
    vw.order_delivered_customer_date IS NOT NULL AND 
    vw.order_purchase_timestamp IS NOT NULL
GROUP BY vw.product_category_name_english
ORDER BY dias_entrega_promedio DESC
LIMIT 10;

-- Pregunta 4 - ¿Hay correlación entre tiempo de entrega y calificación?
SELECT 
    CASE WHEN DATEDIFF(vw.order_delivered_customer_date, vw.order_estimated_delivery_date) > 0 THEN 'Retrasado' ELSE 'Normal' END AS tiempo_entrega,
    ROUND(AVG(vw.review_score), 2) AS calificacion_promedio,
    COUNT(DISTINCT vw.order_id) AS total_ordenes
FROM vw_orders_clean AS vw
WHERE 
    vw.order_status = 'delivered' AND 
    vw.review_score IS NOT NULL AND 
    vw.order_delivered_customer_date IS NOT NULL AND 
    vw.order_estimated_delivery_date IS NOT NULL
GROUP BY tiempo_entrega;

-- =================================================================================================================================================================================================
-- ACTO 3
-- =================================================================================================================================================================================================

-- Pregunta 1 - ¿Qué estados concentran la tasa de ordenes e ingresos más alta?
SELECT 
    vw.customer_state,
    ROUND(SUM(vw.freight_value + vw.price), 2) AS total_ingreso_estado,
    COUNT(DISTINCT vw.order_id) AS total_ordenes_estado
FROM vw_orders_clean AS vw
WHERE vw.customer_state IS NOT NULL AND vw.order_status = 'delivered'
GROUP BY vw.customer_state
ORDER BY total_ordenes_estado DESC;

-- Pregunta 2 - ¿Qué estados concentran los peores tiempos de entrega?
SELECT 
    vw.customer_state,
    AVG(DATEDIFF(vw.order_delivered_customer_date, vw.order_purchase_timestamp)) AS dias_entrega_promedio_estado,
    COUNT(DISTINCT vw.order_id) AS total_ordenes_estado
FROM vw_orders_clean AS vw
WHERE 
    vw.order_status = 'delivered' AND 
    vw.order_delivered_customer_date IS NOT NULL AND
    vw.order_purchase_timestamp IS NOT NULL AND
    vw.customer_state IS NOT NULL
GROUP BY vw.customer_state
ORDER BY dias_entrega_promedio_estado DESC;

-- Pregunta 3 - ¿Cuál es la tasa de órdenes entregadas vs canceladas?
SELECT o.order_status, COUNT(*) AS total, ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS porcentaje_total
FROM orders AS o
WHERE o.order_status IN ('delivered', 'canceled')
GROUP BY o.order_status;

-- Pregunta 4 - ¿Qué vendedores tienen más volumen pero peor calificación?
SELECT 
    vw.seller_id, 
    COUNT(DISTINCT vw.order_id) AS total_ordenes, 
    ROUND(AVG(review_score), 2) AS calificacion_promedio
FROM vw_orders_clean as vw
GROUP BY vw.seller_id
HAVING total_ordenes > 100
ORDER BY calificacion_promedio ASC;



