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
      child: IntrinsicWidth(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icono != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(icono, color: colorScheme.primary, size: 22),
                ),
              Flexible(
                child: Text(
                  texto,
                  softWrap: true,
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
      ),
    );
  }
}
