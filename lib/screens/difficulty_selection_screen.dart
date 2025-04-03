import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../utils/sound_manager.dart';

class DifficultySelectionScreen extends StatefulWidget {
  final String gameName;
  final Function(String) onDifficultySelected;
  final Color themeColor;
  final String icon;

  const DifficultySelectionScreen({
    super.key,
    required this.gameName,
    required this.onDifficultySelected,
    required this.themeColor,
    required this.icon,
  });

  @override
  State<DifficultySelectionScreen> createState() => _DifficultySelectionScreenState();
}

class _DifficultySelectionScreenState extends State<DifficultySelectionScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int _selectedCard = -1;
  final bool _showConfetti = false;
  final _soundManager = SoundManager();

  @override
  void initState() {
    super.initState();
    
    // Ensure home music is playing (but don't restart if already playing)
    _soundManager.ensureHomeMusic();
    
    // Animation controller initialization...
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _playSelectSound() {
    _soundManager.playButtonSound();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          '${widget.gameName} - Choose Level',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: widget.themeColor.withOpacity(0.7),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background with pattern
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  widget.themeColor.withOpacity(0.7), 
                  widget.themeColor.withOpacity(0.3)
                ],
              ),
            ),
            child: CustomPaint(
              painter: BackgroundPatternPainter(widget.themeColor),
              child: Container(),
            ),
          ),
          
          // Animated decorative elements
          ..._buildDecorations(),
          
          // Main content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Bouncing title
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _animationController.value * -8),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 25, 
                            vertical: 15
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Select Difficulty',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: widget.themeColor.withOpacity(0.8),
                                  shadows: [
                                    Shadow(
                                      blurRadius: 2.0,
                                      color: Colors.black12,
                                      offset: Offset(1.0, 1.0),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.icon,
                                    style: TextStyle(
                                      fontSize: 24,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    widget.gameName,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  ),
                  
                  SizedBox(height: 40),
                  
                  // Difficulty cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildAnimatedDifficultyCard(
                          context,
                          'Easy',
                          '😊 Perfect for beginners',
                          'Small numbers, more hints',
                          Colors.green.shade400,
                          0,
                          () {
                            _selectDifficulty(0, 'easy');
                          },
                        ),
                        SizedBox(height: 20),
                        _buildAnimatedDifficultyCard(
                          context,
                          'Medium',
                          '🧠 A good challenge',
                          'Larger numbers, fewer hints',
                          Colors.orange.shade400,
                          1,
                          () {
                            _selectDifficulty(1, 'medium');
                          },
                        ),
                        SizedBox(height: 20),
                        _buildAnimatedDifficultyCard(
                          context,
                          'Hard',
                          '🔥 Only for math wizards!',
                          'Big numbers, time limits',
                          Colors.red.shade400,
                          2,
                          () {
                            _selectDifficulty(2, 'hard');
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 40),
                  
                  // Go back button with animation
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 500),
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: 0.9 + (0.1 * value),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white30,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextButton.icon(
                            onPressed: () {
                              _playSelectSound();
                              Navigator.pop(context);
                            },
                            icon: Icon(
                              Icons.arrow_back_rounded, 
                              color: Colors.white, 
                              size: 26
                            ),
                            label: Text(
                              'Go Back',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20, 
                                vertical: 10
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // Confetti effect when selecting a difficulty
          if (_showConfetti) _buildConfetti(),
        ],
      ),
    );
  }
  
  void _selectDifficulty(int cardIndex, String difficulty) {
    setState(() {
      _selectedCard = cardIndex;
    });
    
    HapticFeedback.mediumImpact();
    _playSelectSound();
    
    // Slight delay to show animation before moving to next screen
    Future.delayed(Duration(milliseconds: 500), () {
      widget.onDifficultySelected(difficulty);
    });
  }

  Widget _buildAnimatedDifficultyCard(
    BuildContext context, 
    String level, 
    String emoji,
    String details,
    Color color, 
    int index,
    VoidCallback onPressed
  ) {
    final isSelected = _selectedCard == index;
    
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 50),
          child: Opacity(
            opacity: value,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 110,
              child: Stack(
                children: [
                  // Card
                  Positioned.fill(
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      transform: isSelected 
                          ? (Matrix4.identity()..scale(1.05))
                          : Matrix4.identity(),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color,
                            color.withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(isSelected ? 0.8 : 0.4),
                            blurRadius: isSelected ? 15 : 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onPressed,
                          splashColor: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Row(
                              children: [
                                // Emoji container
                                Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: Colors.white30,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white54,
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _getDifficultyEmoji(level),
                                      style: TextStyle(fontSize: 36),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 15),
                                // Text content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        level,
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        emoji,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                      Text(
                                        details,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Stars for each difficulty level
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Row(
                      children: List.generate(
                        _getDifficultyStars(level),
                        (i) => Icon(
                          Icons.star,
                          color: Colors.yellow.shade300,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  int _getDifficultyStars(String level) {
    switch (level.toLowerCase()) {
      case 'easy':
        return 1;
      case 'medium':
        return 2;
      case 'hard':
        return 3;
      default:
        return 0;
    }
  }

  String _getDifficultyEmoji(String level) {
    switch (level.toLowerCase()) {
      case 'easy':
        return '😊';
      case 'medium':
        return '🧠';
      case 'hard':
        return '🔥';
      default:
        return '❓';
    }
  }
  
  List<Widget> _buildDecorations() {
    final size = MediaQuery.of(context).size;
    return [
      // Top left decoration
      Positioned(
        top: 70,
        left: -20,
        child: _buildFloatingShape(
          Colors.white.withOpacity(0.2),
          80,
          4,
        ),
      ),
      
      // Bottom right decoration
      Positioned(
        bottom: 50,
        right: -30,
        child: _buildFloatingShape(
          Colors.white.withOpacity(0.2),
          100,
          6,
        ),
      ),
      
      // Bottom left small decoration
      Positioned(
        bottom: size.height * 0.2,
        left: 30,
        child: _buildFloatingShape(
          Colors.white.withOpacity(0.15),
          60,
          3,
        ),
      ),
      
      // Game-specific decoration in top right
      Positioned(
        top: size.height * 0.15,
        right: 20,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _animationController.value * 10),
              child: Container(
                padding: EdgeInsets.all(15),
                height: 70,
                width: 70,
                decoration: BoxDecoration(
                  color: widget.themeColor.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    widget.icon,
                    style: TextStyle(fontSize: 30),
                  ),
                ),
              ),
            );
          }
        ),
      ),
    ];
  }
  
   Widget _buildFloatingShape(Color color, double size, int sides) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _animationController.value * 0.3,
          child: Container(
            height: size,
            width: size,
            decoration: BoxDecoration(
              color: color,
              // Only set borderRadius for rectangles, not for circles
              borderRadius: sides == 4 ? BorderRadius.circular(10) : null,
              // If sides is 4, make a rounded square, otherwise circle
              shape: sides == 4 ? BoxShape.rectangle : BoxShape.circle,
            ),
          ),
        );
      }
    );
  }
  
  Widget _buildConfetti() {
    return IgnorePointer(
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: CustomPaint(
          painter: ConfettiPainter(),
        ),
      ),
    );
  }
}

// Pattern painter for the background
class BackgroundPatternPainter extends CustomPainter {
  final Color baseColor;
  
  BackgroundPatternPainter(this.baseColor);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.fill;
    
    final random = math.Random(42); // Fixed seed for consistency
    
    // Draw some random circles in the background
    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 5 + random.nextDouble() * 20;
      
      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Confetti effect painter
class ConfettiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random();
    final paint = Paint()
      ..style = PaintingStyle.fill;
    
    // Draw confetti pieces
    for (int i = 0; i < 100; i++) {
      // Randomize colors
      switch (random.nextInt(5)) {
        case 0:
          paint.color = Colors.red.shade300;
          break;
        case 1:
          paint.color = Colors.blue.shade300;
          break;
        case 2:
          paint.color = Colors.green.shade300;
          break;
        case 3:
          paint.color = Colors.yellow.shade300;
          break;
        case 4:
          paint.color = Colors.purple.shade300;
          break;
      }
      
      // Randomize position
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final confettiSize = 5 + random.nextDouble() * 5;
      
      // Draw different shapes
      if (random.nextBool()) {
        // Rectangle
        canvas.drawRect(
          Rect.fromLTWH(x, y, confettiSize, confettiSize * 2),
          paint,
        );
      } else {
        // Circle
        canvas.drawCircle(
          Offset(x, y),
          confettiSize,
          paint,
        );
      }
    }
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}