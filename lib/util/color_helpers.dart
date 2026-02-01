import 'package:flutter/material.dart';

/// Parses a hex color string (like "#FFAA00") into a Flutter Color object.
/// Returns a default color if the string is null or invalid.
Color hexToColor(String? hexString, {Color defaultColor = Colors.grey}) {
  if (hexString == null || hexString.isEmpty) {
    return defaultColor;
  }

  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) {
    buffer.write('ff'); // Add the alpha channel if it's missing
  }
  buffer.write(hexString.replaceFirst('#', ''));

  try {
    return Color(int.parse(buffer.toString(), radix: 16));
  } catch (e) {
    return defaultColor;
  }
}
