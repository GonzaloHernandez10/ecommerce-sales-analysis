# Proyecto E-Commerce Olist en Python

import pandas as pd
# pyrefly: ignore [missing-import]
import plotly.graph_objects as go
# pyrefly: ignore [missing-import]
from plotly.subplots import make_subplots

# --------------------------------------------------------------------------------------------------------------------------------------
# 01 VENTAS MENSUALES
# --------------------------------------------------------------------------------------------------------------------------------------
def graficar_ventas_mensuales():
    df_ventas_mensuales = pd.read_csv('./datos/ventas_mensuales.csv')
    #print(df_ventas_mensuales.head())
    
    # Convertir la columna 'mes' a tipo datetime para un mejor manejo de fechas
    df_ventas_mensuales['mes'] = pd.to_datetime(df_ventas_mensuales['mes'])
    df_ventas_mensuales = df_ventas_mensuales[
        (df_ventas_mensuales['mes'] >= '2017-01') & (df_ventas_mensuales['mes'] <= '2018-08')
    ]

    # Definición del lienzo indicando que el eje Y secundario está activo
    fig_ventas_mensuales = make_subplots(specs=[[{"secondary_y": True}]])

    # Añadir el primer trace:  ingresos en el eje primario (Y izquierda)
    fig_ventas_mensuales.add_trace(
        go.Scatter(
            x=df_ventas_mensuales['mes'], 
            y=df_ventas_mensuales['total_ingresos'], 
            name='Ingresos (BRL)', 
            mode='lines+markers', 
            hovertemplate="<b>Período</b>: %{x|%b %Y}<br>"+"<b>Total</b>: $ %{y:,.2f} BRL<extra></extra>"
        ),
        secondary_y=False, # indica que esta traza se dibujará en el eje primario
    )

    # Añadir el segundo trace: ordenes en el eje secundario (Y derecha)
    fig_ventas_mensuales.add_trace(
        go.Scatter(
            x=df_ventas_mensuales['mes'],
            y=df_ventas_mensuales['total_ordenes'],
            name='Órdenes',
            mode='lines+markers', 
            line=dict(dash='dash'), # indica que esta línea será segmentada
            hovertemplate="<b>Período</b>: %{x|%b %Y}<br> "+"<b>Total</b>: %{y:,.0f} órdenes<extra></extra>"
        ),
        secondary_y=True, # indica que esta traza se dibujará en el eje secundario
    )

    # Configurar el diseño estetico general y los elementos visuales que no forman parte de los datos en sí
    fig_ventas_mensuales.update_layout(
        title='Ventas Mensuales (2016-2018)',
    )

    # (RECOMENDADO) Añadir título al eje x
    fig_ventas_mensuales.update_xaxes(
        title_text="<b>Mes</b>",
    )

    # (RECOMENDADO) Añadir títulos a los ejes Y
    fig_ventas_mensuales.update_yaxes(
        title_text="<b>Ingresos (BRL)</b>", 
        secondary_y=False # indica que esta traza se dibujará en el eje primario
    )
    fig_ventas_mensuales.update_yaxes(
        title_text="<b>Ordenes</b>", 
        secondary_y=True # indica que esta traza se dibujará en el eje secundario
    )

    # Mostrar el gráfico
    fig_ventas_mensuales.show()

    # Guardar el gráfico
    fig_ventas_mensuales.write_image("./visualizaciones/01_ventas_mensuales.png") # como imagen para el README
    fig_ventas_mensuales.write_html("./visualizaciones/01_ventas_mensuales.html") # como html interactivo para el portafolio
# --------------------------------------------------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------------------------------------------------
# 02 DISTRIBUCION DE CALIFICACIONES   
# --------------------------------------------------------------------------------------------------------------------------------------
def graficar_distribucion_calificaciones():
    df_distribucion_calificaciones = pd.read_csv('./datos/distribucion_calificaciones.csv')
    #print(df_distribucion_calificaciones.head())

    # Definición del lienzo: gráfico de dona
    fig_distribucion_calificaciones = go.Figure(
        data=[
            go.Pie(
                labels=df_distribucion_calificaciones['review_score'], 
                values=df_distribucion_calificaciones['distribucion'],
                hole=0.6, # este parametro entre 0 y 1 permite cambiar el grosor de la dona
                marker=dict(
                    colors=['#4CAF50', '#2196F3', '#9E9E9E', '#FF9800', '#F44336']
                ),
                hovertemplate="<b>Calificación</b>: %{label}<br>"+"<b>Distribución</b>: %{value}<extra></extra>"
            )
        ]
    )

    # Se calcula el total de reseñas para añadirlo a la leyenda
    total_reviews = df_distribucion_calificaciones['distribucion'].sum()

    # Añadir la etiqueta del total de reseñas al centro de la dona
    fig_distribucion_calificaciones.add_annotation(
        text=f"Total: {total_reviews} reseñas",
        x=0.5,
        y=0.5,
        showarrow=False,
        font=dict(
            size=16,
            color="#000000"
        )
    )
    
    # Modificación del diseño estetico general
    fig_distribucion_calificaciones.update_layout(
        title='Distribución de Calificaciones',
    )

    # Mostrar el gráfico
    fig_distribucion_calificaciones.show()

    # Guardar el gráfico
    fig_distribucion_calificaciones.write_image("./visualizaciones/02_distribucion_calificaciones.png") # como imagen para el README
    fig_distribucion_calificaciones.write_html("./visualizaciones/02_distribucion_calificaciones.html") # como html interactivo para el portafolio
# --------------------------------------------------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------------------------------------------------
# 03 CALIFICACION POR TIEMPO DE ENTREGA
# --------------------------------------------------------------------------------------------------------------------------------------
def graficar_calificacion_por_tiempo_entrega():
    df_calificacion_promedio_por_tiempo_entrega = pd.read_csv('./datos/calificacion_por_tiempo_entrega.csv')
    #print(df_calificacion_promedio_por_tiempo_entrega.head())

    # Definición del lienzo: gráfico de barras
    fig_calificacion_promedio_por_tiempo_entrega = go.Figure(
        data=[
            go.Bar(
                x=df_calificacion_promedio_por_tiempo_entrega['tiempo_entrega'],
                y=df_calificacion_promedio_por_tiempo_entrega['calificacion_promedio'],
                marker_color=['#2196F3', '#F44336'],
                text=df_calificacion_promedio_por_tiempo_entrega['calificacion_promedio'],
                textposition='auto',
                hovertemplate="<b>Tiempo de Entrega</b>: %{x}<br>"+"<b>Calificación Promedio</b>: %{y}<extra></extra>"
            )
        ]
    )

    # Modificación del diseño estetico general
    fig_calificacion_promedio_por_tiempo_entrega.update_layout(
        title='Calificación por Tiempo de Entrega',
        template='plotly_white',
    )

    fig_calificacion_promedio_por_tiempo_entrega.update_xaxes(
        title_text="<b>Tiempo de Entrega</b>"
    )

    fig_calificacion_promedio_por_tiempo_entrega.update_yaxes(
        title_text="<b>Calificación Promedio</b>"
    )

    # Mostrar el gráfico
    fig_calificacion_promedio_por_tiempo_entrega.show()

    # Guardar el gráfico
    fig_calificacion_promedio_por_tiempo_entrega.write_image("./visualizaciones/03_calificacion_por_tiempo_entrega.png") # como imagen para el README
    fig_calificacion_promedio_por_tiempo_entrega.write_html("./visualizaciones/03_calificacion_por_tiempo_entrega.html") # como html interactivo para el portafolio
# --------------------------------------------------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------------------------------------------------
# 04 TIEMPO DE ENTREGA POR ESTADO
# --------------------------------------------------------------------------------------------------------------------------------------
def graficar_tiempo_de_entrega_por_estado():
    df_tiempo_entrega_estado = pd.read_csv('./datos/tiempo_entrega_por_estado.csv')
    #print(df_tiempo_entrega_estado.head())

    # Ordenar los datos por 'dias_entrega_promedio_estado' y seleccionar los top 10
    df_tiempo_entrega_estado = df_tiempo_entrega_estado.sort_values(
        by='dias_entrega_promedio_estado', 
        ascending=False
    ).head(10)

    # Definición del lienzo: gráfico de barras horizontales
    fig_tiempo_entrega_estado = go.Figure(
        data=[
            go.Bar(
                x=df_tiempo_entrega_estado['dias_entrega_promedio_estado'],
                y=df_tiempo_entrega_estado['customer_state'],
                marker_color='#2196F3',
                text=df_tiempo_entrega_estado['dias_entrega_promedio_estado'],
                texttemplate='%{text:.2f}', # formatea el texto a mostrar en las barras (actua sobre las etiquetas estaticas de las barras)
                textposition='auto', # se posiciona el texto automaticamente
                orientation='h', # indica que el gráfico es horizontal
                hovertemplate='<b>Estado:</b> %{y}<br><b>Tiempo de Entrega:</b> %{x:.2f} días<extra></extra>' # etiqueta personalizada que aparece al pasar el mouse sobre una barra (actua sobre el tooltip)
            )
        ]
    )
    
    # Modificación del diseño estetico general
    fig_tiempo_entrega_estado.update_layout(
        title='Tiempo de Entrega por Estado',
        template='plotly_white',
        yaxis={
            'categoryorder':'total ascending' # ordena los datos de menor a mayor tiempo de entrega
        }
    )

    fig_tiempo_entrega_estado.update_xaxes(
        title_text='<b>Tiempo de Entrega (días)</b>',
    )

    fig_tiempo_entrega_estado.update_yaxes(
        title_text='<b>Estado</b>'
    )

    # Mostrar el gráfico
    fig_tiempo_entrega_estado.show()

    # Guardar el gráfico
    fig_tiempo_entrega_estado.write_image("./visualizaciones/04_tiempo_de_entrega_por_estado.png") # como imagen para el README
    fig_tiempo_entrega_estado.write_html("./visualizaciones/04_tiempo_de_entrega_por_estado.html") # como html interactivo para el portafolio
# --------------------------------------------------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------------------------------------------------
# 05 VENDEDORES CRITICOS
# --------------------------------------------------------------------------------------------------------------------------------------
def graficar_vendedores_criticos():
    df_vendedores_criticos = pd.read_csv('./datos/vendedores_criticos.csv')
    #print(df_vendedores_criticos.head())

    # Definición del lienzo: gráfico de dispersión
    fig_vendedores_criticos = go.Figure(
        data=[
            go.Scatter(
                x=df_vendedores_criticos['total_ordenes'],
                y=df_vendedores_criticos['calificacion_promedio'],
                mode='markers',
                marker=dict(
                    size=12,
                    color='rgb(102,194,165)',
                    opacity=0.8,
                    line=dict(
                        width=2,
                        color='DarkSlateGrey',
                    ),
                ),
                text=df_vendedores_criticos['seller_id'],
                textposition='top center',
                hovertemplate='<b>Vendedor:</b> %{text}<br><b>Total de Ordenes:</b> %{x}<br><b>Calificación Promedio:</b> %{y}<extra></extra>'
            )
        ]
    )

    # Modificación del diseño estetico general
    fig_vendedores_criticos.update_layout(
        title='Vendedores Críticos',
        template='plotly_white',
    )

    fig_vendedores_criticos.update_xaxes(
        title_text='<b>Total de Ordenes</b>'
    )

    fig_vendedores_criticos.update_yaxes(
        title_text='<b>Calificación Promedio</b>'
    )

    # Agregar línea horizontal para indicar el límite de alerta (3.8 estrellas)
    fig_vendedores_criticos.add_hline(y=3.8, line_dash="dash", line_color="red", annotation_text="Límite (3.8)")

    # Mostrar el gráfico
    fig_vendedores_criticos.show()

    # Guardar el gráfico
    fig_vendedores_criticos.write_image("./visualizaciones/05_vendedores_criticos.png") # como imagen para el README
    fig_vendedores_criticos.write_html("./visualizaciones/05_vendedores_criticos.html") # como html interactivo para el portafolio
# --------------------------------------------------------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------------------------------------------------------
# GENERAR LOS GRÁFICOS
# --------------------------------------------------------------------------------------------------------------------------------------
# graficar_ventas_mensuales()
# graficar_distribucion_calificaciones()
# graficar_calificacion_por_tiempo_entrega()
graficar_tiempo_de_entrega_por_estado()
# graficar_vendedores_criticos()
