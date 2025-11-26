import 'package:flutter/material.dart';
import 'package:limitless_app/config/keys.dart';
import 'package:limitless_app/ui/auth/login_screen.dart';
import 'package:limitless_app/ui/main_layout.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Limitless",
      theme: ThemeData(
        fontFamily: "SF",
        scaffoldBackgroundColor: Colors.white,
      ),

      // 🔥 QUI scegliamo cosa mostrare all'avvio
      home: supabase.auth.currentSession == null
          ? const LoginScreen()      // utente non loggato → login
          : const MainLayout(),      // utente loggato → app principale

      
    );
  }
}
