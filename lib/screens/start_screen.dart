import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';
import 'dart:math';
import '../utils/sound_manager.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> with TickerProviderStateMixin {
  // Use sound manager instead of direct audio player
  final _soundManager = SoundManager();
  bool _isMusicPlaying = false;
  
  // Animation controllers for animations
  late AnimationController _bounceController;
  late AnimationController _spinController;
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    
    // Ensure home music is playing (but don't restart if already playing)
    _soundManager.ensureHomeMusic();
    
    // Get current sound state from manager
    _isMusicPlaying = _soundManager.isMusicEnabled;
    
    // Initialize animations
    _bounceController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _spinController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 4000),
    )..repeat();
    
    _floatController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    // Only dispose animation controllers, sound manager handles audio
    _bounceController.dispose();
    _spinController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          // Colorful gradient background - made brighter for kids
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade300,
              Colors.lightBlue.shade200,
              Colors.cyan.shade100,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Just a few decorative clouds for a cleaner look
            Positioned(
              top: 50,
              left: 30,
              child: _buildCloud(100, Colors.white),
            ),
            Positioned(
              top: 80,
              right: 50,
              child: _buildCloud(120, Colors.white),
            ),
            
            // Reduced number of math balloons - just 5 carefully placed ones
            ..._buildStrategicBalloons(),
            
            // Just a few stars
            ..._buildStrategicStars(),
            
            // Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title with glow effect
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.yellow.withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Animated title
                        AnimatedBuilder(
                          animation: _spinController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: (_spinController.value * 0.1) - 0.05,
                              child: Text(
                                'Math Magic',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,
                                  shadows: [
                                    Shadow(
                                      color: Colors.blue.shade700,
                                      offset: Offset(2, 2),
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Fun with Numbers!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: Colors.deepPurple,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 60),
                  
                  // Play button
                  _buildAnimatedButton(
                    text: 'Play',
                    icon: Icons.play_arrow_rounded,
                    color: Colors.green.shade600,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _soundManager.playButtonSound();
                      
                      try {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => HomeScreen()),
                        );
                      } catch (e) {
                        print("Navigation error: $e");
                        Navigator.pushReplacementNamed(context, '/home');
                      }
                    },
                  ),
                  SizedBox(height: 20),
                  
                  // Sound toggle button
                  _buildAnimatedButton(
                    text: _isMusicPlaying ? 'Sound: ON' : 'Sound: OFF',
                    icon: _isMusicPlaying ? Icons.volume_up : Icons.volume_off,
                    color: Colors.orange.shade600,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _soundManager.playButtonSound();
                      _soundManager.toggleMusic();
                      
                      setState(() {
                        _isMusicPlaying = _soundManager.isMusicEnabled;
                      });
                    },
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Quit button
                  _buildAnimatedButton(
                    text: 'Quit',
                    icon: Icons.exit_to_app,
                    color: Colors.red.shade600,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _soundManager.playButtonSound();
                      
                      Future.delayed(Duration(milliseconds: 300), () {
                        SystemNavigator.pop(); // Exit the app
                      });
                    },
                  ),
                ],
              ),
            ),
            
            // Bouncing math icons at bottom - kept for visual interest
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBouncingIcon(Icons.add_circle, Colors.green, 0),
                  _buildBouncingIcon(Icons.remove_circle, Colors.red, 0.2),
                  _buildBouncingIcon(Icons.calculate, Colors.purple, 0.4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to create strategically placed balloons
  List<Widget> _buildStrategicBalloons() {
    // Just a few balloons in specific locations
    final List<Map<String, dynamic>> balloonConfigs = [
      {'symbol': '+', 'color': Colors.red.shade300, 'left': 50.0, 'top': 130.0},
      {'symbol': '=', 'color': Colors.blue.shade300, 'right': 60.0, 'top': 180.0},
      {'symbol': '×', 'color': Colors.purple.shade300, 'left': 200.0, 'top': 50.0},
      {'symbol': '3', 'color': Colors.pink.shade300, 'right': 40.0, 'top': 80.0},
      {'symbol': '÷', 'color': Colors.amber.shade400, 'left': 30.0, 'top': 250.0},
    ];
    
    return balloonConfigs.map((config) {
      return Positioned(
        left: config['left'],
        right: config['right'],
        top: config['top'],
        bottom: config['bottom'],
        child: AnimatedBuilder(
          animation: _floatController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _floatController.value * 15),
              child: Column(
                children: [
                  // Balloon - slightly larger than before
                  Container(
                    width: 50,
                    height: 60,
                    decoration: BoxDecoration(
                      color: config['color'],
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 3,
                          offset: Offset(1, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        config['symbol'],
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Balloon string
                  Container(
                    height: 25,
                    width: 2,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            );
          }
        ),
      );
    }).toList();
  }
  
  // Helper method to create strategically placed stars
  List<Widget> _buildStrategicStars() {
    // Just a few stars in specific locations
    final List<Map<String, dynamic>> starConfigs = [
      {'size': 18.0, 'left': 40.0, 'top': 40.0},
      {'size': 15.0, 'right': 50.0, 'top': 30.0},
      {'size': 20.0, 'left': 80.0, 'bottom': 120.0},
      {'size': 12.0, 'right': 70.0, 'bottom': 100.0},
      {'size': 16.0, 'left': 150.0, 'top': 80.0},
      {'size': 14.0, 'right': 120.0, 'top': 130.0},
    ];
    
    return starConfigs.map((config) {
      return Positioned(
        left: config['left'],
        right: config['right'],
        top: config['top'],
        bottom: config['bottom'],
        child: AnimatedBuilder(
          animation: _spinController,
          builder: (context, child) {
            final offset = _spinController.value;
            return Opacity(
              opacity: 0.3 + (offset * 0.7),
              child: Icon(
                Icons.star,
                color: Colors.yellow.shade400,
                size: config['size'],
              ),
            );
          }
        ),
      );
    }).toList();
  }

  Widget _buildBouncingIcon(IconData icon, Color color, double delay) {
    return AnimatedBuilder(
      animation: _bounceController,
      builder: (context, child) {
        final value = _bounceController.value;
        // Apply delay to the animation
        final delayedValue = ((value + delay) % 1.0);
        // Map the value to a bounce curve
        final bounceHeight = -sin(delayedValue * 3.14) * 15;
        
        return Transform.translate(
          offset: Offset(0, bounceHeight),
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.8),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 35,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 500),
        builder: (context, double value, child) {
          return Transform.scale(
            scale: 0.9 + (0.1 * value),
            child: Container(
              width: 200,
              padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.6),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 28),
                  SizedBox(width: 10),
                  Text(
                    text,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildCloud(double size, Color color) {
    return Container(
      width: size,
      height: size * 0.6,
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(size / 2),
      ),
    );
  }
}