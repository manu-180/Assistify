class ClaseModels {
  final int id;
  final String semana;
  final String dia;
  final String fecha;
  final String hora;
  final bool feriado;
  final List<String> mails;
  int lugaresDisponibles;
  final int mes;
  final List<String> espera;

  ClaseModels({
    required this.id,
    required this.semana,
    required this.dia,
    required this.fecha,
    required this.hora,
    required this.feriado,
    required this.mails,
    required this.lugaresDisponibles,
    required this.mes,
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
      feriado: map['feriado'] ?? false,
      mails: List<String>.from(map['mails'] ?? []),
      lugaresDisponibles: map['lugar_disponible'],
      mes: map['mes'],
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
      'feriado': feriado,
      'mails': mails,
      'lugar_disponible': lugaresDisponibles,
      'mes': mes,
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
    bool? feriado,
    List<String>? mails,
    int? lugaresDisponibles,
    int? mes,
    List<String>? espera,
  }) {
    return ClaseModels(
      id: id ?? this.id,
      semana: semana ?? this.semana,
      dia: dia ?? this.dia,
      fecha: fecha ?? this.fecha,
      hora: hora ?? this.hora,
      feriado: feriado ?? this.feriado,
      mails: mails ?? List.from(this.mails),
      lugaresDisponibles: lugaresDisponibles ?? this.lugaresDisponibles,
      mes: mes ?? this.mes,
      espera: espera ?? List.from(this.espera),
    );
  }
}
