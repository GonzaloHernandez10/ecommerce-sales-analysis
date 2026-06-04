-- ====================================
-- Verifica JOIN por JOIN en la vista para ver donde esta el error. 
-- ====================================
CREATE VIEW vw_orders_clean AS 
SELECT
	o.order_id,
	o.order_status,
	o.order_purchase_timestamp,
	o.order_delivered_customer_date,
	o.order_estimated_delivery_date,
	orv.review_score,
	oi.price,
	oi.freight_value,
	oi.seller_id,
	c.customer_city,
	c.customer_state,
	ct.product_category_name_english
FROM orders AS o
LEFT JOIN(
	SELECT order_id, ROUND(AVG(review_score),0) AS review_score
   FROM order_reviews
   GROUP BY order_id
) AS orv ON o.order_id = orv.order_id
JOIN customers AS c ON o.customer_id = c.customer_id
JOIN order_items AS oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN category_translation AS ct ON p.product_category_name = ct.product_category_name
WHERE o.order_status IN ('delivered', 'shipped');

-- verificación del total de registros en la vista
SELECT COUNT(*) AS total_registros_vista FROM vw_orders_clean;

-- verificación del total de ordenes unicas en la vista
SELECT COUNT(DISTINCT order_id) AS total_ordenes_unicas_vista FROM vw_orders_clean;
