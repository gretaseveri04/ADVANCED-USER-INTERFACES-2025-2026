import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient supabase = Supabase.instance.client;

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
      await supabase.auth.signOut();
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  // All'interno della tua classe AuthService

Future<bool> signInWithGoogle() async {
  try {
    // Modifica la chiamata di login aggiungendo lo scope del calendario
    await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'tuo-schema-app://login-callback', // O il tuo URL di redirect
      scopes: 'https://www.googleapis.com/auth/calendar', // <--- FONDAMENTALE
      // Nota: se usi 'queryParams', access_type=offline serve per il refresh token
      queryParams: {'access_type': 'offline', 'prompt': 'consent'},
    );
    return true;
  } catch (e) {
    print('Errore Login: $e');
    return false;
  }
}
}
