import 'package:flutter/material.dart';
import 'package:limitless_app/config/keys.dart';
import 'package:limitless_app/models/lifelog_model.dart';
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

      initialRoute: supabase.auth.currentSession == null ? '/login' : '/home',

      routes: {
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const MainLayout(),
        '/lifelog': (_) => const LifelogScreen(),
        '/chat': (_) => const ChatScreen(),
        '/calendar': (_) => const CalendarScreen(),
        '/transcriptDetail': (_) => const TranscriptDetailScreen(),
      },

      onGenerateRoute: (settings) {
        if (settings.name == '/transcription') {
          final lifelog = settings.arguments as Lifelog;
          return MaterialPageRoute(
            builder: (_) => TranscriptScreen(lifelog: lifelog),
            settings: settings,
          );
        }

        return null;
      },
    );
  }
}
