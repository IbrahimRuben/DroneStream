// Importaciones necesarias para el funcionamiento del código
import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

// Enumeraciones para los estados de conexión y suscripción MQTT
enum MqttCurrentConnectionState {
  IDLE,
  CONNECTING,
  CONNECTED,
  DISCONNECTED,
  ERROR_WHEN_CONNECTING
}

enum MqttSubscriptionState { IDLE, SUBSCRIBED }

// Clase que envuelve el cliente MQTT y proporciona funcionalidades específicas
class MQTTClientWrapper extends ChangeNotifier {
  MqttServerClient client = MqttServerClient.withPort(
    'classpip.upc.edu',
    'prueba_flutter',
    1884,
  );

  // Estados de conexión y suscripción MQTT
  MqttCurrentConnectionState connectionState = MqttCurrentConnectionState.IDLE;
  MqttSubscriptionState subscriptionState = MqttSubscriptionState.IDLE;

  // Variables relacionadas con la conexión MQTT
  bool mqttIsConnected = false;
  List<String> subscribedTopics = [];
  String lastVideoFrame = '';

  // Inicialización del cliente MQTT y conexión
  Future<bool> connectMqttClient() async {
    _setupMqttClient();
    return await _connectClient();
  }

  // Configuración del cliente MQTT
  void _setupMqttClient() {
    client.keepAlivePeriod = 60;
    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;
    client.onSubscribed = _onSubscribed;
  }

  // Conectar al cliente MQTT y gestionar estados
  Future<bool> _connectClient() async {
    try {
      log('client connecting....');
      connectionState = MqttCurrentConnectionState.CONNECTING;
      await client.connect('dronsEETAC', 'mimara1456.');
    } on Exception catch (e) {
      log('client exception - $e');
      connectionState = MqttCurrentConnectionState.ERROR_WHEN_CONNECTING;
      client.disconnect();
      mqttIsConnected = false;
      notifyListeners();
      return false;
    }

    // Cuando nos conectamos, printeamos diferentes resultados
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      connectionState = MqttCurrentConnectionState.CONNECTED;
      log('client connected');
      mqttIsConnected = true;
      notifyListeners();
      return true;
    } else {
      log('ERROR client connection failed - disconnecting, status is ${client.connectionStatus}');
      connectionState = MqttCurrentConnectionState.ERROR_WHEN_CONNECTING;
      client.disconnect();
      mqttIsConnected = false;
      notifyListeners();
      return false;
    }
  }

  // Desconectar el cliente MQTT y desuscribirse de todos los tópicos
  void disconnectMqttClient() {
    unsubscribeFromAllTopics();
    client.disconnect();
  }

  // Suscribirse a un tópico MQTT
  void subscribeToTopic(String topicName) {
    log('Subscribing to the $topicName topic');
    client.subscribe(topicName, MqttQos.atMostOnce);
  }

  // Publicar un mensaje en un tópico MQTT
  void publishMessage(String message, String topic) {
    if (mqttIsConnected) {
      final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
      builder.addString(message);

      log('Publishing message "$message" to topic $topic');

      client.publishMessage(topic, MqttQos.exactlyOnce, builder.payload!);
    } else {
      log("Cliente desconectado");
    }
  }

  // Método para desuscribirse de todos los tópicos
  void unsubscribeFromAllTopics() {
    for (String topic in subscribedTopics) {
      unsubscribeFromTopic(topic);
    }
    subscribedTopics.clear(); // Limpiar la lista de tópicos suscritos
    notifyListeners();
  }

  // Método para desuscribirse de un tópico específico
  void unsubscribeFromTopic(String topic) {
    log('Unsubscribing from the $topic topic');
    client.unsubscribe(topic);
    notifyListeners();
  }

  // Inicializar el DummyService
  void initDummyService() {
    publishMessage('', 'Connect');
  }

  // Callbacks para diferentes eventos MQTT -----------------------------------
  void _onSubscribed(String topic) {
    log('Subscription confirmed for topic $topic');
    subscriptionState = MqttSubscriptionState.SUBSCRIBED;

    // Para evitar suscribirse a tópicos ya suscritos
    if (!subscribedTopics.contains(topic)) {
      subscribedTopics.add(topic);
    }
    notifyListeners();
  }

  void _onDisconnected() {
    log('OnDisconnected client callback - Client disconnection');
    mqttIsConnected = false;
    connectionState = MqttCurrentConnectionState.DISCONNECTED;
    notifyListeners();
  }

  void _onConnected() {
    connectionState = MqttCurrentConnectionState.CONNECTED;
    log('OnConnected client callback - Client connection was sucessful');

    // Escuchamos las actualizaciones para recibir mensajes
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
      var message =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      //Si se recibe un mensaje en el tópico 'videoFrame', se actualiza el frame
      // IMPORTANTE CAMBIAR ESTO POR LA VARIABLE DEL TÓPICO
      if (c[0].topic == 'videoFrame') {
        lastVideoFrame = message;
        notifyListeners();
      }

      log('YOU GOT A NEW MESSAGE:');
      log(message);
    });
  }
}
