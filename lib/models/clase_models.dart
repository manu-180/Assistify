class ClaseModels {
  final int id;
  final String semana;
  final String dia;
  final String fecha;
  final String hora;
  final List<String> mails;
  int lugaresDisponibles;
  final int mes;
  final int capacidad;
  final List<String> espera;

  ClaseModels({
    required this.id,
    required this.semana,
    required this.dia,
    required this.fecha,
    required this.hora,
    required this.mails,
    required this.lugaresDisponibles,
    required this.mes,
    required this.capacidad,
    required this.espera,
  });

  @override
  String toString() {
    return 'ClaseModels(id: $id, semana: $semana, lugaresDisponibles: $lugaresDisponibles, dia: $dia, fecha: $fecha, hora: $hora, mails: $mails)';
  }

  // Método para crear una instancia desde un Map (útil para bases de datos)
  factory ClaseModels.fromMap(Map<String, dynamic> map) {
    return ClaseModels(
      id: map['id'],
      semana: map['semana'],
      dia: map['dia'],
      fecha: map['fecha'],
      hora: map['hora'],
      mails: List<String>.from(map['mails'] ?? []),
      lugaresDisponibles: map['lugar_disponible'],
      mes: map['mes'],
      capacidad: map['capacidad'],
      espera: List<String>.from(map['espera'] ?? []),
    );
  }

  // Método para convertir una instancia a Map (útil para bases de datos)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'semana': semana,
      'dia': dia,
      'fecha': fecha,
      'hora': hora,
      'mails': mails,
      'lugar_disponible': lugaresDisponibles,
      'mes': mes,
      'capacidad': capacidad,
      'espera': espera,
    };
  }

  // Método copyWith para copiar y modificar instancias
  ClaseModels copyWith({
    int? id,
    String? semana,
    String? dia,
    String? fecha,
    String? hora,
    List<String>? mails,
    int? lugaresDisponibles,
    int? mes,
    int? capacidad,
    List<String>? espera,
  }) {
    return ClaseModels(
      id: id ?? this.id,
      semana: semana ?? this.semana,
      dia: dia ?? this.dia,
      fecha: fecha ?? this.fecha,
      hora: hora ?? this.hora,
      mails: mails ?? List.from(this.mails),
      lugaresDisponibles: lugaresDisponibles ?? this.lugaresDisponibles,
      mes: mes ?? this.mes,
      capacidad: capacidad ?? this.capacidad,
      espera: espera ?? List.from(this.espera),
    );
  }
}
