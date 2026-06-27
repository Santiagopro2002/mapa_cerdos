import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'screen/cliente/cliente_form_screen.dart';
import 'screen/cliente/cliente_screen.dart';
import 'screen/mapa/mapa_entregas_screen.dart';
import 'settings/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Entregas de Chancho',
      initialRoute: '/',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primary,
          centerTitle: true,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
      routes: {
        '/': (context) => const HomeScreen(),
        '/clientes': (context) => const ClienteScreen(),
        '/clientes/form': (context) => const ClienteFormScreen(),
        '/mapa': (context) => const MapaEntregasScreen(),
      },
    );
  }
}
