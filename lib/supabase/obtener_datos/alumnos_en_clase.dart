import 'package:taller_ceramica/supabase/obtener_datos/obtener_taller.dart';
import 'package:taller_ceramica/supabase/supabase_barril.dart';
import 'package:taller_ceramica/main.dart';
import 'dart:convert';

class AlumnosEnClase {
  Future<List<String>> clasesAlumno(String alumno, columna) async {
    final usuarioActivo = Supabase.instance.client.auth.currentUser;

    // Obtener el nombre del taller
    final taller = await ObtenerTaller().retornarTaller(usuarioActivo!.id);

    // Consulta a Supabase para obtener las clases donde el alumno está inscrito
    final data = await supabase
        .from(taller) // Nombre de la tabla de clases
        .select(
            'dia, fecha, hora, mails') // Selecciona solo las columnas necesarias
        .contains(
            columna,
            jsonEncode(
                [alumno])); // Filtra clases donde "mails" contiene al alumno

    // Lista para almacenar las clases como objetos con fecha/hora ordenables
    final List<Map<String, dynamic>> clasesProcesadas = [];

    for (final clase in data) {
      final partesFecha = (clase['fecha'] as String).split('/');
      final dia = clase['dia'];
      final hora = clase['hora'];

      // Combina fecha y hora para crear un objeto DateTime
      final fechaHora = DateTime.parse(
        '${partesFecha[2]}-${partesFecha[1]}-${partesFecha[0]}T$hora:00',
      );

      // Guarda la información con la fecha/hora para ordenar después
      clasesProcesadas.add({
        'fechaHora': fechaHora,
        'info': "$dia ${partesFecha[0]} a las $hora",
      });
    }

    // Ordena las clases por proximidad de fecha/hora
    clasesProcesadas.sort((a, b) => a['fechaHora'].compareTo(b['fechaHora']));

    // Devuelve solo la información formateada
    return clasesProcesadas.map((clase) => clase['info'] as String).toList();
  }
}
