import 'package:intl/intl.dart';

class GenerarFechasDelMes {
  List<String> generarFechasDelMes(int mes, int year) {
    final DateFormat formato = DateFormat('dd/MM/yyyy');
    final List<String> fechas = [];

    // Calcular el primer y último día del mes especificado
    final DateTime inicio = DateTime(year, mes, 1);
    final DateTime fin =
        DateTime(year, mes + 1, 0); // Último día del mes actual

    for (DateTime fecha = inicio;
        fecha.isBefore(fin) || fecha.isAtSameMomentAs(fin);
        fecha = fecha.add(const Duration(days: 1))) {
      // Verificar si la fecha es de lunes a viernes
      if (fecha.weekday >= DateTime.monday &&
          fecha.weekday <= DateTime.friday) {
        fechas.add(formato.format(fecha));
      }
    }

    return fechas;
  }
}
