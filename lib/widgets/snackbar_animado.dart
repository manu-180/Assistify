import 'package:flutter/material.dart';

 void mostrarSnackBarAnimado({
    required BuildContext context,
    required String mensaje,
    Color? colorFondo,
     int duracionSegundos = 6,
    
  }) {
 final theme = Theme.of(context);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      
      SnackBar(
        duration: Duration(seconds: duracionSegundos),

        backgroundColor: Colors.transparent,
        elevation: 0,
        content: GestureDetector(
          onTap: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          child: Material(
            // 👈 clave para que el tap funcione bien
            color: Colors.transparent,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorFondo ?? theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                mensaje,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }