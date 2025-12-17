import 'package:flutter/material.dart';
import 'package:limitless_app/core/services/auth_service.dart';
import 'package:limitless_app/ui/auth/signup_screen.dart';
import 'package:limitless_app/ui/main_layout.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;

  late final Stream<AuthState> _authStream;

  @override
  void initState() {
    super.initState();
    _authStream = Supabase.instance.client.auth.onAuthStateChange;
    
    _authStream.listen((data) {
      if (data.session != null && mounted) {
      }
    });
  }

  Future<void> login() async {
    setState(() => loading = true);
    try {
      final auth = AuthService();
      final res = await auth.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (res.session != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainLayout()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception:', '').trim())),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => loading = true); 
    try {
      final success = await AuthService().signInWithGoogle();

      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainLayout()),
        );
      } else {
        if (mounted) {
           setState(() => loading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Errore Google: $e")),
        );
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 110,
                ),
              ),

              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F1F5),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    hintText: 'Email',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F1F5),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Password',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              GestureDetector(
                onTap: loading ? null : login,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF5F9E), Color(0xFF5F9BFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: loading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text(
                            "Continue",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text("OR", style: TextStyle(color: Colors.grey.shade400)),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity, 
                child: OutlinedButton.icon(
                  onPressed: _googleSignIn, 
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                    side: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5), 
                    backgroundColor: Colors.white,
                    elevation: 0,
                  ),
                  icon: Image.asset(
                    'assets/images/google.png',
                    height: 24, 
                    width: 24,
                  ), 
                  label: const Text(
                    "Sign in with Google",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black87, 
                      fontWeight: FontWeight.w600
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      );
                    },
                    child: const Text(
                      "Sign up",
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}