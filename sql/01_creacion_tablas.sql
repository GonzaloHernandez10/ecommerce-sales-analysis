-- ============================================
-- PROYECTO: Análisis E-Commerce Olist
-- BASE DE DATOS: MySQL
-- Fase 1: Crear schema y tablas
-- ============================================

CREATE DATABASE IF NOT EXISTS olist_ecommerce
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE olist_ecommerce;

-- Tabla: clientes
CREATE TABLE customers (
	customer_id           VARCHAR(50)  PRIMARY KEY,
	customer_unique_id    VARCHAR(50)  NOT NULL,
	customer_zip_code     VARCHAR(10),
	customer_city         VARCHAR(100),
	customer_state        CHAR(2)
);

-- Tabla: vendedores
CREATE TABLE sellers (
  seller_id             VARCHAR(50)  PRIMARY KEY,
  seller_zip_code       VARCHAR(10),
  seller_city           VARCHAR(100),
  seller_state          CHAR(2)
);

-- Tabla: traducción de categorías (se carga antes que products)
CREATE TABLE category_translation (
	product_category_name         VARCHAR(100) PRIMARY KEY,
	product_category_name_english VARCHAR(100)
);

-- Tabla: productos
CREATE TABLE products (
	product_id               VARCHAR(50)  PRIMARY KEY,
	product_category_name    VARCHAR(100),
	product_name_length      INT,
	product_description_length INT,
	product_photos_qty       INT,
	product_weight_g         INT,
	product_length_cm        INT,
	product_height_cm        INT,
	product_width_cm         INT,
	FOREIGN KEY (product_category_name)
	REFERENCES category_translation(product_category_name)
);

-- Tabla: órdenes (núcleo del dataset)
CREATE TABLE orders (
	order_id                        VARCHAR(50)  PRIMARY KEY,
	customer_id                     VARCHAR(50)  NOT NULL,
	order_status                    VARCHAR(30),
	order_purchase_timestamp        DATETIME,
	order_approved_at               DATETIME,
	order_delivered_carrier_date    DATETIME,
	order_delivered_customer_date   DATETIME,
	order_estimated_delivery_date   DATETIME
);

-- Tabla: ítems por orden
CREATE TABLE order_items (
	order_id             VARCHAR(50)  NOT NULL,
	order_item_id        INT          NOT NULL,
	product_id           VARCHAR(50),
	seller_id            VARCHAR(50),
	shipping_limit_date  DATETIME,
	price                DECIMAL(10,2),
	freight_value        DECIMAL(10,2),
	PRIMARY KEY (order_id, order_item_id)
);

-- Tabla: pagos
CREATE TABLE order_payments (
	order_id              VARCHAR(50)  NOT NULL,
	payment_sequential    INT          NOT NULL,
	payment_type          VARCHAR(30),
	payment_installments  INT,
	payment_value         DECIMAL(10,2),
	PRIMARY KEY (order_id, payment_sequential)
);

-- Tabla: reseñas
CREATE TABLE order_reviews (
  review_id               VARCHAR(50)  PRIMARY KEY,
  order_id                VARCHAR(50)  NOT NULL,
  review_score            TINYINT,
  review_comment_title    TEXT,
  review_comment_message  TEXT,
  review_creation_date    DATETIME,
  review_answer_timestamp DATETIME
);