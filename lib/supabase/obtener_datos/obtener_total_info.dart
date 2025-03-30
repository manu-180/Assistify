import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taller_ceramica/models/clase_models.dart';
import 'package:taller_ceramica/models/subscription_models.dart';
import 'package:taller_ceramica/models/usuario_models.dart';
import 'package:taller_ceramica/utils/internet.dart'; // Importa la clase Internet con hayConexionInternet

class ObtenerTotalInfo {
  final SupabaseClient supabase;
  final String clasesTable;
  final String usuariosTable;

  ObtenerTotalInfo({
    required this.supabase,
    required this.clasesTable,
    required this.usuariosTable,
  });

  Future<List<ClaseModels>> obtenerClases() async {
    if (!await Internet().hayConexionInternet()) {
      throw Exception('No hay conexión a Internet.');
    }

    try {
      final response = await supabase.from(clasesTable).select();

      return (response as List<dynamic>)
          .map((item) => ClaseModels.fromMap(item))
          .toList();
    } catch (e) {
      throw Exception('No se pudieron obtener las clases: $e');
    }
  }

  Future<List<UsuarioModels>> obtenerUsuarios() async {
    if (!await Internet().hayConexionInternet()) {
      throw Exception('No hay conexión a Internet.');
    }

    try {
      final response = await supabase.from(usuariosTable).select();

      return (response as List<dynamic>)
          .map((item) => UsuarioModels.fromMap(item))
          .toList();
    } catch (e) {
      throw Exception('No se pudieron obtener los usuarios: $e');
    }
  }

  Future<List<SubscriptionModel>> obtenerSubscriptos() async {
    if (!await Internet().hayConexionInternet()) {
      throw Exception('No hay conexión a Internet.');
    }

    try {
      final response = await supabase.from("subscriptions").select();

      return (response as List<dynamic>)
          .map((item) => SubscriptionModel.fromMap(item))
          .toList();
    } catch (e) {
      throw Exception('No se pudieron obtener los usuarios: $e');
    }
  }
}
