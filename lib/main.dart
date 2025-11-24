import 'package:flutter/material.dart';
import 'screens/auth_check.dart';  
import 'screens/welcome_screen.dart';     
import 'screens/login_screen.dart';      
import 'screens/dashboard_screen.dart';   
import 'screens/inventario_screen.dart';
import 'screens/promociones_screen.dart';
import 'screens/reportes_screen.dart';
void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Surprise App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
      ),

      home: const AuthCheckScreen(),

      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/auth': (context) => const LoginScreen(),
        '/dashboard': (context) =>
            const DashboardScreen(userName: 'Usuario'),
        '/inventario': (context) => const InventarioScreen(),
        '/promociones': (context) => const PromocionesScreen(),
        '/reportes': (context) => const ReportesScreen(),
      },
    );
  }
}
