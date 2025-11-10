import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Retrieves the screen height for an adaptive layout
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset( 
              'assets/images/logo.png', 
              height: screenHeight * 0.2, // Image height scaled to 20% of screen height
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome!', 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 32),
            const TextField(
              decoration: InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
              
                Navigator.pushReplacementNamed(context, '/home');
              },
              child: const Text('Log in'),
            ),
          ],
        ),
      ),
    );
  }
}