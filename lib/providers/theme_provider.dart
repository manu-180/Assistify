import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taller_ceramica/config/theme/app_theme.dart';

// Proveedor para la lista de colores disponibles
final listTheColors = Provider((ref) => listColors);

// Proveedor para manejar el estado del tema
final themeNotifyProvider =
    StateNotifierProvider<ThemeNotify, AppTheme>((ref) => ThemeNotify());

// Clase ThemeNotify que extiende StateNotifier
class ThemeNotify extends StateNotifier<AppTheme> {
  ThemeNotify() : super(AppTheme()) {
    _loadPreferences();
  }

  // Alterna entre modo claro y oscuro
  void toggleDarkMode() {
    state = state.copyWidht(isDarkMode: !state.isDarkMode);
    _savePreferences(); // Guardar preferencias al cambiar
  }

  // Cambia el color seleccionado
  void changeColor(int index) {
    state = state.copyWidht(selectedColor: index);
    _savePreferences(); // Guardar preferencias al cambiar
  }

  // Carga las preferencias del almacenamiento local
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? false;
    final selectedColor = prefs.getInt('selectedColor') ?? 0;

    state = state.copyWidht(
      isDarkMode: isDarkMode,
      selectedColor: selectedColor,
    );
  }

  // Guarda las preferencias en el almacenamiento local
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', state.isDarkMode);
    await prefs.setInt('selectedColor', state.selectedColor);
  }
}
