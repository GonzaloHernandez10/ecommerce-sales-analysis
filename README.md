# Análisis de E-Commerce — Olist Brasil

### Descripción general

Este proyecto forma parte de un portafolio de análisis de datos orientado a demostrar
competencias en extracción, transformación, análisis y comunicación de datos utilizando
SQL y Excel. El análisis se realiza sobre el dataset público de Olist, una plataforma
brasileña de e-commerce que conecta pequeños comerciantes con los principales marketplaces
del país.

El objetivo no es solo demostrar dominio técnico de las herramientas, sino responder
una pregunta de negocio concreta a través de un análisis estructurado con narrativa clara.

---

### Pregunta de negocio

> **¿Olist está creciendo bien o está creciendo mal?**

Las ventas de Olist crecieron en volumen entre 2016 y 2018, pero simultáneamente
aumentaron las quejas de clientes. Este análisis busca determinar si el crecimiento
en volumen está comprometiendo la calidad del servicio, identificar dónde se concentran
los problemas y proponer en qué áreas enfocar la atención.

---

### Dataset

**Fuente:** [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)  
**Periodo cubierto:** 2016 – 2018  
**Tablas:** 8  
**Registros totales:** ~530,000  

| Tabla | Registros | Descripción |
|---|---|---|
| customers | 99,441 | Clientes únicos con ubicación geográfica |
| orders | 99,441 | Órdenes con estado y fechas del ciclo de entrega |
| order_items | 112,650 | Productos incluidos en cada orden |
| order_payments | 103,886 | Métodos y valores de pago por orden |
| order_reviews | 98,409 | Calificaciones y comentarios de clientes |
| products | 32,951 | Catálogo de productos con categoría y dimensiones |
| sellers | 3,095 | Vendedores con ubicación geográfica |
| category_translation | 71 | Traducción de categorías del portugués al inglés |

---

### Herramientas

| Herramienta | Uso |
|---|---|
| MySQL | Almacenamiento, limpieza y extracción de datos mediante SQL |
| HeidiSQL | Cliente de base de datos para ejecución de queries |
| Excel | Análisis estadístico descriptivo y visualizaciones |

---

### Estructura del repositorio

```
ecommerce-sales-analysis/
├── README.md
├── docs/
│   └── setup_notes.md        # Problemas encontrados durante la carga y soluciones implementadas
├── sql/
│   └── queries.sql           # Todas las consultas documentadas con su pregunta de negocio
├── data/
│   └── output.csv            # Dataset consolidado exportado desde SQL
└── excel/
    └── dashboard.xlsx        # Análisis estadístico y visualizaciones
```

---

### Narrativa del análisis

El análisis se desarrolla en tres actos que responden preguntas encadenadas:

**Acto 1 — ¿Cómo están las ventas?**  
Establecer la línea base del negocio: volumen de órdenes, ingresos por periodo
y categorías principales. Este acto describe el negocio con datos antes de emitir
cualquier juicio sobre él.

**Acto 2 — ¿Dónde está el problema?**  
Cruzar ventas con calificaciones de clientes y tiempos de entrega para identificar
si el problema es el producto, el precio o la logística.

**Acto 3 — ¿Dónde enfocar la solución?**  
Segmentar el problema geográficamente para identificar dónde se concentra la
fricción y qué acciones tendrían mayor impacto.

---

### Preguntas que guían el análisis

| # | Pregunta | Acto |
|---|---|---|
| 1 | ¿Cuál es el ingreso total y número de órdenes por mes? | 1 |
| 2 | ¿Cuáles son las 10 categorías con más ingresos? | 1 |
| 3 | ¿Cuál es el ticket promedio por categoría? | 1 |
| 4 | ¿Cómo se distribuyen las calificaciones de clientes? | 2 |
| 5 | ¿Qué categorías tienen peor calificación promedio? | 2 |
| 6 | ¿Cuántos días tarda en promedio cada categoría en entregarse? | 2 |
| 7 | ¿Hay correlación entre tiempo de entrega y calificación? | 2 |
| 8 | ¿Qué estados concentran los peores tiempos de entrega? | 3 |
| 9 | ¿Cuál es la tasa de órdenes entregadas vs canceladas? | 3 |
| 10 | ¿Qué vendedores tienen más volumen pero peor calificación? | 3 |

---

### Estado del proyecto

- [x] Configuración de la base de datos en MySQL
- [x] Carga y validación de los 8 archivos del dataset
- [ ] Análisis exploratorio con SQL — extracción y transformación
- [ ] Análisis estadístico y visualizaciones en Excel
- [ ] Comunicación de hallazgos

---

### Hallazgos principales

*Esta sección se completará al finalizar el análisis.*

---

### Conclusiones y recomendaciones

*Esta sección se completará al finalizar el análisis.*

---

### Sobre el autor

Analista de datos en formación con background en desarrollo de aplicaciones web.
Este proyecto forma parte de un portafolio orientado a demostrar competencias
en el ciclo completo de análisis de datos: extracción, limpieza, análisis y
comunicación de resultados.

📧 *tu correo*  
💼 *tu LinkedIn*  
🐙 *tu GitHub*
