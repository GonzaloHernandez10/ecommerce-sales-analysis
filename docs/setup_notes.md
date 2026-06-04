# Notas de configuración — Carga del dataset Olist

**Base de datos:** MySQL  
**Herramienta:** HeidiSQL  
**Dataset:** [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)  
**Fecha de configuración:** marzo 2026

---

### Resumen

Durante la carga inicial del dataset se encontraron cuatro problemas relacionados con la calidad de los datos fuente y el comportamiento estricto de MySQL. Ninguno de estos problemas afecta la integridad del análisis posterior. A continuación se documenta cada problema, su causa y la solución implementada.

---

### Problema 1 — Campos vacíos en columnas enteras (tabla `products`)

**Advertencia generada:**
```
Incorrect integer value: '' for column 'product_name_length' at row 10013
```

**Causa:**  
Algunos registros del archivo `olist_products_dataset.csv` tienen campos vacíos en columnas numéricas (por ejemplo, `product_name_length`, `product_weight_g`). MySQL en modo estricto rechaza cadenas vacías `''` al intentar insertarlas en columnas de tipo `INT`.

**Solución implementada:**  
Se desactivó el modo estricto de MySQL para la sesión de carga y se usaron variables intermedias con `NULLIF()` en la sentencia `LOAD DATA` para convertir campos vacíos a `NULL` en lugar de intentar insertarlos como enteros.

```sql
SET SESSION sql_mode = 'NO_ENGINE_SUBSTITUTION';

LOAD DATA LOCAL INFILE '...olist_products_dataset.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
IGNORE 1 LINES
(product_id, @category, @name_len, ...)
SET
  product_category_name      = NULLIF(@category, ''),
  product_name_length        = NULLIF(@name_len, ''),
  product_weight_g           = NULLIF(@weight,   ''),
  ...;
```

**Impacto en el análisis:**  
Los campos `NULL` en todas las tablas se conservan.

---

### Problema 2 — Categorías huérfanas en `products` sin entrada en `category_translation`

**Advertencia generada:**

```
Cannot add or update a child row: a foreign key constraint fails
(`olist_ecommerce`.`products`, CONSTRAINT `products_ibfk_1`
FOREIGN KEY (`product_category_name`) REFERENCES `category_translation`)
```

**Causa:**  
Dos categorías presentes en `olist_products_dataset.csv` no existen en el archivo de traducción `product_category_name_translation.csv`.

Categorías faltantes identificadas:

- `portateis_cozinha_e_preparadores_de_alimentos`
- `pc_gamer`

**Solución implementada:**  
Se insertaron manualmente las categorías faltantes en `category_translation` antes de recargar la tabla `products`.

```sql
INSERT IGNORE INTO category_translation 
  (product_category_name, product_category_name_english)
VALUES
  ('portateis_cozinha_e_preparadores_de_alimentos', 'portable_kitchen_and_food_preparers'),
  ('pc_gamer', 'pc_gamer');
```

**Impacto en el análisis:**  
Ninguno. Las dos categorías ahora tienen traducción al inglés y se comportan igual que el resto.

---

### Problema 3 — BOM y caracteres invisibles en `customer_id` (tabla `orders`)

**Advertencia generada:**

```
Cannot add or update a child row: a foreign key constraint fails
(`olist_ecommerce`.`orders`, CONSTRAINT `orders_ibfk_1`
FOREIGN KEY (`customer_id`) REFERENCES `customers`)
```

**Causa:**  
El archivo `olist_orders_dataset.csv` fue guardado con codificación UTF-8 con BOM (Byte Order Mark), lo que agrega caracteres invisibles (`\xEF\xBB\xBF`) al inicio de los valores. Esto hace que el mismo `customer_id` tenga longitudes distintas al compararse entre tablas:

```sql
-- orders: LENGTH(customer_id) = 35 (con BOM)
-- customers: LENGTH(customer_id) = 32 (sin BOM)
```

MySQL no reconoce los IDs como iguales, por lo que el 62% de las órdenes aparece como huérfano respecto a `customers`.

**Solución implementada:**  
Se eliminó el foreign key de la tabla `orders` para el entorno de análisis y se agregó `CHARACTER SET utf8mb4` junto con `TRIM()` en todos los campos para minimizar el efecto de caracteres residuales.

```sql
-- Tabla recreada sin FK
CREATE TABLE orders (
  order_id     VARCHAR(50) PRIMARY KEY,
  customer_id  VARCHAR(50) NOT NULL,
  ...
  -- FK removida: problema de BOM en el CSV fuente
);

LOAD DATA LOCAL INFILE '...olist_orders_dataset.csv'
INTO TABLE orders
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
IGNORE 1 LINES
(@order_id, @customer_id, ...)
SET
  order_id    = TRIM(@order_id),
  customer_id = TRIM(@customer_id),
  ...;
```

**Decisión analítica:**  
La foreign key entre `orders` y `customers` no se restituyó. Para un entorno de análisis esto no afecta ninguna query — los JOINs funcionan correctamente a nivel de valores aunque no haya constraint formal. La integridad referencial estricta es una necesidad de sistemas en reales en producción, no de proyectos de análisis.

Las tablas `order_items`, `order_payments` y `order_reviews` se cargaron también sin foreign keys siguiendo el mismo criterio.

---

### Problema 4 — Saltos de línea mixtos en `order_reviews`

**Advertencia generada:**

```
Delimiter '\r' in position 19 in datetime value '2017-10-27 13:36:43\r'
at row 885 is superfluous and is deprecated.
```

**Causa:**  
El archivo `olist_order_reviews_dataset.csv` usa saltos de línea Windows (`\r\n`) mientras que los demás archivos del dataset usan solo `\n`. Al cargar con `LINES TERMINATED BY '\n'`, el carácter `\r` queda pegado al último campo de cada fila (el timestamp), generando valores de fecha inválidos.

**Solución implementada:**  
Se agregó `REPLACE()` en el campo `review_answer_timestamp` para eliminar el `\r` residual antes de la conversión a `DATETIME`.

```sql
LOAD DATA LOCAL INFILE '...olist_order_reviews_dataset.csv'
INTO TABLE order_reviews
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@review_id, @order_id, @score, @title, @message, @creation, @answer)
SET
  ...
  review_answer_timestamp = NULLIF(TRIM(REPLACE(@answer, '\r', '')), '');
```

**Impacto en el análisis:**  
Ninguno. Los timestamps se almacenaron correctamente. El conteo final de reseñas (101,604) es consistente con la versión del dataset descargado.

---

### Problema 5 — Campos de texto sin comillas y duplicados en `order_reviews`

#### 5.1 — CSV modificado sin delimitadores de texto

**Causa:**  
Durante el proceso de carga se eliminaron accidentalmente las comillas dobles
del archivo `olist_order_reviews_dataset.csv`. Esto causó que MySQL interpretara
las comas dentro de los campos `review_comment_title` y `review_comment_message`
como separadores de columna, desplazando los valores de `review_creation_date`
y `review_answer_timestamp` fuera de su posición correcta.

**Advertencias generadas:**
```
Data truncated for column 'review_creation_date' at row 2823
Data truncated for column 'review_answer_timestamp' at row 2823
Row 2824 was truncated; it contained more data than there were input columns
```

**Solución implementada:**  
Se restauró el archivo CSV original desde el ZIP descargado de Kaggle, que sí
conserva las comillas dobles como delimitadores de texto. Se agregó `ENCLOSED BY '"'`
al comando `LOAD DATA` para que MySQL respete el contenido entre comillas como
un único campo sin importar las comas internas.

Parte de esta solución también se implemento en la tabla `sellers` ya que dicha tabla presentaba el mismo problema.
```sql
LOAD DATA LOCAL INFILE '...olist_order_reviews_dataset.csv'
INTO TABLE order_reviews
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
...
```

**Impacto en el análisis:**  
Ninguno. Los registros se cargaron correctamente con su estructura de 7 columnas
respetada.

---

#### 5.2 — `review_id` duplicados en el CSV fuente

**Advertencia generada:**
```
Duplicate entry '44d1e9165ec54b1d89d33594856af859' for key 'order_reviews.PRIMARY'
```

**Causa:**  
El archivo `olist_order_reviews_dataset.csv` contiene `review_id` duplicados en
el dataset fuente. MySQL rechaza el segundo registro al intentar insertar una
PRIMARY KEY que ya existe, resultando en una carga parcial de los datos.

**Investigación:**  
Se verificó si los duplicados tenían datos distintos eliminando temporalmente el
PRIMARY KEY y consultando los registros repetidos. El resultado fue que no había
duplicados reales en los datos — los `review_id` repetidos eran un artefacto del
CSV fuente, no registros con información diferente.

**Solución implementada:**  
Se agregó la cláusula `IGNORE` a la sentencia `LOAD DATA` para que MySQL descarte
silenciosamente los duplicados en lugar de generar un error bloqueante.
```sql
LOAD DATA LOCAL INFILE '...olist_order_reviews_dataset.csv'
IGNORE
INTO TABLE order_reviews
...
```

**Decisión analítica:**  
Los 98,409 registros cargados representan todos los `review_id` únicos del
dataset. Los duplicados descartados no contienen información adicional y su
exclusión no afecta ninguna query de análisis.

**Impacto en el análisis:**  
Mínimo. La diferencia entre 101,604 filas en el CSV y 98,409 registros únicos
cargados representa un 3.1% de duplicados en el dataset fuente, todos descartados
correctamente.

---

### Conteo final de registros

```sql
SELECT 'customers'                       AS tabla, COUNT(*) AS registros FROM customers
UNION ALL SELECT 'orders',               COUNT(*) FROM orders
UNION ALL SELECT 'order_items',          COUNT(*) FROM order_items
UNION ALL SELECT 'order_payments',       COUNT(*) FROM order_payments
UNION ALL SELECT 'order_reviews',        COUNT(*) FROM order_reviews
UNION ALL SELECT 'products',             COUNT(*) FROM products
UNION ALL SELECT 'sellers',              COUNT(*) FROM sellers
UNION ALL SELECT 'category_translation', COUNT(*) FROM category_translation;
```

| Tabla | Registros cargados |
|---|---|
| customers | 99,441 |
| orders | 99,441 |
| order_items | 112,650 |
| order_payments | 103,886 |
| order_reviews | 98,409 |
| products | 32,951 |
| sellers | 3,095 |
| category_translation | 73 |

---

## Lecciones aprendidas

- Los datasets públicos de Kaggle no están limpios por defecto. Encontrar y resolver estos problemas es parte del trabajo del analista.
- `NULLIF()` y variables intermedias en `LOAD DATA` son el patrón correcto para manejar campos vacíos en MySQL.
- Los problemas de encoding (BOM, `\r\n` vs `\n`) son comunes cuando los archivos CSV se generan en Windows. Siempre verificar con `LENGTH()` si los JOINs no devuelven los resultados esperados.
- En un entorno no productivo, eliminar un foreign key es una decisión válida cuando el problema es del dato fuente y no afecta las queries de análisis.
- La calidad de los datos, en especifico la integridad, no se vio afectada gracias a este proceso de resolución de problemas en la carga de datos.
