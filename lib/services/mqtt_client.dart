import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

// connection states for easy identification
enum MqttCurrentConnectionState {
  IDLE,
  CONNECTING,
  CONNECTED,
  DISCONNECTED,
  ERROR_WHEN_CONNECTING
}

enum MqttSubscriptionState { IDLE, SUBSCRIBED }

/*
String server = 'ee29acde5e9c4c0aa728e6c098fddfb1.s1.eu.hivemq.cloud';
String clientIdentifier = 'prueba_flutter';
int port = 8883;

MqttServerClient client = MqttServerClient.withPort(
    'broker.emqx.io',
    'prueba_flutter',
    1883,
  );*/

class MQTTClientWrapper extends ChangeNotifier {
  MqttServerClient client = MqttServerClient.withPort(
    'classpip.upc.edu',
    'prueba_flutter',
    1884,
  );

  MqttCurrentConnectionState connectionState = MqttCurrentConnectionState.IDLE;
  MqttSubscriptionState subscriptionState = MqttSubscriptionState.IDLE;

  List<String> listaValueMensajes = [];
  bool mqttIsConnected = false;
  List<String> subscribedTopics = [];
  String lastVideoFrame = '';
  final Completer<void> _subscriptionCompleter = Completer<void>();
  bool isSubscribedToValue = false;

  /*void initMqtt() {
    MQTTClientWrapper newclient = MQTTClientWrapper();
    newclient.prepareMqttClient();
  }*/

  // using async tasks, so the connection won't hinder the code flow
  /*void prepareMqttClient() async {
    _setupMqttClient();
    await _connectClient();
    subscribeToTopic('Dart/Mqtt_client/testtopic');
    publishMessage('MENSAJE_PRUEBA', 'dart/mqtt/parameters');
  }*/

  Future<bool> connectMqttClient() async {
    _setupMqttClient();
    return await _connectClient();
  }

  void _setupMqttClient() {
    //client = MqttServerClient.withPort('<your_host>', '<your_name>', <your_port>);
    // the next 2 lines are necessary to connect with tls, which is used by HiveMQ Cloud
    //client.secure = true;
    //client.securityContext = SecurityContext.defaultContext;
    client.keepAlivePeriod = 60;
    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;
    client.onSubscribed = _onSubscribed;
    //client.port = 1884;
    //client.port = 1883;
  }

  // waiting for the connection, if an error occurs, print it and disconnect
  Future<bool> _connectClient() async {
    try {
      log('client connecting....');
      connectionState = MqttCurrentConnectionState.CONNECTING;
      await client.connect('dronsEETAC', 'mimara1456.');
      //await client.connect();
    } on Exception catch (e) {
      log('client exception - $e');
      connectionState = MqttCurrentConnectionState.ERROR_WHEN_CONNECTING;
      client.disconnect();
      mqttIsConnected = false;
      notifyListeners();
      return false;
    }

    // when connected, print a confirmation, else print an error
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

  void disconnectMqttClient() {
    unsubscribeFromAllTopics();
    client.disconnect();
  }

  void subscribeToTopic(String topicName) {
    log('Subscribing to the $topicName topic');
    client.subscribe(topicName, MqttQos.atMostOnce);
  }

  Future<void> getSubscriptionFuture() {
    return _subscriptionCompleter.future;
  }

  void publishMessage(String message, String topic) {
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(message);

    log('Publishing message "$message" to topic $topic');

    client.publishMessage(topic, MqttQos.exactlyOnce, builder.payload!);
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

  void initDummyService() {
    publishMessage('', 'Connect');
  }

  // callbacks for different events -------------------------------------------
  void _onSubscribed(String topic) {
    log('Subscription confirmed for topic $topic');
    subscriptionState = MqttSubscriptionState.SUBSCRIBED;

    if (!subscribedTopics.contains(topic)) {
      subscribedTopics.add(topic);
    }
    notifyListeners();

    /*if (topic == 'Value' && !_subscriptionCompleter.isCompleted) {
      _subscriptionCompleter.complete();
    }*/
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

    //Nos suscribimos a los tópicos necesarios
    //client.subscribe('writeParameters', MqttQos.atLeastOnce);
    //client.subscribe('Value', MqttQos.atLeastOnce);
    //client.subscribe('videoFrame', MqttQos.atLeastOnce);

    // print the message when it is received
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
      var message =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      /*if (c[0].topic == 'Value') listaValueMensajes.add(message);
      if (c[0].topic == 'videoFrame') {
        lastVideoFrame = message;
        notifyListeners();
      }*/

      log('YOU GOT A NEW MESSAGE:');
      log(message);
    });
  }
}
