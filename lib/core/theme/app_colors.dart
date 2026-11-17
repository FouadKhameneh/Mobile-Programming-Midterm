import 'package:material_ui/material_ui.dart';

/// Soundify's design tokens. The palette intentionally leans into a deep
/// midnight canvas with violet and cyan light.
abstract final class AppColors {
  static const Color background = Color(0xFF07080F);
  static const Color backgroundElevated = Color(0xFF0D0F1A);
  static const Color surface = Color(0xFF131522);
  static const Color surfaceHigh = Color(0xFF1B1E2E);
  static const Color surfaceGlass = Color(0xFF1A1D2B);
  static const Color outline = Color(0xFF2A2F44);

  static const Color primary = Color(0xFFA78BFA);
  static const Color primaryDeep = Color(0xFF7C3AED);
  static const Color accent = Color(0xFF67E8F9);
  static const Color pink = Color(0xFFF472B6);
  static const Color mint = Color(0xFF6EE7B7);
  static const Color danger = Color(0xFFFB7185);
  static const Color warning = Color(0xFFFBBF24);

  static const Color textPrimary = Color(0xFFF6F3FF);
  static const Color textSecondary = Color(0xFFA8A5BF);
  static const Color textMuted = Color(0xFF6F6C86);

  static const Color lightBackground = Color(0xFFF7F6FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF1A1726);
  static const Color lightTextSecondary = Color(0xFF5D5A70);

  static const LinearGradient brandGradient = LinearGradient(
    colors: <Color>[primaryDeep, Color(0xFFC026D3), Color(0xFF0891B2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: <Color>[Color(0xFF7C3AED), Color(0xFFF472B6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient coverFallback = LinearGradient(
    colors: <Color>[Color(0xFF23263A), Color(0xFF141624)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: <Color>[Color(0x22FFFFFF), Color(0x08FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
