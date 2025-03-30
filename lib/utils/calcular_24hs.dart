class Calcular24hs {
  bool esMayorA24Horas(String fecha, String hora) {
    final List<String> partesFecha = fecha.split('/');
    if (partesFecha.length != 3) {
      throw const FormatException(
          "La fecha no está en el formato correcto (dd/MM/yyyy)");
    }
    final int dia = int.parse(partesFecha[0]);
    final int mes = int.parse(partesFecha[1]);
    final int anio = int.parse(partesFecha[2]);

    final List<String> partesHora = hora.split(':');
    if (partesHora.length != 2) {
      throw const FormatException(
          "La hora no está en el formato correcto (HH:mm)");
    }
    final int horas = int.parse(partesHora[0]);
    final int minutos = int.parse(partesHora[1]);

    final DateTime fechaClase = DateTime(anio, mes, dia, horas, minutos);

    final DateTime fechaActual = DateTime.now();

    final Duration diferencia = fechaClase.difference(fechaActual);

    return diferencia.inHours > 23;
  }

  bool esMenorA0Horas(String fecha, String hora, int mesActual) {
    final List<String> partesFecha = fecha.split('/');
    if (partesFecha.length != 3) {
      throw const FormatException(
          "La fecha no está en el formato correcto (dd/MM/yyyy)");
    }
    final int dia = int.parse(partesFecha[0]);
    // Usar el mes actual en lugar del extraído de la fecha
    final int mes = mesActual;
    final int anio = int.parse(partesFecha[2]);

    // Dividir la hora en horas y minutos
    final List<String> partesHora = hora.split(':');
    if (partesHora.length != 2) {
      throw const FormatException(
          "La hora no está en el formato correcto (HH:mm)");
    }
    final int horas = int.parse(partesHora[0]);
    final int minutos = int.parse(partesHora[1]);

    // Crear el objeto DateTime para la clase
    final DateTime fechaClase = DateTime(anio, mes, dia, horas, minutos);

    // Obtener la fecha actual
    final DateTime fechaActual = DateTime.now();

    // Calcular la diferencia entre la fecha de la clase y la fecha actual
    final Duration diferencia = fechaClase.difference(fechaActual);

    return diferencia.inSeconds < 0;
  }
}
