// PÁGINA EN DESUSO -----------------------------------------------------------
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:dronestream/services/mqtt_client.dart';
import 'package:dronestream/utils/my_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late TextEditingController textController;
  late Size size;
  bool isConnected = false;
  Uint8List? backgroundImage;
  int sendornot = 0;

  @override
  void initState() {
    super.initState();
    textController = TextEditingController();
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  Uint8List decodeAndShow(String frame) {
    Uint8List image = base64Decode(frame);
    backgroundImage = image;
    return image;
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.sizeOf(context);

    return Consumer<MQTTClientWrapper>(
      builder: (context, mqttclient, child) => Scaffold(
        appBar: AppBar(
          title: const Text(
            "DroneStream",
            style: TextStyle(color: Colors.black),
          ),
          leading: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Image.asset('assets/icon/drone_icon_nobg.png'),
          ),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: mqttclient.mqttIsConnected
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      mqttclient.mqttIsConnected ? 'Conectado' : 'Desconectado',
                      style: TextStyle(
                          color: mqttclient.mqttIsConnected
                              ? Colors.green
                              : Colors.red),
                    ),
                  ],
                ),
              ),
            ),
          ],
          elevation: 0,
          backgroundColor: Colors.grey[300],
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onLongPress: () {
                        if (sendornot == 0) {
                          mqttclient.publishMessage("", "StartVideoStream");
                          sendornot = 1;
                        } else {
                          mqttclient.publishMessage("", "StopVideoStream");
                          sendornot = 0;
                        }
                      },
                      onPressed: () async {
                        if (mqttclient.mqttIsConnected == false) {
                          await mqttclient.connectMqttClient();
                          mqttclient.initDummyService();
                        } else {
                          mqttclient.disconnectMqttClient();
                        }
                      },
                      child: Text(mqttclient.mqttIsConnected
                          ? 'Desconectar'
                          : 'Conectar'),
                    ),
                    FittedBox(
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
                                  if (textController.text.isNotEmpty &&
                                      mqttclient.mqttIsConnected) {
                                    mqttclient.subscribeToTopic(value);
                                    textController.clear();
                                  }
                                },
                                onTapOutside: (event) {
                                  FocusScope.of(context).unfocus();
                                },
                              ),
                            ),
                            const SizedBox(width: 15),
                            MyButton(
                              onTap: () {
                                log("ESTADO CONEXION: ${mqttclient.connectionState}");
                                if (textController.text.isNotEmpty &&
                                    mqttclient.mqttIsConnected) {
                                  mqttclient
                                      .subscribeToTopic(textController.text);
                                  textController.clear();
                                }
                              },
                              title: 'Send',
                            ),
                          ],
                        ),
                      ),
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: size.width),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Stack(
                          children: [
                            Container(
                              color: Colors.grey[300],
                            ),
                            if (mqttclient.mqttIsConnected == false)
                              const Center(
                                child: Text("Cliente desconectado"),
                              ),
                            if (backgroundImage != null)
                              Image.memory(
                                backgroundImage!,
                                fit: BoxFit.fill,
                                width: size.width,
                                height: size.width,
                              ),
                            //),
                            if (mqttclient.lastVideoFrame.isNotEmpty)
                              Image.memory(
                                decodeAndShow(mqttclient.lastVideoFrame),
                                fit: BoxFit.fill,
                                width: size.width,
                                height: size.width,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
