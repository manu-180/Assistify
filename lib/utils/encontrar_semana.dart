import 'package:intl/intl.dart';

class EncontrarSemana {
  String obtenerSemana(String fechaStr) {
    DateFormat formatoFecha = DateFormat("dd/MM/yyyy");
    DateTime fecha = formatoFecha.parse(fechaStr);

    DateTime primerDiaMes = DateTime(fecha.year, fecha.month, 1);

    // Encontrar el primer domingo del mes
    int diasHastaPrimerDomingo = (7 - primerDiaMes.weekday) % 7;
    DateTime primerDomingo =
        primerDiaMes.add(Duration(days: diasHastaPrimerDomingo));

    // Calcular los días desde el primer domingo
    int diasDesdePrimerDomingo = fecha.difference(primerDomingo).inDays;

    // Si la fecha está antes del primer domingo, es semana 1
    if (diasDesdePrimerDomingo < 0) {
      return 'semana1';
    }

    // Calcular la semana a partir del primer domingo
    int semana = (diasDesdePrimerDomingo / 7).floor() + 2;

    // Ajustar a un máximo de 5 semanas
    if (semana > 5) {
      semana = 5;
    }

    return 'semana$semana';
  }
}
