import 'package:flutter/material.dart';

/// Maktab brand palette: deep mosque green, white, a soft neutral background and a subtle gold accent.
abstract final class MaktabColors {
  static const primary = Color(0xFF0E5240);
  static const primaryDark = Color(0xFF0A3D30);

  /// The wide-screen sidebar, a shade darker than [primary].
  static const sidebar = Color(0xFF0B4033);
  static const sidebarSelected = Color(0xFF1C6A54);
  static const primaryContainer = Color(0xFFDDEFE7);
  static const gold = Color(0xFFB8913A);
  static const background = Color(0xFFF4F6F5);
  static const surface = Colors.white;
  static const outline = Color(0xFFE0E6E3);

  /// Status colours, always paired with text or an icon: present/paid, late/partly, absent/outstanding.
  static const success = Color(0xFF1E8A57);
  static const successContainer = Color(0xFFE3F4EA);
  static const warning = Color(0xFFD9730D);
  static const warningContainer = Color(0xFFFDEEDC);
  static const danger = Color(0xFFC62828);
  static const dangerContainer = Color(0xFFFBE4E4);

  /// [success] and [warning] are too light for small text (below 4.5:1); they are for icons and large figures.
  /// Small text on a status container uses these darker shades instead.
  static const onSuccessContainer = Color(0xFF146B43);
  static const onWarningContainer = Color(0xFF8A4600);
}
