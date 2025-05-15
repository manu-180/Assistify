import 'package:flutter/material.dart';

class TituloSeleccion extends StatelessWidget {
  final String texto;
  final IconData? icono;

  const TituloSeleccion({super.key, required this.texto, this.icono});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Stack(
        children: [
          // Marca de agua decorativa
          if (icono != null)
            Positioned(
              top: 12,
              left: 12,
              child: Icon(
                icono,
                size: 64,
                color: colorScheme.primary.withOpacity(0.07),
              ),
            ),
          // Contenido principal
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icono != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(icono, color: colorScheme.primary, size: 22),
                  ),
                Expanded(
                  child: Text(
                    texto,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          fontFamily: "oxanium",
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
