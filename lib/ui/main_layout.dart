import 'package:flutter/material.dart';
// ... assicurati che gli altri import ci siano ...
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
    const HomeScreen(),            // Index 0
    const LifelogScreen(),         // Index 1
    const ChatScreen(),            // Index 2 (AI)
    const MessagesListScreen(),    // Index 3
    const ProfileScreen(),         // Index 4
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

      // --- AGGIUNGI QUESTO BLOCCO ---
      floatingActionButton: Container(
        height: 58.0, // Un po' più grande del normale per enfasi
        width: 58.0,
        // Decorazione per l'effetto 3D e il gradiente stile Meta AI
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            // Colori ispirati all'anello dell'immagine che hai mandato (Blu -> Viola -> Giallo/Arancio)
            colors: [Color(0xFF3366FF), Color(0xFF8844FF), Color(0xFFFFAA00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3), // Ombra scura per il rilievo 3D
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 4), // Sposta l'ombra in basso
            ),
          ],
        ),
        // Il bottone vero e proprio
        child: FloatingActionButton(
          onPressed: () {
            // Quando premuto, cambia il tab all'indice 2 (Chat AI)
            setState(() {
              _selectedIndex = 2;
            });
          },
          // Rendiamo il FAB trasparente per mostrare il gradiente del Container sotto
          backgroundColor: Colors.transparent,
          elevation: 0, // Disabilitiamo l'ombra nativa del FAB perché usiamo quella del Container
          highlightElevation: 0,
          // L'icona "scintilla" o AI al centro
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
        ),
      ),
      // Opzionale: puoi spostarlo leggermente più in alto se copre troppo la barra in basso
      // floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      // ------------------------------
    );
  }
}