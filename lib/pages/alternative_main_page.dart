// Importaciones necesarias para el funcionamiento del código
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:dronestream/services/mqtt_client.dart';
import 'package:dronestream/utils/my_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Clase principal para la página principal
class AlternativeMainPage extends StatefulWidget {
  const AlternativeMainPage({super.key});

  @override
  State<AlternativeMainPage> createState() => _AlternativeMainPageState();
}

// Estado asociado a la página principal
class _AlternativeMainPageState extends State<AlternativeMainPage> {
  // Declaración de variables necesarias
  late TextEditingController textController;
  late Size size;
  int sendornot = 0; // Variable para controlar el envío de mensajes

  @override
  void initState() {
    super.initState();
    textController = TextEditingController();
  }

  @override
  void dispose() {
    textController.dispose(); // Liberación de recursos al cerrar la página
    super.dispose();
  }

  // Función para decodificar y mostrar una imagen a partir de un frame en formato base64
  Uint8List decodeAndShow(String frame) {
    Uint8List image = base64Decode(frame);
    return image;
  }

  @override
  Widget build(BuildContext context) {
    // Obtener la instancia del proveedor MQTTClientWrapper usando Provider
    MQTTClientWrapper mqttProvider =
        Provider.of<MQTTClientWrapper>(context, listen: true);
    size = MediaQuery.sizeOf(context); // Obtener el tamaño de la pantalla

    // Estructura del widget de la página
    return Scaffold(
      backgroundColor:
          Colors.grey[200], //Cambiamos el color del fondo de la aplicación
      appBar: AppBar(
        title: const Text(
          "MQTT DroneStream",
          style: TextStyle(color: Colors.black),
        ),
        elevation: 0,
        backgroundColor: Colors.grey[300],
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Image.asset('assets/icon/drone_icon_nobg.png'),
        ),
        actions: [
          // Indicador de estado de conexión MQTT
          SizedBox(
            width: 90,
            child: FittedBox(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: mqttProvider.mqttIsConnected
                            ? Colors.green
                            : Colors.red,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        mqttProvider
                                .mqttIsConnected //Cambia según el estado de conexión
                            ? 'Conectado'
                            : 'Desconectado',
                        style: TextStyle(
                            color: mqttProvider.mqttIsConnected
                                ? Colors.green
                                : Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Botón para iniciar o detener el flujo de video
                  ElevatedButton(
                    onLongPress: () {
                      //Función usada para el desarrollo
                      if (sendornot == 0) {
                        mqttProvider.publishMessage("", "StartVideoStream");
                        sendornot = 1;
                      } else {
                        mqttProvider.publishMessage("", "StopVideoStream");
                        sendornot = 0;
                      }
                    },
                    onPressed: () async {
                      // Conectar o desconectar el cliente MQTT
                      if (mqttProvider.mqttIsConnected == false) {
                        await mqttProvider.connectMqttClient();
                        mqttProvider.initDummyService();
                      } else {
                        mqttProvider.disconnectMqttClient();
                      }
                      setState(() {});
                    },
                    child: Text(mqttProvider.mqttIsConnected
                        ? 'Desconectar'
                        : 'Conectar'),
                  ),
                  const SizedBox(height: 5),
                  // Campo de texto para suscribirse a un tema MQTT
                  Visibility(
                    visible: mqttProvider.mqttIsConnected,
                    child: FittedBox(
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 50,
                              width: 150,
                              child: TextField(
                                maxLines: 1,
                                textAlignVertical: TextAlignVertical.center,
                                controller: textController,
                                decoration: const InputDecoration(
                                  isCollapsed: true,
                                  prefixIcon: Icon(Icons.topic),
                                  hintText: 'Drone ID',
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey),
                                  ),
                                ),
                                onSubmitted: (value) {
                                  // Suscribirse al tema ingresado si se pulsa "Enter"
                                  if (textController.text.isNotEmpty &&
                                      mqttProvider.mqttIsConnected) {
                                    mqttProvider.subscribeToTopic(value);
                                    textController.clear();
                                  }
                                },
                                onTapOutside: (event) {
                                  // Desactivar el campo de texto al tocar fuera de él
                                  FocusScope.of(context).unfocus();
                                },
                              ),
                            ),
                            const SizedBox(width: 15),
                            // Botón personalizado
                            MyButton(
                              onTap: () {
                                log("ESTADO CONEXION: ${mqttProvider.connectionState}");
                                // Suscribirse al tema ingresado si se pulsa el botón
                                if (textController.text.isNotEmpty &&
                                    mqttProvider.mqttIsConnected) {
                                  mqttProvider
                                      .subscribeToTopic(textController.text);
                                  textController.clear();
                                }
                              },
                              title: 'Subscribe',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Visualización del flujo de video
                  RepaintBoundary(
                    child: Consumer<MQTTClientWrapper>(
                      builder: (context, mqttclient, child) => ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: size.width),
                        child: AspectRatio(
                          aspectRatio: 4 / 3,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Fondo de la imagen
                              Container(
                                color: Colors.grey[300],
                              ),
                              // Mensaje de cliente desconectado
                              if (mqttclient.mqttIsConnected == false)
                                const Center(
                                  child: Text("Cliente desconectado"),
                                ),
                              // Indicador de carga y visualización del frame de video
                              if (mqttProvider.mqttIsConnected &&
                                  mqttclient.lastVideoFrame.isEmpty)
                                const CircularProgressIndicator(),
                              if (mqttclient.lastVideoFrame.isNotEmpty)
                                Image.memory(
                                  decodeAndShow(mqttclient.lastVideoFrame),
                                  fit: BoxFit.fill,
                                  width: size.width,
                                  height: size.width,
                                  gaplessPlayback: true,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
