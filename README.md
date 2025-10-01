# Proyecto CineAgile

CineAgile es una cadena peruana de cines que ofrece servicios a nivel nacional. Opera mediante su aplicación web que permite el proceso de venta de entradas y las operaciones internas de la empresa como el control de salas, sedes, funciones, entre otras. Mediante el diagrama buscamos cubrir una alta disponilibidad, escalabilidad, resiliencia y concurrencia.

<img width="1852" height="1296" alt="iac borrador - Page 2" src="https://github.com/user-attachments/assets/6aa2a969-eaad-4f74-a2d8-a7743ec211ea" />

Diagrama de arquitectura propuesto


A pesar de su crecimiento a nivel nacional, la plataforma digital de CineAgile sufre de caídas constantes y una severa degradación del rendimiento durante los eventos de mayor demanda, como los estrenos de películas taquilleras (ej. estrenos de Marvel, sagas populares o cintas peruanas muy esperadas) y los fines de semana con promociones especiales.

Este problema se manifiesta en los siguientes puntos críticos que afectan directamente al negocio:

1. Baja disponibilidad y carencia de resiliencia

El sistema es vulnerable a fallos técnicos menores. La caída de un solo servidor de base de datos o un microservicio crítico puede dejar toda la plataforma inoperativa por horas, ya que no existen mecanismos de recuperación automática.

2. Incapacidad para manejar la concurrencia y falta de escalabilidad

Durante el lanzamiento de la preventa de una película popular, miles de usuarios intentan acceder a la aplicación simultáneamente para comprar sus entradas. La arquitectura actual no puede gestionar este volumen de peticiones, lo que provoca que el sistema colapse, la página de compra de entradas no cargue o las transacciones fallen a mitad del proceso. Se pierden miles de ventas en las primeras horas, que son las más críticas. Los clientes frustrados abandonan la compra y acuden a la competencia directa (como Cinemark o Cineplanet), lo que resulta en una pérdida de ingresos directa y un daño irreparable a la imagen de la marca, siendo catalogados en redes sociales como un servicio "caído" o poco fiable. Los periodos picos son durante las fechas de preventa y estreno.

El proyecto se puede desplegar mediante
terraform init
terraform plan
terraform apply

Para la integración continúa de pueden ejecutar los jenkisfiles configurando las credenciales de usuario de aws, el repo de elastic container registry y la region de aws.
