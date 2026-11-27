import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppTheme {
  // Brand Colors
  static const Color primary = Color(0xFF1E3A8A); // Deep Navy Blue
  static const Color primaryLight = Color(0xFF2563EB); // Royal Blue
  static const Color primaryDark = Color(0xFF0F172A); // Slate Dark
  static const Color accent = Color(0xFFE11D48); // Vyapar Rose / Crimson
  static const Color accentLight = Color(0xFFF43F5E);
  static const Color successGreen = Color(0xFF059669); // Emerald Receivables / Inflow
  static const Color successLight = Color(0xFF10B981);
  static const Color dangerRed = Color(0xFFDC2626); // Crimson Payables / Outflow
  static const Color dangerLight = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFD97706); // Amber Warning
  static const Color warningLight = Color(0xFFF59E0B);
  static const Color purple = Color(0xFF7C3AED); // Royalty Purple
  static const Color purpleLight = Color(0xFF8B5CF6);
  static const Color background = Color(0xFFF8FAFC); // Cool Slate White
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);

  // Modern Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkNavyGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFE11D48), Color(0xFFF43F5E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF047857), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFB91C1C), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient amberGradient = LinearGradient(
    colors: [Color(0xFFB45309), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF6D28D9), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadows
  static const List<BoxShadow> softShadow = [
    BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 3)),
  ];

  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 8)),
  ];

  // Formatters
  static final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
  static final shortCurrency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  static final dateFormat = DateFormat('dd MMM yyyy');
  static final timeFormat = DateFormat('hh:mm a');

  // Modern Card Container Decoration
  static BoxDecoration modernCardDecoration({
    Color backgroundColor = surface,
    Color borderColor = border,
    double borderRadius = 14,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor, width: 1),
      boxShadow: shadows ?? cardShadow,
    );
  }

  // Modern Badge Decoration
  static BoxDecoration badgeDecoration({
    required Color color,
    double borderRadius = 8,
    bool isFilled = false,
  }) {
    return BoxDecoration(
      color: isFilled ? color : color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(borderRadius),
      border: isFilled ? null : Border.all(color: color.withOpacity(0.3), width: 1),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        surface: surface,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      tabBarTheme: const TabBarTheme(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.white,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.3),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.3),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dangerRed, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade100,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: border),
        ),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
      ),
    );
  }
}
