# Proyecto CineAgile

CineAgile es una cadena peruana de cines que ofrece servicios a nivel nacional. Opera mediante su aplicación web que permite el proceso de venta de entradas y las operaciones internas de la empresa como el control de salas, sedes, funciones, entre otras. Mediante el diagrama buscamos cubrir una alta disponilibidad, escalabilidad, resiliencia y concurrencia.





Diagrama de arquitectura propuesto
<img width="1869" height="1285" alt="IAC agiles - PARTE 2 horizontal" src="https://github.com/user-attachments/assets/3df753b0-a270-4a2d-995a-6dc90ba43002" />

A pesar de su crecimiento a nivel nacional, la plataforma digital de CineAgile sufre de caídas constantes y una severa degradación del rendimiento durante los eventos de mayor demanda, como los estrenos de películas taquilleras (ej. estrenos de Marvel, sagas populares o cintas peruanas muy esperadas) y los fines de semana con promociones especiales.

Este problema se manifiesta en los siguientes puntos críticos que afectan directamente al negocio:

1. Baja disponibilidad y carencia de resiliencia

El sistema es vulnerable a fallos técnicos menores. La caída de un solo servidor de base de datos o un microservicio crítico puede dejar toda la plataforma inoperativa por horas, ya que no existen mecanismos de recuperación automática.

2. Incapacidad para manejar la concurrencia y falta de escalabilidad

Durante el lanzamiento de la preventa de una película popular, miles de usuarios intentan acceder a la aplicación simultáneamente para comprar sus entradas. La arquitectura actual no puede gestionar este volumen de peticiones, lo que provoca que el sistema colapse, la página de compra de entradas no cargue o las transacciones fallen a mitad del proceso. Se pierden miles de ventas en las primeras horas, que son las más críticas. Los clientes frustrados abandonan la compra y acuden a la competencia directa (como Cinemark o Cineplanet), lo que resulta en una pérdida de ingresos directa y un daño irreparable a la imagen de la marca, siendo catalogados en redes sociales como un servicio "caído" o poco fiable. Los periodos picos son durante las fechas de preventa y estreno.

Para ejecutar el despliegue,
1 Ejecutar el comando docker-compose up -d --build desde /jenkins
2 Entrar a la interfaz de jenkins en localhost:8080
3 El usuario y contraseña son admin
4 Ejecutar el pipeline principal
![WhatsApp Image 2025-12-01 at 12 37 41 AM](https://github.com/user-attachments/assets/556f2286-1396-41bb-81cb-260aff870ea2)

