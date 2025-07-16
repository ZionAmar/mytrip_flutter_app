import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/splash_screen.dart';
import 'screens/trips_list_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  initializeDateFormatting('he_IL', null).then((_) {
    runApp(const MyTripApp());
  });
}

class MyTripApp extends StatelessWidget {
  const MyTripApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MyTrip App',

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('he', 'IL'),
      ],
      locale: const Locale('he', 'IL'),

      theme: ThemeData( // Removed 'const' here because some ThemeXxxData aren't const
        primarySwatch: Colors.teal,

        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
          primary: Colors.teal.shade700,
          onPrimary: Colors.white,
          secondary: Colors.orange.shade700,
          onSecondary: Colors.white,
          tertiary: Colors.blue.shade700,
          onTertiary: Colors.white,
          error: Colors.red.shade700,
          onError: Colors.white,
          surface: Colors.white,
          onSurface: Colors.grey.shade900,
          background: Colors.grey.shade100,
          onBackground: Colors.grey.shade900,
        ),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.teal.shade700,
          foregroundColor: Colors.white,
          elevation: 4,
          titleTextStyle: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        // --- FIX START ---
        cardTheme: CardThemeData( // Changed CardTheme to CardThemeData
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        ),
        // --- FIX END ---
        floatingActionButtonTheme: FloatingActionButtonThemeData( // No 'const' needed here
          backgroundColor: Colors.orange.shade700,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData( // No 'const' needed here
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        textButtonTheme: TextButtonThemeData( // No 'const' needed here
          style: TextButton.styleFrom(
            foregroundColor: Colors.teal.shade700,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme( // No 'const' needed here
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.teal.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.orange.shade700, width: 2),
          ),
          labelStyle: TextStyle(color: Colors.grey.shade700),
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIconColor: Colors.grey.shade600,
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        ),
        fontFamily: 'Roboto',
      ),

      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(nextRoute: '/trips'),
        '/trips': (context) => TripsListScreen(),
      },
    );
  }
}