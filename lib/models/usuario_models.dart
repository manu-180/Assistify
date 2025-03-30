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
  });

  // Función para convertir el mapa a un objeto UsuarioModels
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

    );
  }

  @override
  String toString() {
    return 'UsuarioModels(id: $id, usuario: $usuario, fullname: $fullname, userUid: $userUid, sexo: $sexo, clasesDisponibles: $clasesDisponibles, alertTrigger: $alertTrigger, taller: $taller, admin: $admin, createdAt: $createdAt)';
  }
}
