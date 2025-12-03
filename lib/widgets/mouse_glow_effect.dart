import 'package:flutter/material.dart';

class MouseGlowEffect extends StatefulWidget {
  final Widget child;
  const MouseGlowEffect({super.key, required this.child});

  @override
  State<MouseGlowEffect> createState() => _MouseGlowEffectState();
}

class _MouseGlowEffectState extends State<MouseGlowEffect> {
  // Posizione del mouse (inizialmente fuori schermo)
  Offset _mousePos = const Offset(-1000, -1000);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      // 1. Ascolta il movimento del mouse
      onHover: (event) {
        setState(() {
          _mousePos = event.position;
        });
      },
      // 2. Stack: Fondo (luce) + Contenuto sopra
      child: Stack(
        children: [
          // Sfondo base (bianco o grigio chiarissimo)
          Container(color: Colors.white),

          // L'effetto Luce (CustomPainter per prestazioni massime)
          CustomPaint(
            painter: _GlowPainter(_mousePos),
            size: Size.infinite,
          ),

          // Il contenuto vero e proprio della pagina (trasparente)
          widget.child,
        ],
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  final Offset position;

  _GlowPainter(this.position);

  @override
  void paint(Canvas canvas, Size size) {
    // Definiamo il gradiente radiale (la luce)
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          // Colore centrale (la luce): Viola/Blu trasparente
          Colors.deepPurple.withOpacity(0.15), 
          // Colore esterno: Trasparente (sfuma nel nulla)
          Colors.transparent, 
        ],
        stops: const [0.0, 0.6], // Raggio della sfumatura
      ).createShader(
        Rect.fromCircle(center: position, radius: 300), // Raggio grande (300px)
      );

    // Disegna un rettangolo grande quanto lo schermo con questo gradiente
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_GlowPainter oldDelegate) {
    return oldDelegate.position != position; // Ridisegna solo se il mouse si muove
  }
}