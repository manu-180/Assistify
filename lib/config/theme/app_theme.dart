import 'package:flutter/material.dart';

const List<Color> listColors = [
  Color(0xFF00A8E8), // Celeste vibrante
  Color(0xFF26D1D9), // Aguamarina brillante
  Color(0xFF55E6C1), // Verde agua
  Color(0xFFF7D794), // Amarillo pastel
  Color(0xFFFFA552), // Naranja suave vibrante
  Color(0xFFE74C3C), // Rojo coral
  Color(0xFFAF52DE), // Violeta brillante
  Color(0xFF4285F4), // Azul Google moderno
  Color(0xFF34D399), // Verde menta saturado
  Color(0xFFFF6B81), // Rosa coral vibrante
];


class AppTheme {
  final int selectedColor;
  final bool isDarkMode;

  AppTheme({this.selectedColor = 0, this.isDarkMode = false});

  ThemeData getColor() => ThemeData(
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      colorSchemeSeed: listColors[selectedColor],
      appBarTheme: const AppBarTheme(centerTitle: false));

  AppTheme copyWidht({bool? isDarkMode, int? selectedColor}) => AppTheme(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      selectedColor: selectedColor ?? this.selectedColor);
}
