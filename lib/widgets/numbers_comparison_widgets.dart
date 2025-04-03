import 'package:flutter/material.dart';
import 'dart:math';

// A utility extension to capitalize the first letter of a string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

// Get the appropriate color for a difficulty level
Color getDifficultyColor(String difficulty) {
  switch (difficulty.toLowerCase()) {
    case 'easy':
      return Colors.green;
    case 'medium':
      return Colors.orange;
    case 'hard':
      return Colors.red;
    default:
      return Colors.blue;
  }
}

// Widget for the transition indicator between rounds
Widget buildTransitionIndicator(VoidCallback onComplete) {
  // Start a delayed action to move to the next round
  Future.delayed(Duration(milliseconds: 1500), () {
    onComplete();
  });
  
  return Container(
    padding: EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.blue.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.blue.withValues(alpha: 0.5),
        width: 2,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
        SizedBox(width: 15),
        Text(
          'Next Round Coming...',
          style: TextStyle(
            color: Colors.blue.shade800,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    ),
  );
}

// Widget for information rows in the instructions dialog
Widget buildInfoRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
        ),
        SizedBox(width: 5),
        Text(
          value,
          style: TextStyle(fontSize: 15),
        ),
      ],
    ),
  );
}

// Widget for background decorative elements
List<Widget> buildBackgroundElements(BuildContext context) {
  final size = MediaQuery.of(context).size;
  return [
    // Top left decorative math symbol
    Positioned(
      top: 20,
      left: 10,
      child: Opacity(
        opacity: 0.2,
        child: Transform.rotate(
          angle: -0.2,
          child: Text(
            '+',
            style: TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    ),
    
    // Bottom right decorative math symbol
    Positioned(
      bottom: 30,
      right: 20,
      child: Opacity(
        opacity: 0.2,
        child: Transform.rotate(
          angle: 0.3,
          child: Text(
            '×',
            style: TextStyle(
              fontSize: 100,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    ),
    
    // Center back decorative math symbol
    Positioned(
      top: size.height * 0.4,
      left: size.width * 0.35,
      child: Opacity(
        opacity: 0.1,
        child: Text(
          '=',
          style: TextStyle(
            fontSize: 120,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    ),
    
    // Top right bubble decoration
    Positioned(
      top: 40,
      right: 20,
      child: Opacity(
        opacity: 0.2,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
      ),
    ),
    
    // Bottom left bubble decoration
    Positioned(
      bottom: 60,
      left: 30,
      child: Opacity(
        opacity: 0.2,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
      ),
    ),
  ];
}

// Widget for game over celebration elements
List<Widget> buildGameOverDecoration(BuildContext context) {
  final List<Widget> decorations = [];
  final size = MediaQuery.of(context).size;
  final random = Random();
  
  // Add several floating shapes with staggered animations
  for (int i = 0; i < 20; i++) {
    final double left = random.nextDouble() * size.width;
    final double top = random.nextDouble() * size.height;
    final double shapeSize = 10 + random.nextDouble() * 30;
    final color = [
      Colors.red.shade300,
      Colors.blue.shade300,
      Colors.green.shade300,
      Colors.yellow.shade300,
      Colors.purple.shade300,
    ][random.nextInt(5)];
    
    // Define the shape first to use it consistently
    final isCircle = random.nextBool();
    final BoxShape shapeType = isCircle ? BoxShape.circle : BoxShape.rectangle;
    
    decorations.add(
      Positioned(
        left: left,
        top: top,
        child: TweenAnimationBuilder(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 1000 + i * 100),
          builder: (context, double value, child) {
            return Opacity(
              opacity: value * 0.7,
              child: Transform.translate(
                offset: Offset(0, (1 - value) * 50),
                child: Container(
                  width: shapeSize,
                  height: shapeSize,
                  decoration: BoxDecoration(
                    color: color,
                    shape: shapeType,
                    // Only apply borderRadius if it's a rectangle
                    borderRadius: !isCircle ? BorderRadius.circular(5) : null,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  return decorations;
}

// Create a pulsing highlight effect for correct answers
Widget buildPulsingHighlight(Widget child) {
  return TweenAnimationBuilder(
    tween: Tween<double>(begin: 0.9, end: 1.1),
    duration: Duration(milliseconds: 700),
    curve: Curves.easeInOut,
    builder: (context, double value, _) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.yellow.withValues(alpha: 0.3 * value),
              spreadRadius: 10 * value,
              blurRadius: 15 * value,
            ),
          ],
        ),
        child: child,
      );
    },
  );
}

// Create a bouncing button effect
Widget buildBouncingButton({
  required VoidCallback onTap,
  required Widget child,
  Color color = Colors.blue,
  EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  BorderRadius borderRadius = const BorderRadius.all(Radius.circular(15)),
}) {
  return TweenAnimationBuilder(
    tween: Tween<double>(begin: 0, end: 1),
    duration: Duration(milliseconds: 300),
    builder: (context, double value, _) {
      return GestureDetector(
        onTap: onTap,
        child: Transform.scale(
          scale: 1.0 + (0.05 * sin(value * 3 * 3.14159)),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: color,
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: child,
          ),
        ),
      );
    },
  );
}

// Animated text that scales in
Widget buildAnimatedText(String text, {
  double fontSize = 24,
  FontWeight fontWeight = FontWeight.bold,
  Color color = Colors.white,
  Duration duration = const Duration(milliseconds: 800),
}) {
  return TweenAnimationBuilder(
    tween: Tween<double>(begin: 0.0, end: 1.0),
    duration: duration,
    curve: Curves.elasticOut,
    builder: (context, double value, _) {
      return Opacity(
        opacity: value,
        child: Transform.scale(
          scale: value,
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: color,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 5,
                  offset: Offset(2, 2),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}