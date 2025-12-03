import 'package:flutter/material.dart';
import 'package:limitless_app/ui/chat/chat_screen.dart';
import 'package:limitless_app/ui/home/home_screen.dart';
import 'package:limitless_app/ui/transcript/lifelog_screen.dart';
import 'package:limitless_app/ui/messages/messages_list_screen.dart';
import 'package:limitless_app/widgets/custom_buttom_nav.dart';
import 'package:limitless_app/ui/profile/profile_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> pages = [
    const HomeScreen(),            
    const LifelogScreen(),         
    const ChatScreen(),            
    const MessagesListScreen(),    
    const ProfileScreen(),         
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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

      floatingActionButton: Container(
        height: 58.0, 
        width: 58.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF3366FF), Color(0xFF8844FF), Color(0xFFFFAA00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3), 
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 4), 
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            setState(() {
              _selectedIndex = 2;
            });
          },
          backgroundColor: Colors.transparent,
          elevation: 0, 
          highlightElevation: 0,
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}