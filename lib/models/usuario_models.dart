class UsuarioModels {
  final int id;
  final String usuario;
  final String fullname;
  final String userUid;
  final String sexo;
  final String taller;
  final int clasesDisponibles;
  final int alertTrigger;
  final bool admin;
  final DateTime createdAt;
  final String rubro;
  final String? telefono;

  UsuarioModels({
    required this.id,
    required this.usuario,
    required this.fullname,
    required this.userUid,
    required this.sexo,
    required this.clasesDisponibles,
    required this.alertTrigger,
    required this.taller,
    required this.admin,
    required this.createdAt,
    required this.rubro,
    required this.telefono,
  });

  factory UsuarioModels.fromMap(Map<String, dynamic> map) {
    return UsuarioModels(
      id: map['id'],
      usuario: map['usuario'],
      fullname: map['fullname'],
      userUid: map['user_uid'],
      sexo: map['sexo'],
      clasesDisponibles: map['clases_disponibles'],
      alertTrigger: map['trigger_alert'],
      taller: map['taller'],
      admin: map['admin'],
      createdAt: DateTime.parse(map['created_at']),
      rubro: map['rubro'],
      telefono: map['telefono'],
    );
  }

  UsuarioModels copyWith({
    int? id,
    String? usuario,
    String? fullname,
    String? userUid,
    String? sexo,
    String? taller,
    int? clasesDisponibles,
    int? alertTrigger,
    bool? admin,
    DateTime? createdAt,
    String? rubro,
    String? telefono,
  }) {
    return UsuarioModels(
      id: id ?? this.id,
      usuario: usuario ?? this.usuario,
      fullname: fullname ?? this.fullname,
      userUid: userUid ?? this.userUid,
      sexo: sexo ?? this.sexo,
      taller: taller ?? this.taller,
      clasesDisponibles: clasesDisponibles ?? this.clasesDisponibles,
      alertTrigger: alertTrigger ?? this.alertTrigger,
      admin: admin ?? this.admin,
      createdAt: createdAt ?? this.createdAt,
      rubro: rubro ?? this.rubro,
      telefono: telefono ?? this.telefono,
    );
  }

  @override
  String toString() {
    return 'UsuarioModels(id: $id, usuario: $usuario, fullname: $fullname, userUid: $userUid, sexo: $sexo, clasesDisponibles: $clasesDisponibles, alertTrigger: $alertTrigger, taller: $taller, admin: $admin, createdAt: $createdAt)';
  }
}
