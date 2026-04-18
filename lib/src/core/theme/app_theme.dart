import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  static const _sand = Color(0xFFF5EFE3);
  static const _ink = Color(0xFF14213D);
  static const _mist = Color(0xFFE7E1D6);
  static const _teal = Color(0xFF16B6B0);
  static const _coral = Color(0xFFFF6B4A);
  static const _slate = Color(0xFF24324A);
  static const _leaf = Color(0xFF4F8A5B);

  static ThemeData lightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _ink,
      brightness: Brightness.light,
    ).copyWith(
      primary: _ink,
      secondary: _teal,
      tertiary: _coral,
      surface: Colors.white,
      surfaceTint: Colors.white,
      error: const Color(0xFFB42318),
    );

    final baseTextTheme = GoogleFonts.spaceGroteskTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _sand,
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.spaceGrotesk(
          fontSize: 56,
          fontWeight: FontWeight.w700,
          letterSpacing: -2,
          color: _ink,
        ),
        displaySmall: GoogleFonts.spaceGrotesk(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.2,
          color: _ink,
        ),
        headlineMedium: GoogleFonts.spaceGrotesk(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: _ink,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: _ink,
        ),
        bodyLarge: GoogleFonts.spaceGrotesk(
          fontSize: 16,
          height: 1.35,
          color: _slate,
        ),
        bodyMedium: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          height: 1.45,
          color: _slate,
        ),
        labelLarge: GoogleFonts.ibmPlexMono(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: _slate,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: _ink,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: _ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withOpacity(0.92),
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: _mist),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: Colors.white,
        selectedColor: _ink,
        secondarySelectedColor: _ink,
        side: BorderSide(color: _mist),
        labelStyle: GoogleFonts.ibmPlexMono(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _slate,
        ),
        secondaryLabelStyle: GoogleFonts.ibmPlexMono(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: GoogleFonts.spaceGrotesk(color: _slate.withOpacity(0.6)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: _mist),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: _mist),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: _teal, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _ink,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _ink,
          side: BorderSide(color: _mist),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      dividerColor: _mist,
      iconTheme: const IconThemeData(color: _ink),
      extensions: const <ThemeExtension<dynamic>>[
        SprintBoardPalette(
          shell: _ink,
          shellMuted: _slate,
          surfaceAlt: _mist,
          accent: _teal,
          accentWarm: _coral,
          success: _leaf,
        ),
      ],
    );
  }
}

@immutable
class SprintBoardPalette extends ThemeExtension<SprintBoardPalette> {
  const SprintBoardPalette({
    required this.shell,
    required this.shellMuted,
    required this.surfaceAlt,
    required this.accent,
    required this.accentWarm,
    required this.success,
  });

  final Color shell;
  final Color shellMuted;
  final Color surfaceAlt;
  final Color accent;
  final Color accentWarm;
  final Color success;

  @override
  SprintBoardPalette copyWith({
    Color? shell,
    Color? shellMuted,
    Color? surfaceAlt,
    Color? accent,
    Color? accentWarm,
    Color? success,
  }) {
    return SprintBoardPalette(
      shell: shell ?? this.shell,
      shellMuted: shellMuted ?? this.shellMuted,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      accent: accent ?? this.accent,
      accentWarm: accentWarm ?? this.accentWarm,
      success: success ?? this.success,
    );
  }

  @override
  SprintBoardPalette lerp(ThemeExtension<SprintBoardPalette>? other, double t) {
    if (other is! SprintBoardPalette) {
      return this;
    }

    return SprintBoardPalette(
      shell: Color.lerp(shell, other.shell, t) ?? shell,
      shellMuted: Color.lerp(shellMuted, other.shellMuted, t) ?? shellMuted,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t) ?? surfaceAlt,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      accentWarm: Color.lerp(accentWarm, other.accentWarm, t) ?? accentWarm,
      success: Color.lerp(success, other.success, t) ?? success,
    );
  }
}
