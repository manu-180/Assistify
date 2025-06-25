import 'package:assistify/l10n/app_localizations.dart';
import 'package:assistify/utils/capitalize.dart';
import 'package:assistify/utils/dia_con_fecha.dart';
import 'package:assistify/widgets/custom_box.dart';
import 'package:assistify/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

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
    final color = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () {
            cambiarFecha(false);
          },
          icon: Icon(
            Icons.arrow_back_ios,
            size: screenWidth * 0.07,
            color: color.primary,
          ),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
        SizedBox(width: screenWidth * 0.05),
        CustomBox(
          width: screenWidth > 600 ? screenWidth * 0.15 : screenWidth * 0.35,
          color1: colors.secondaryContainer,
          color2: colors.primary.withAlpha(60),
          text: text.isEmpty
              ? AppLocalizations.of(context).translate('selectDate')
              : Capitalize().capitalize(DiaConFecha()
                  .obtenerDiaDeLaSemana(text, AppLocalizations.of(context))),
        ),
        SizedBox(width: screenWidth * 0.05),
        IconButton(
          onPressed: () {
            cambiarFecha(true);
          },
          icon: Icon(
            Icons.arrow_forward_ios,
            size: screenWidth * 0.07,
            color: color.primary,
          ),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
