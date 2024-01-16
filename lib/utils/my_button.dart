// Importación de la biblioteca Flutter
import 'package:flutter/material.dart';

// Definición de un botón personalizado reutilizable
class MyButton extends StatelessWidget {
  final String title; // Título del botón
  final Function() onTap; // Función a ejecutar al tocar el botón

  // Constructor del botón con parámetros requeridos
  const MyButton({super.key, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Retorna un widget InkWell que es un área sensible al toque
    return InkWell(
      onTap: onTap, // Asigna la función onTap al evento onTap del InkWell
      child: Container(
        height: 48,
        width: 100,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black26)),
        child: Text(
          title, // Muestra el título del botón
          style: const TextStyle(color: Colors.white), // Estilo del texto
        ),
      ),
    );
  }
}
