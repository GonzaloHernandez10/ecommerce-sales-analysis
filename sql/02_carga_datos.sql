-- ============================================
-- PROYECTO: Análisis E-Commerce Olist
-- BASE DE DATOS: MySQL
-- Fase 2: Cargar datos
-- ============================================

-- Necesario para desactivar todos los modos SQL estrictos y restricciones de sintaxis
SET SESSION sql_mode = 'NO_ENGINE_SUBSTITUTION';

-- Tabla: clientes
LOAD DATA LOCAL INFILE 'C:/Users/jorge/Downloads/olist/olist_customers_dataset.csv'
INTO TABLE customers
FIELDS TERMINATED BY ',' 
IGNORE 1 LINES
(customer_id, @unique_id, @zip_code, @city, @state)
SET
	customer_unique_id = NULLIF(@unique_id, ''),
	customer_zip_code  = NULLIF(@zip_code,	''),
	customer_city	   = NULLIF(@city, 		''),
	customer_state 	   = NULLIF(@state, 	'');

-- Tabla: vendedores
LOAD DATA LOCAL INFILE 'C:/Users/jorge/Downloads/olist/olist_sellers_dataset.csv'
INTO TABLE sellers
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
IGNORE 1 LINES
(seller_id, @zip_code, @city, @state)
SET
	seller_zip_code	= NULLIF(@zip_code, ''),
	seller_city 	= NULLIF(@city,     ''),
	seller_state	= NULLIF(@state,    '');

-- Tabla: traducción de categorías
LOAD DATA LOCAL INFILE 'C:/Users/jorge/Downloads/olist/product_category_name_translation.csv'
INTO TABLE category_translation
FIELDS TERMINATED BY ',' 
IGNORE 1 LINES
(@category_name, @name_english)
SET
	product_category_name			= NULLIF(@category_name, ''),
	product_category_name_english 	= NULLIF(@name_english,  '');

-- Necesario para evitar inconsistencias entre la tablas category_translation y products
INSERT IGNORE INTO category_translation 
  (product_category_name, product_category_name_english)
VALUES
  ('portateis_cozinha_e_preparadores_de_alimentos', 'portable_kitchen_and_food_preparers'),
  ('pc_gamer', 'pc_gamer');

-- Tabla: productos
LOAD DATA LOCAL INFILE 'C:/Users/jorge/Downloads/olist/olist_products_dataset.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
IGNORE 1 LINES
(product_id, @category, @name_len, @desc_len, @photos, @weight, @length_cm, @height, @width)
SET
	product_category_name       = NULLIF(@category, ''),
	product_name_length         = NULLIF(@name_len, ''),
	product_description_length  = NULLIF(@desc_len, ''),
	product_photos_qty          = NULLIF(@photos,   ''),
	product_weight_g            = NULLIF(@weight,	''),
	product_length_cm           = NULLIF(@length_cm,''),
	product_height_cm           = NULLIF(@height,   ''),
	product_width_cm            = NULLIF(@width,    '');

-- Tabla: órdenes
LOAD DATA LOCAL INFILE 'C:/Users/jorge/Downloads/olist/olist_orders_dataset.csv'
INTO TABLE orders
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
IGNORE 1 LINES
(@order_id, @customer_id, @status, @purchase, @approved, @carrier, @delivered, @estimated)
SET
	order_id                          = TRIM(@order_id),
	customer_id                       = TRIM(@customer_id),
	order_status                      = NULLIF(TRIM(@status),    ''),
	order_purchase_timestamp          = NULLIF(TRIM(@purchase),  ''),
	order_approved_at                 = NULLIF(TRIM(@approved),  ''),
	order_delivered_carrier_date      = NULLIF(TRIM(@carrier),   ''),
	order_delivered_customer_date     = NULLIF(TRIM(@delivered), ''),
	order_estimated_delivery_date     = NULLIF(TRIM(@estimated), '');
  
-- Tabla: ítems por orden 
LOAD DATA LOCAL INFILE 'C:/Users/jorge/Downloads/olist/olist_order_items_dataset.csv'
INTO TABLE order_items
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
IGNORE 1 LINES
(@order_id, @item_id, @product_id, @seller_id, @ship_date, @price, @freight)
SET
	order_id            = TRIM(@order_id),
	order_item_id       = TRIM(@item_id),
	product_id          = NULLIF(TRIM(@product_id),  ''),
	seller_id           = NULLIF(TRIM(@seller_id),   ''),
	shipping_limit_date = NULLIF(TRIM(@ship_date),   ''),
	price               = NULLIF(TRIM(@price),       ''),
	freight_value       = NULLIF(TRIM(@freight),     '');

-- Tabla: pagos
LOAD DATA LOCAL INFILE 'C:/Users/jorge/Downloads/olist/olist_order_payments_dataset.csv'
INTO TABLE order_payments
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
IGNORE 1 LINES
(@order_id, @seq, @type, @installments, @value)
SET
	order_id             = TRIM(@order_id),
	payment_sequential   = TRIM(@seq),
	payment_type         = NULLIF(TRIM(@type),         ''),
	payment_installments = NULLIF(TRIM(@installments), ''),
	payment_value        = NULLIF(TRIM(@value),        '');

-- Tabla: reseñas
LOAD DATA LOCAL INFILE 'C:/Users/jorge/Downloads/olist/olist_order_reviews_dataset.csv'
IGNORE
INTO TABLE order_reviews
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@review_id, @order_id, @score, @title, @message, @creation, @answer)
SET
  review_id               = TRIM(@review_id),
  order_id                = TRIM(@order_id),
  review_score            = NULLIF(TRIM(@score),                     ''),
  review_comment_title    = NULLIF(TRIM(@title),                     ''),
  review_comment_message  = NULLIF(TRIM(@message),                   ''),
  review_creation_date    = NULLIF(TRIM(@creation),                  ''),
  review_answer_timestamp = NULLIF(TRIM(REPLACE(@answer, '\r', '')), '');

-- Verificación de los datos cargados
SELECT 'customers'           				  AS tabla, COUNT(*) AS registros FROM customers
UNION ALL SELECT 'orders',               COUNT(*) FROM orders
UNION ALL SELECT 'order_items',          COUNT(*) FROM order_items
UNION ALL SELECT 'order_payments',       COUNT(*) FROM order_payments
UNION ALL SELECT 'order_reviews',        COUNT(*) FROM order_reviews
UNION ALL SELECT 'products',             COUNT(*) FROM products
UNION ALL SELECT 'sellers',              COUNT(*) FROM sellers
UNION ALL SELECT 'category_translation', COUNT(*) FROM category_translation;
