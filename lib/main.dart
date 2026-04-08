import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// Desktop SQLite (Linux, Windows, macOS)
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// HOME SCREEN
import 'screens/home_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'widgets/responsive_root.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/database.dart';

class MyScrollBehavior extends MaterialScrollBehavior {
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    final isDesktop =
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;

    if (!isDesktop) return child;

    return Scrollbar(
      controller: details.controller,
      thumbVisibility: true,
      child: child,
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop režim (Linux / Windows / macOS)
  if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Android + iOS používajú normálny sqflite → nič netreba inicializovať

  // 🔥 neblokujúci preload databázy
  AppDatabase.instance.database;

  runApp(const ProviderScope(child: ResponsiveRoot(child: EmeramApp())));
}

class EmeramApp extends StatelessWidget {
  const EmeramApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emerám',
      debugShowCheckedModeBanner: false,
      scrollBehavior: MyScrollBehavior(),
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),

      supportedLocales: const [Locale('sk', 'SK'), Locale('en', 'US')],

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      localeResolutionCallback: (locale, supportedLocales) {
        // 1. full match (language + country)
        if (locale == null) return supportedLocales.first;

        for (var supported in supportedLocales) {
          if (supported.languageCode == locale.languageCode &&
              supported.countryCode == locale.countryCode) {
            return supported;
          }
        }

        // 2. language-only match
        for (var supported in supportedLocales) {
          if (supported.languageCode == locale.languageCode) {
            return supported;
          }
        }

        // 3. fallback
        return supportedLocales.first;
      },

      home: const HomeScreen(),
    );
  }
}
