import 'package:flutter/material.dart';
import 'number_duel_screen.dart';
import 'number_ladder_screen.dart';
import 'build_number_screen.dart';
import 'difficulty_selection_screen.dart';
import 'start_screen.dart';
import '../utils/sound_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Use sound manager instead of direct audio player
  final _soundManager = SoundManager();
  // Removed _isMusicPlaying variable since we're removing the toggle button
  
  // Animation controllers
  late AnimationController _bounceController;
  late AnimationController _rotateController;
  
  @override
  void initState() {
    super.initState();
    // Use the dedicated method
    _soundManager.playHomeMusic();
    
    // Setup animations
    _bounceController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _rotateController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 8000),
    )..repeat();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Use the updated method to check if home music should be restored
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_soundManager.currentMusic != 'sounds/home_music.mp3') {
        _soundManager.playHomeMusic();
      }
    });
  }
  
  @override
  void dispose() {
    _bounceController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Math Fun Games',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 30),
          onPressed: () {
            // Use sound manager for button sound
            _soundManager.playButtonSound();
            
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => StartScreen()),
            );
          },
        ),
        // Removed the actions section with the volume toggle button
      ),
      body: Container(
        decoration: BoxDecoration(
          // Vibrant background for kids
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.indigo.shade500,
              Colors.purple.shade400, 
              Colors.deepPurple.shade300
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background decorations
            ..._buildBackgroundDecorations(),
            
            // Main content
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title with bounce animation
                    AnimatedBuilder(
                      animation: _bounceController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _bounceController.value * -10),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                            decoration: BoxDecoration(
                              color: Colors.yellow.shade100.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.yellow.shade600.withOpacity(0.5),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Text(
                              'Choose a Fun Game!',
                              style: TextStyle(
                                fontSize: 28, 
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple.shade700,
                              ),
                            ),
                          ),
                        );
                      }
                    ),
                    
                    SizedBox(height: 40),
                    
                    // Game buttons with improved design
                    _buildGameButton(
                      context, 
                      'Number Duel', 
                      '🏁 Compare Numbers', 
                      Colors.red.shade300,
                      Icons.compare_arrows, 
                      () {
                        _soundManager.playButtonSound();
                        _navigateToDifficultySelection(
                          context, 
                          'Number Duel', 
                          Colors.red.shade300,
                          '🏁',
                          (difficulty) => _navigateToNumberDuel(context, difficulty)
                        );
                      }
                    ),
                    
                    SizedBox(height: 20),
                    
                    _buildGameButton(
                      context, 
                      'Balloon Numbers', 
                      '🎈 Order Numbers', 
                      Colors.green.shade300,
                      Icons.bubble_chart, 
                      () {
                        _soundManager.playButtonSound();
                        _navigateToDifficultySelection(
                          context, 
                          'Balloon Numbers', 
                          Colors.green.shade300,
                          '🎈',
                          (difficulty) => _navigateToNumberLadder(context, difficulty)
                        );
                      }
                    ),
                    
                    SizedBox(height: 20),
                    
                    _buildGameButton(
                      context, 
                      'Build a Number', 
                      '🏗️ Compose Numbers', 
                      Colors.orange.shade300,
                      Icons.construction, 
                      () {
                        _soundManager.playButtonSound();
                        _navigateToDifficultySelection(
                          context, 
                          'Build a Number', 
                          Colors.orange.shade300,
                          '🏗️',
                          (difficulty) => _navigateToBuildNumber(context, difficulty)
                        );
                      }
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  List<Widget> _buildBackgroundDecorations() {
    final size = MediaQuery.of(context).size;
    
    return [
      // Rotating sun/star in the corner
      Positioned(
        top: -30,
        right: -30,
        child: AnimatedBuilder(
          animation: _rotateController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotateController.value * 2 * 3.14,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.yellow.shade300,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.yellow.shade600.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade300,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          }
        ),
      ),
      
      // Floating math symbols
      Positioned(
        left: 20,
        top: size.height * 0.2,
        child: _buildFloatingSymbol('+', Colors.pink.shade300, 0),
      ),
      Positioned(
        right: 30,
        top: size.height * 0.35,
        child: _buildFloatingSymbol('-', Colors.green.shade300, 0.3),
      ),
      Positioned(
        left: 40,
        bottom: size.height * 0.30,
        child: _buildFloatingSymbol('×', Colors.amber.shade300, 0.6),
      ),
      Positioned(
        right: 35,
        bottom: size.height * 0.1,
        child: _buildFloatingSymbol('=', Colors.blue.shade300, 0.9),
      ),
    ];
  }
  
  Widget _buildFloatingSymbol(String symbol, Color color, double delay) {
    return AnimatedBuilder(
      animation: _bounceController,
      builder: (context, child) {
        // Add delay to animation
        final delayedValue = ((_bounceController.value + delay) % 1.0);
        
        return Transform.translate(
          offset: Offset(0, delayedValue * 15),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                symbol,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      }
    );
  }
  
  
  void _navigateToDifficultySelection(
    BuildContext context, 
    String gameName, 
    Color themeColor,
    String icon,
    Function(String) onDifficultySelected
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DifficultySelectionScreen(
          gameName: gameName,
          themeColor: themeColor,
          icon: icon,
          onDifficultySelected: onDifficultySelected,
        ),
      ),
    );
  }
  
  void _navigateToNumberDuel(BuildContext context, String difficulty) async {
    await Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => NumberDuelScreen(difficulty: difficulty)
      )
    );
    
    // Use the ensureHomeMusic method instead
    _soundManager.ensureHomeMusic();
  }
  
  void _navigateToNumberLadder(BuildContext context, String difficulty) async {
    await Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => NumberLadderScreen(difficulty: difficulty)
      )
    );
    
    // Use the ensureHomeMusic method instead
    _soundManager.ensureHomeMusic();
  }
  
  void _navigateToBuildNumber(BuildContext context, String difficulty) async {
    await Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => BuildNumberScreen(difficulty: difficulty)
      )
    );
    
    // Use the ensureHomeMusic method instead
    _soundManager.ensureHomeMusic();
  }
  
  Widget _buildGameButton(BuildContext context, String title, String subtitle, 
      Color color, IconData icon, VoidCallback onPressed) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.6),
            blurRadius: 8,
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
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color,
                  color.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 18, horizontal: 15),
              child: Row(
                children: [
                  // Game icon in a circle
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  SizedBox(width: 15),
                  // Game info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 22, 
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Arrow indicator
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white70,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}