import 'package:flutter/material.dart';
import 'package:limitless_app/ui/chat/chat_screen.dart'; // Chat AI
import 'package:limitless_app/ui/home/home_screen.dart';
import 'package:limitless_app/ui/transcription/lifelog_screen.dart';
import 'package:limitless_app/ui/messages/messages_list_screen.dart'; // <--- IMPORTANTE: Importa la nuova schermata
import 'package:limitless_app/widgets/custom_buttom_nav.dart'; // Correggi se il nome del file è custom_bottom_nav.dart
import 'package:limitless_app/ui/profile/profile_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  // La lista deve rispettare l'ordine delle icone in CustomBottomNav:
  // 0: Home
  // 1: Record
  // 2: AI (Fulmine)
  // 3: Chat (Fumetto)
  // 4: Profile
  // dentro _MainLayoutState
final List<Widget> pages = const [
  HomeScreen(),            // Index 0
  LifelogScreen(),         // Index 1
  ChatScreen(),            // Index 2 (AI)
  MessagesListScreen(),    // Index 3 (Chat)
  ProfileScreen(),         // Index 4: ORA COLLEGA IL FILE REALE
];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Usiamo IndexedStack per mantenere lo stato delle pagine (così non si ricaricano ogni volta)
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }
}