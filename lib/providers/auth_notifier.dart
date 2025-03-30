import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Clase que manejará el estado de autenticación
class AuthNotifier extends StateNotifier<User?> {
  final SupabaseClient _supabase;

  AuthNotifier(this._supabase) : super(_supabase.auth.currentUser) {
    // Escucha cambios en el estado de autenticación
    _supabase.auth.onAuthStateChange.listen((event) {
      state = _supabase.auth.currentUser;
    });
  }

  /// Función para cerrar sesión
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    state = null; // Actualiza el estado
  }

  /// Función para iniciar sesión
  Future<void> signIn(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    state = response.user; // Actualiza el estado con el usuario autenticado
  }

  /// Función para registrarse
  Future<void> signUp(String email, String password) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );
    state = response.user; // Actualiza el estado tras el registro
  }
}

/// Provider que expone el estado de autenticación
final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  final supabase = Supabase.instance.client;
  return AuthNotifier(supabase);
});
