import 'package:flutter/material.dart';
import 'package:limitless_app/config/keys.dart';
import 'package:limitless_app/models/lifelog_model.dart';
import 'package:limitless_app/models/meeting_model.dart'; // <--- AGGIUNTO QUESTO IMPORT
import 'package:limitless_app/ui/auth/login_screen.dart';
import 'package:limitless_app/ui/calendar/calendar_screen.dart';
import 'package:limitless_app/ui/chat/chat_screen.dart';
import 'package:limitless_app/ui/main_layout.dart';
import 'package:limitless_app/ui/transcript/lifelog_screen.dart';
import 'package:limitless_app/ui/transcript/transcripts_screen.dart';
import 'package:limitless_app/ui/transcript/transcript_detail_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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

      // Se l'utente è loggato va alla Home, altrimenti al Login
      initialRoute: supabase.auth.currentSession == null ? '/login' : '/home',

      // Rotte statiche (senza argomenti)
      routes: {
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const MainLayout(),
        '/lifelog': (_) => const LifelogScreen(),
        '/chat': (_) => const ChatScreen(),
        '/calendar': (_) => const CalendarScreen(),
        // Abbiamo rimosso transcriptDetail da qui perché richiede argomenti
      },

      // Rotte dinamiche (con argomenti)
      onGenerateRoute: (settings) {
        
        // Vecchia gestione lifelog (se ti serve ancora)
        if (settings.name == '/transcription') {
          final lifelog = settings.arguments as Lifelog;
          return MaterialPageRoute(
            builder: (_) => TranscriptScreen(lifelog: lifelog),
            settings: settings,
          );
        }

        // --- NUOVA GESTIONE DETTAGLIO MEETING ---
        if (settings.name == '/transcriptDetail') {
          // Recuperiamo l'oggetto Meeting passato come argomento
          final meeting = settings.arguments as Meeting; 
          return MaterialPageRoute(
            builder: (_) => TranscriptDetailScreen(meeting: meeting),
            settings: settings,
          );
        }

        return null;
      },
    );
  }
}