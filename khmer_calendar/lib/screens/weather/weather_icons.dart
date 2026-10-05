import 'package:flutter/material.dart';

IconData wxMaterialIcon(int code) {
  if (code <= 1) return Icons.wb_sunny;
  if (code <= 3) return Icons.cloud;
  if (code <= 48) return Icons.dehaze;
  if (code <= 86) return Icons.umbrella;
  return Icons.flash_on;
}
