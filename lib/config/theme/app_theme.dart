import 'package:flutter/material.dart';

const List<Color> listColors = [
  Color(0xFFE74C3C),
  Color(0xFFF7D794),
  Color(0xFF55E6C1),
  Color(0xFF00CEC9),
  Color(0xFFADD8E6),
  Color(0xFFAF52DE),
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
