import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.withOpacity(0.2), width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home, "Home", 0),
              _navItem(Icons.mic, "Record", 1),
              
              // Logo centrale
              _navItem("assets/images/logo.png", "AI", 2, isAsset: true),
              
              _navItem(Icons.chat_bubble_outline, "Chat", 3),
              _navItem(Icons.person_outline, "Profile", 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(dynamic icon, String label, int index, {bool isAsset = false}) {
    final bool isActive = index == currentIndex;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque, 
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(8),
            decoration: isActive
                ? const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFB476FF), Color(0xFF7F7CFF)],
                    ),
                    shape: BoxShape.circle,
                  )
                : const BoxDecoration(color: Colors.transparent),
            child: isAsset
                ? Image.asset(
                    icon as String,
                    width: 26, // Stessa grandezza delle icone
                    height: 26,
                    fit: BoxFit.contain,
                    // LOGICA COLORE: 
                    // Se attivo -> Bianco (per contrasto sul viola)
                    // Se inattivo -> Null (mostra i colori originali del logo invece del grigio)
                    color: isActive ? Colors.white : null, 
                  )
                : Icon(
                    icon as IconData,
                    color: isActive ? Colors.white : Colors.grey,
                    size: 26,
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? Colors.purple : Colors.grey,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}