import 'package:flutter/material.dart';



class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Usiamo il SafeArea per non coprire la barra di stato e la notch
    return const Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              _HeaderSection(),
              SizedBox(height: 20),
              
              
              Text(
                'TODAY\'S TODO LIST',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              
              Divider(), 
              SizedBox(height: 20),

             
              Text(
                'OUR SERVICES',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 15),

              
              _ServicesGrid(),
            ],
          ),
        ),
      ),
      // (Floating Action Button)
      floatingActionButton: _FloatingChatButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}


class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'YOUR NAME',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'today: 31 ottobre 2025', 
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        
        
        Container(
          width: 200,
          height: 200,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.purple, Colors.yellow],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            // User icon
            child: Icon(
              Icons.person,
              size: 40,
              color: Colors.white,
              
            ),
          ),
        ),
      ],
    );
  }
}


class _ServiceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Color> colors;

  const _ServiceCard({
    required this.title,
    required this.icon,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (title == 'RECORDINGS AND TRANSCRIPTION') {
          Navigator.pushNamed(context, '/transcription');
        } else if (title == 'CHATBOT') {
          Navigator.pushNamed(context, '/chat');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.last.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            // Icona decorativa
            Align(
              alignment: Alignment.bottomRight,
              child: Icon(
                icon,
                size: 40,
                color: Colors.black.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServicesGrid extends StatelessWidget {
  const _ServicesGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      
      physics: const NeverScrollableScrollPhysics(), 
      shrinkWrap: true,
      crossAxisCount: 2, // 2 colonne
      crossAxisSpacing: 15, // Spazio orizzontale
      mainAxisSpacing: 15, // Spazio verticale
      childAspectRatio: 0.9, 
      children: [
        // Recordings e Trascrizione
        _ServiceCard(
          title: 'RECORDINGS AND TRANSCRIPTION',
          icon: Icons.mic_rounded,
          colors: [
            Colors.purple.shade100,
            Colors.white,
          ],
        ),

        // Summary of the Day (Placeholder)
        _ServiceCard(
          title: 'START RECORDING',
          icon: Icons.lightbulb_outline,
          colors: [
            Colors.blue.shade100,
            Colors.white,
          ],
        ),

        // Chatbot (AI Chat)
        _ServiceCard(
          title: 'CHATBOT',
          icon: Icons.chat_bubble_outline,
          colors: [
            Colors.orange.shade100,
            Colors.white,
          ],
        ),

        // da decidere
        _ServiceCard(
          title: 'xyz',
          icon: Icons.support_agent_rounded,
          colors: [
            Colors.green.shade100,
            Colors.white,
          ],
        ),
      ],
    );
  }
}

class _FloatingChatButton extends StatelessWidget {
  const _FloatingChatButton();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.pushNamed(context, '/chat');
      },
      backgroundColor: const Color(0xFF673AB7), 
      shape: const CircleBorder(),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Colors.purple.shade300, Colors.orange.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Image.asset(
          'assets/images/logo.png', 
          width: 28,
          height: 28,
          
        ),
      ),
    );
  }
}