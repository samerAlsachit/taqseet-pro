import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

class AppTextStyles {
  static const String _font = AppConstants.fontFamily;

  static TextStyle get heading1 => TextStyle(fontFamily: _font, fontSize: 28, fontWeight: FontWeight.w700);
  static TextStyle get heading2 => TextStyle(fontFamily: _font, fontSize: 22, fontWeight: FontWeight.w700);
  static TextStyle get heading3 => TextStyle(fontFamily: _font, fontSize: 18, fontWeight: FontWeight.w700);
  static TextStyle get bodyLarge => TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w400);
  static TextStyle get bodyMedium => TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w400);
  static TextStyle get bodySmall => TextStyle(fontFamily: _font, fontSize: 12, fontWeight: FontWeight.w400);
  static TextStyle get button => TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w700);
  static TextStyle get caption => TextStyle(fontFamily: _font, fontSize: 11, fontWeight: FontWeight.w400);
  static TextStyle get label => TextStyle(fontFamily: _font, fontSize: 14, fontWeight: FontWeight.w500);
}
