import 'package:flutter/material.dart';

const kPrimaryColor = Color(0xFF4F46E5); // Deep Indigo
const kSecondaryAiColor = Color(0xFF7C3AED); // Electric Violet
const kAccentColor = Color(0xFF06B6D4); // Cyan AI Accent
const kBackgroundColor = Color(0xFFE3F2FD); // Clean Solid Light Blue
const kCardColor = Colors.white;
const kTextPrimary = Color(0xFF0F172A);
const kTextSecondary = Color(0xFF64748B);

const kAiGradient = LinearGradient(
  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFF0EA5E9)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const kSoftAiGradient = LinearGradient(
  colors: [Color(0xFFEEF2FF), Color(0xFFF5F3FF), Color(0xFFECFEFF)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class AiBackground extends StatelessWidget {
  final Widget child;
  const AiBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: kBackgroundColor,
      child: child,
    );
  }
}

ThemeData appTheme() {
  return ThemeData(
    primaryColor: kPrimaryColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kPrimaryColor,
      primary: kPrimaryColor,
      secondary: kAccentColor,
      surface: kBackgroundColor,
    ),
    scaffoldBackgroundColor: kBackgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(50),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.2),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kPrimaryColor, width: 1.8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    ),
    cardTheme: CardThemeData(
      color: kCardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    ),
    useMaterial3: true,
  );
}

Color statusColor(String status) {
  switch (status) {
    case 'pending':
      return const Color(0xFFF59E0B);
    case 'accepted':
      return const Color(0xFF10B981);
    case 'rejected':
      return const Color(0xFFEF4444);
    case 'cancelled':
      return const Color(0xFF64748B);
    case 'completed':
      return const Color(0xFF4F46E5);
    default:
      return const Color(0xFF64748B);
  }
}

IconData statusIcon(String status) {
  switch (status) {
    case 'pending':
      return Icons.hourglass_top_rounded;
    case 'accepted':
      return Icons.check_circle_rounded;
    case 'rejected':
      return Icons.cancel_rounded;
    case 'cancelled':
      return Icons.block_rounded;
    case 'completed':
      return Icons.verified_rounded;
    default:
      return Icons.info_rounded;
  }
}
