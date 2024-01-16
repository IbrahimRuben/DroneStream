# MQTT DroneStream

## Descripción
Esta aplicación utiliza el protocolo MQTT para recibir en tiempo real contenido multimedia desde un cliente externo, simulado en el archivo _DummyService.py_.

## Instalación

**Paso 1:**

Descarga o clona este repositorio usando el siguiente enlace:
```
https://github.com/IbrahimRuben/dronestream.git
```

**Paso 2:**

Ve a la carpeta raíz del proyecto y ejecuta el siguiente comando en la consola para obtener las dependencias necesarias:

```
flutter pub get
```

**Paso 3:**

Ejecuta la aplicación con el siguiente comando en la consola:

```
flutter run lib/main.dart
```

> [!IMPORTANT]
> Recuerda seleccionar el dispositivo en el que desees ejecutar la aplicación.

> [!CAUTION]
> Esta aplicación está disponible únicamente en Android/iOS.



# Guía de uso

- El primer paso es ejecutar el archivo _DummyService.py_ para iniciar el cliente externo, ya que este enviará las imágenes.
- El segundo paso es conectarnos al broker MQTT con el botón "Conectar".
- Una vez hecho esto, si deseamos que el cliente externo nos envíe contenido, podemos mantener pulsado el botón "Conectar". Esto enviará un mensaje al broker que el _DummyService.py_ interpretará como inicio de la transmisión.
- Si deseamos detener la transmisión, podemos volver a mantener pulsado el botón "Conectar" para que termine de enviar imágenes.
- Si deseamos desconectarnos, simplemente pulsamos "Desconectar".