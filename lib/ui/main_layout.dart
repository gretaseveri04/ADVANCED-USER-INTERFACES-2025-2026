import 'package:flutter/material.dart';
import 'package:limitless_app/ui/chat/chat_screen.dart';
import 'package:limitless_app/ui/home/home_screen.dart';
import 'package:limitless_app/ui/transcription/lifelog_screen.dart';
import 'package:limitless_app/widgets/custom_buttom_nav.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> pages = const [
    HomeScreen(),
    LifelogScreen(),
    //AIScreen(),
    ChatScreen(),
    //ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: pages[_selectedIndex],
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }
}
