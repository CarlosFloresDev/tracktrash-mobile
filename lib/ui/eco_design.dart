import 'package:flutter/material.dart';

abstract final class EcoColors {
  static const pine = Color(0xFF143D2B);
  static const green = Color(0xFF217A51);
  static const lime = Color(0xFFD7F58B);
  static const background = Color(0xFFF6F7F2);
  static const muted = Color(0xFF68766B);
}

ThemeData ecoTheme() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: EcoColors.background,
  colorScheme: ColorScheme.fromSeed(
    seedColor: EcoColors.green,
    primary: EcoColors.pine,
    secondary: EcoColors.green,
    surface: EcoColors.background,
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 36,
      height: 1.12,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.2,
      color: EcoColors.pine,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      height: 1.15,
      fontWeight: FontWeight.w800,
      letterSpacing: -.7,
      color: EcoColors.pine,
    ),
    titleLarge: TextStyle(
      fontSize: 21,
      fontWeight: FontWeight.w700,
      color: EcoColors.pine,
    ),
    bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: EcoColors.pine),
    bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: EcoColors.muted),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: EcoColors.background,
    surfaceTintColor: Colors.transparent,
    titleTextStyle: TextStyle(
      color: EcoColors.pine,
      fontSize: 22,
      fontWeight: FontWeight.w800,
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: Colors.white,
    margin: const EdgeInsets.only(bottom: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: const BorderSide(color: Color(0xFFE6EBE1)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFDBE4D8)),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(48, 54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(48, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: Colors.white,
    indicatorColor: EcoColors.lime,
    labelTextStyle: WidgetStateProperty.all(
      const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
    ),
  ),
);

class EcoEntrance extends StatelessWidget {
  const EcoEntrance({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 420),
    curve: Curves.easeOutCubic,
    child: child,
    builder: (_, v, child) => Opacity(
      opacity: v,
      child: Transform.translate(offset: Offset(0, 14 * (1 - v)), child: child),
    ),
  );
}

class EcoEmpty extends StatelessWidget {
  const EcoEmpty({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.eco_outlined,
    this.action,
  });
  final String title, message;
  final IconData icon;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Icon(icon, size: 44, color: EcoColors.green),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          if (action != null)
            Padding(padding: const EdgeInsets.only(top: 16), child: action!),
        ],
      ),
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 14),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        ?trailing,
      ],
    ),
  );
}
