import 'package:dronestream/pages/main_page.dart';
import 'package:dronestream/services/mqtt_client.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => MQTTClientWrapper(),
        ),
      ],
      builder: (context, child) => const MaterialApp(
        //showPerformanceOverlay: true,
        debugShowCheckedModeBanner: false,
        title: 'DroneStream',
        home: MainPage(),
      ),
    );
  }
}
