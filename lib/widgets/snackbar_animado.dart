import 'package:animate_do/animate_do.dart';
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
      behavior: SnackBarBehavior.fixed, // Usar fixed para evitar errores de layout
      backgroundColor: Colors.transparent,
      elevation: 0,
      content: SlideInUp(
        duration: const Duration(milliseconds: 500),
        child: Material(
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
