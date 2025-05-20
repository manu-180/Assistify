import 'package:intl/intl.dart';

Future<int> contarDiasEnMesActual(String diaEnMinuscula) async {
  final ahora = DateTime.now();
  final primerDiaDelMes = DateTime(ahora.year, ahora.month, 1);
  final ultimoDiaDelMes = DateTime(ahora.year, ahora.month + 1, 0);

  final diasMap = {
    'lunes': DateTime.monday,
    'martes': DateTime.tuesday,
    'miércoles': DateTime.wednesday,
    'miercoles': DateTime.wednesday, // sin tilde
    'jueves': DateTime.thursday,
    'viernes': DateTime.friday,
    'sábado': DateTime.saturday,
    'sabado': DateTime.saturday, // sin tilde
    'domingo': DateTime.sunday,
  };

  final numeroDia = diasMap[diaEnMinuscula];
  if (numeroDia == null) return 0;

  int contador = 0;
  for (int i = 0; i < ultimoDiaDelMes.day; i++) {
    final fecha = primerDiaDelMes.add(Duration(days: i));
    if (fecha.weekday == numeroDia) contador++;
  }

  return contador;
}
