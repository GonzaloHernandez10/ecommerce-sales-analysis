# Hallazgos del Análisis - Olist E-commerce

Este documento contiene los hallazgos y las decisiones analíticas que tomé durante cada uno de los actos del proyecto.

---

## Acto 1: ¿Cómo están las ventas?

### ¿Cuál es el ingreso total y número de órdenes por mes?
* **Hallazgo:** Los datos de 2016 muestran volúmenes muy bajos y falta el mes de noviembre. El crecimiento en 2017 y 2018 es continuo, destacando noviembre de 2017 (Black Friday) con 8,552 órdenes y 1.16 millones de BRL en ingresos. Al final del periodo (septiembre-octubre de 2018), los datos caen de golpe a cero. Hay bajas estacionales predecibles en diciembre, febrero y a mitad de año.
* **Decisión analítica:** Decidí excluir el año 2016 y los meses finales de 2018 (septiembre y octubre) del análisis de tendencias en los gráficos. 2016 representa una fase piloto del negocio y los meses finales de 2018 están incompletos en el dataset. Incluirlos daría una falsa impresión de caída o estancamiento del negocio.

### ¿Cuáles son las 10 categorías con más ingresos?
* **Hallazgo:** El volumen de órdenes no siempre equivale a más ingresos. La categoría más vendida (`bed_bath_table` con 9,378 órdenes) generó 1.23 millones de BRL, mientras que `watches_gifts` generó más ingresos (1.28 millones de BRL) con casi la mitad de órdenes (5,565) debido a su alto valor unitario. Además, solo 5 categorías concentran el 31% del ingreso total de la empresa.
* **Recomendación:** Sugiero al equipo comercial enfocar la captación de nuevos vendedores en las 5 categorías líderes (belleza, hogar, relojes, accesorios de computación, etc.) para diversificar la oferta en donde la plataforma ya es más rentable.

### ¿Cuál es el ticket promedio por categoría?
* **Hallazgo:** La categoría con el ticket promedio más alto es `computers` (1,283.98 BRL). Al cruzar esto con el volumen, note que las computadoras se compran poco pero caro, y los accesorios (`computers_accessories`) se compran de forma masiva y económica. Ninguna de las categorías de ticket promedio alto figura en el top de volumen, ya que corresponden a compras planificadas o industriales.
* **Recomendación:** Recomiendo dividir el catálogo en dos estrategias de marketing diferentes: compras rápidas o por impulso (productos de bajo ticket y alta frecuencia) y compras planificadas (productos de alto ticket, que requieren mayor tiempo de decisión).

---

## Acto 2: ¿Dónde está el problema? 

### ¿Cómo se distribuyen las calificaciones de clientes?
* **Hallazgo:** El 79% de las calificaciones son positivas (4 y 5 estrellas), el 8.4% son neutras (3 estrellas) y el 12.6% son insatisfechas (1 y 2 estrellas).
* **Decisión analítica:** Tener más del 10% de calificaciones negativas es un foco rojo en e-commerce. Como en el análisis previo descartamos errores en cobros o precios, mi hipótesis principal es que la insatisfacción se debe a fallas en la entrega.

### ¿Qué categorías tienen peor calificación promedio?
* **Hallazgo:** Con un filtro de mínimo 50 órdenes para asegurar representatividad, la categoría peor evaluada de Olist es `office_furniture` (muebles de oficina) con un promedio de 3.5 estrellas. El resto del top 10 de peores categorías promedia menos de 4 estrellas y la mayoría son artículos pesados o voluminosos.
* **Decisión analítica:** Este patrón sugiere un problema con el manejo de productos grandes. Apoya la hipótesis logística: los muebles tienen más probabilidades de sufrir daños durante el transporte o tardar más en entregarse.

### ¿Cuántos días tarda en promedio cada categoría en entregarse?
* **Hallazgo:** `office_furniture` (muebles de oficina) tiene el peor tiempo de entrega de la plataforma, promediando casi 21 días (20.78 días). Categorías de muebles similares también están entre las más lentas para llegar al cliente.
* **Decisión analítica:** Los datos confirman la hipótesis: la mala calificación de los muebles está directamente ligada a la lentitud en la entrega.

### ¿Hay correlación entre tiempo de entrega y calificación?
* **Hallazgo:** Cuando un pedido llega a tiempo o antes de lo prometido, la calificación promedio es de 4.22 estrellas. Cuando el pedido se retrasa, la calificación se desploma a 2.33 estrellas.
* **Recomendación:** El cliente castiga severamente la promesa rota. Para reducir las quejas del 12.6%, la prioridad número uno debe ser mejorar el cumplimiento de las fechas estimadas.

---

## Acto 3: ¿Dónde enfocar la solución?

### ¿Qué estados concentran la tasa de órdenes e ingresos más alta?
* **Hallazgo:** Sao Paulo (SP) domina ampliamente el mercado con 40,501 órdenes y 5.76 millones de BRL en ingresos. Río de Janeiro (RJ) le sigue con ~2 millones de BRL y Minas Gerais (MG) con ~1.8 millones de BRL.
* **Decisión analítica:** Sao Paulo representa casi la mitad del negocio. Cualquier problema operativo aquí puede comprometer a toda la empresa, por lo que las estrategias de mejora deben priorizar este estado.

### ¿Qué estados concentran los peores tiempos de entrega?
* **Hallazgo:** Los peores tiempos de entrega están en el norte del país, liderados por Amapá (28.2 días), Roraima (28.1 días) y Amazonas (26.3 días). En contraste, en Sao Paulo los envíos promedian 8.6 días.
* **Recomendación:** El problema de entregas tardías está regionalizado y no afecta al motor del negocio (Sao Paulo). En lugar de reestructurar la logística nacional, la solución más rápida es corregir las fechas de entrega estimadas que se muestran a los clientes del norte en la web, evitando falsas expectativas.

### ¿Cuál es la tasa de órdenes entregadas vs canceladas?
* **Hallazgo:** El 99.36% de las órdenes (96,478) se entregó con éxito y solo el 0.64% (625) terminó en cancelación.
* **Decisión analítica:** La plataforma es operativamente muy sólida cobrando y procesando compras. Esto confirma que el problema de insatisfacción del cliente ocurre después de la compra (durante el traslado) y no en la fiabilidad del sitio web.

### ¿Qué vendedores tienen más volumen pero peor calificación?
* **Hallazgo:** Filtrando vendedores con más de 100 órdenes, encontramos casos muy contrastantes. El vendedor `7c67e1448b00f6e969d365cea6b010ab` tiene un volumen de 980 órdenes pero una calificación promedio crítica de ~3.0. Por otro lado, el vendedor `3b15288545f8928d3e65a8f949a28291` mantiene una calificación casi perfecta con más de 100 ventas.
* **Recomendación:** Los vendedores grandes con bajas calificaciones dañan la imagen del marketplace. Sugiero implementar alertas automáticas: si un vendedor supera las 100 ventas pero su promedio baja de 3.8 estrellas, se le debe auditar o reducir su visibilidad para proteger la reputación de Olist.
