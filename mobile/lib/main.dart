import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/di.dart';

void main() {
  runApp(ProviderScope(overrides: appProviderOverrides, child: const App()));
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Mantenimiento',
      routerConfig: router,
      theme: _buildTheme(),
      debugShowCheckedModeBanner: false,
    );
  }

  ThemeData _buildTheme() {
    const primary = Color(0xFF6338E8);
    const tertiary = Color(0xFF31D0AA);
    const neutral = Color(0xFF1D1D1F);

    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        tertiary: tertiary,
        onPrimary: Colors.white,
      ),
      useMaterial3: true,
    );

    return base.copyWith(
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
        bodyColor: neutral,
        displayColor: neutral,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: neutral,
        ),
        iconTheme: const IconThemeData(color: neutral),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
