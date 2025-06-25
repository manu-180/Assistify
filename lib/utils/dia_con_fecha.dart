import 'package:assistify/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class DiaConFecha {
  String obtenerDiaDeLaSemana(String? fecha, AppLocalizations localizations) {
    // Verificar si la fecha es nula o no tiene el formato esperado
    if (fecha == null ||
        fecha.isEmpty ||
        fecha == localizations.translate('selectDate')) {
      return localizations.translate('selectDate');
    }

    try {
      // Parsear la fecha desde el formato "dd/MM/yyyy"
      DateTime parsedDate = DateFormat("dd/MM/yyyy").parse(fecha);

      // Retornar el día traducido usando palabras clave
      switch (parsedDate.weekday) {
        case 1:
          return localizations.translate('monday');
        case 2:
          return localizations.translate('tuesday');
        case 3:
          return localizations.translate('wednesday');
        case 4:
          return localizations.translate('thursday');
        case 5:
          return localizations.translate('friday');
        case 6:
          return localizations.translate('saturday');
        case 7:
          return localizations.translate('sunday');
        default:
          return "-";
      }
    } catch (e) {
      return "-";
    }
  }
}
