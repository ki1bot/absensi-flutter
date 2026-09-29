import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const primary = Color(0xFF2563EB);
  static const primarySoft = Color(0x142563EB);

  static const success = Color(0xFF16805C);
  static const successSoft = Color(0x1416805C);

  static const warning = Color(0xFFB76E18);
  static const warningSoft = Color(0x14B76E18);

  static const danger = Color(0xFFBE3B3B);
  static const dangerSoft = Color(0x14BE3B3B);

  static const surface = Color(0xFFFFFFFF);
  static const background = Color(0xFFF7F8FA);

  static const textPrimary = Color(0xFF18202F);
  static const textSecondary = Color(0xFF667085);
  static const textMuted = Color(0xFF98A2B3);

  static const border = Color(0xFFE4E7EC);
}

class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    return _build(
      brightness: Brightness.light,
      scaffold: const Color(0xFFF7F8FA),
      surface: const Color(0xFFFFFFFF),
      surfaceSecondary: const Color(0xFFF2F4F7),
      text: const Color(0xFF18202F),
      secondaryText: const Color(0xFF667085),
      outline: const Color(0xFFE4E7EC),
    );
  }

  static ThemeData get dark {
    return _build(
      brightness: Brightness.dark,
      scaffold: const Color(0xFF0F1115),
      surface: const Color(0xFF171A20),
      surfaceSecondary: const Color(0xFF20242C),
      text: const Color(0xFFF2F4F7),
      secondaryText: const Color(0xFFA6AFBD),
      outline: const Color(0xFF303641),
    );
  }

  static ThemeData _build({
    required Brightness brightness,
    required Color scaffold,
    required Color surface,
    required Color surfaceSecondary,
    required Color text,
    required Color secondaryText,
    required Color outline,
  }) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: brightness,
        ).copyWith(
          primary: AppColors.primary,
          surface: surface,
          surfaceContainer: surfaceSecondary,
          surfaceContainerLow: surfaceSecondary,
          surfaceContainerHighest: surfaceSecondary,
          outline: outline,
          outlineVariant: outline,
          error: AppColors.danger,
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
    );

    return base.copyWith(
      scaffoldBackgroundColor: scaffold,
      canvasColor: scaffold,

      textTheme: base.textTheme.copyWith(
        headlineLarge: base.textTheme.headlineLarge?.copyWith(
          color: text,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          height: 1.15,
          letterSpacing: -0.8,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          color: text,
          fontSize: 27,
          fontWeight: FontWeight.w700,
          height: 1.2,
          letterSpacing: -0.5,
        ),
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          color: text,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          height: 1.25,
          letterSpacing: -0.3,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          color: text,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          color: text,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          color: text,
          fontSize: 15,
          height: 1.5,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          color: secondaryText,
          fontSize: 14,
          height: 1.5,
        ),
        bodySmall: base.textTheme.bodySmall?.copyWith(
          color: secondaryText,
          fontSize: 12,
          height: 1.45,
        ),
      ),

      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 60,
        backgroundColor: scaffold,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: TextStyle(color: secondaryText, fontSize: 14),
        hintStyle: TextStyle(color: secondaryText.withAlpha(180), fontSize: 14),
        helperStyle: TextStyle(color: secondaryText, fontSize: 12),
        prefixIconColor: secondaryText,
        suffixIconColor: secondaryText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: outline),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: outline,
          disabledForegroundColor: secondaryText,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: BorderSide(color: outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: text),
      ),

      dividerTheme: DividerThemeData(color: outline, thickness: 1, space: 1),

      listTileTheme: ListTileThemeData(
        iconColor: secondaryText,
        textColor: text,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),

      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }

          return null;
        }),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }

          return null;
        }),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: brightness == Brightness.dark
            ? const Color(0xFF252A33)
            : const Color(0xFF18202F),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
