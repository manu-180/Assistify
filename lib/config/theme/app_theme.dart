import 'package:flutter/material.dart';

const List<Color> listColors = [
  Color(0xFF00A8E8), // Celeste vibrante (color principal)
  Color(0xFF26D1D9), // Aguamarina brillante
  Color(0xFF55E6C1), // Verde agua
  Color(0xFFF7D794), // Amarillo pastel
  Color(0xFFFFA552), // Naranja suave vibrante (nuevo)
  Color(0xFFE74C3C), // Rojo coral
  Color(0xFFAF52DE), // Violeta brillante
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
