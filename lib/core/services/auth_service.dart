import 'dart:io'; // Serve per riconoscere se siamo su iOS
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final SupabaseClient supabase = Supabase.instance.client;

  static const String _iOSClientId = '457158269786-1tlbj87qdjbp8qelhajciqv4uql4m36d.apps.googleusercontent.com';

  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<AuthResponse> signup({
    required String email,
    required String password,
    required String name,
    required String surname,
    required String birthday,
    required String company,
    required String role,
  }) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'surname': surname,
          'birthday': birthday,
          'company': company,
          'role': role,
        },
      );
      return response;
    } catch (e) {
      throw Exception('Signup failed: $e');
    }
  }

  Future<void> logout() async {
    try {
      // Logout sia da Supabase che da Google per pulire tutto
      await supabase.auth.signOut();
      await GoogleSignIn().signOut();
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  // --- QUESTA È LA FUNZIONE CHE DEVI CAMBIARE ---
  Future<bool> signInWithGoogle() async {
    try {
      // 1. Configurazione Nativa (uguale al CalendarService)
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: Platform.isIOS ? _iOSClientId : null,
        // Richiediamo l'accesso al calendario SUBITO, durante il login
        scopes: ['https://www.googleapis.com/auth/calendar'], 
      );

      // 2. Apre il popup nativo di iOS (niente browser localhost!)
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        return false; // L'utente ha annullato
      }

      // 3. Otteniamo i token di sicurezza da Google
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw 'Nessun token Google trovato.';
      }

      // 4. Passiamo questi token a Supabase
      // Supabase capisce che l'utente è valido e lo logga nel database
      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      return true;
    } catch (e) {
      print('Errore Login Google: $e');
      return false;
    }
  }
}