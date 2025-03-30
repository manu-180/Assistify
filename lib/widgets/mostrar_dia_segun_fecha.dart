import 'package:flutter/material.dart';
import 'package:taller_ceramica/utils/dia_con_fecha.dart';
import 'package:taller_ceramica/widgets/custom_box.dart';
import 'package:taller_ceramica/l10n/app_localizations.dart'; // Importar traducciones

class MostrarDiaSegunFecha extends StatelessWidget {
  const MostrarDiaSegunFecha({
    super.key,
    required this.text,
    required this.colors,
    required this.color,
    required this.cambiarFecha,
  });

  final ColorScheme colors;
  final Color color;
  final String text;
  final void Function(bool) cambiarFecha;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade200,
            boxShadow: [
              BoxShadow(
                color: colors.primaryContainer.withAlpha(20),
                blurRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () {
              cambiarFecha(false);
            },
            icon: const Icon(Icons.arrow_left, size: 28),
            color: Colors.black,
          ),
        ),
        SizedBox(width: screenWidth * 0.05),
        CustomBox(
          width: screenWidth > 600 ? screenWidth * 0.15 : screenWidth * 0.35,
          color1: colors.secondaryContainer,
          color2: colors.primary.withAlpha(60),
          text: text.isEmpty
              ? AppLocalizations.of(context).translate('selectDate')
              : DiaConFecha().obtenerDiaDeLaSemana(
                  text, AppLocalizations.of(context)), // Pasar el contexto
        ),
        SizedBox(width: screenWidth * 0.05),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade200,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () {
              cambiarFecha(true);
            },
            icon: const Icon(Icons.arrow_right, size: 28),
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
