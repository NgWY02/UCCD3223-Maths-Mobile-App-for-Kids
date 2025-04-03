import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/numbers_ordering_game.dart';
import '../widgets/numbers_ordering_widgets.dart';
import '../utils/sound_manager.dart';
import '../utils/string_utils.dart';

class NumberOrderingScreen extends StatefulWidget {
  final String difficulty;

  const NumberOrderingScreen({super.key, required this.difficulty});

  @override
  _NumberOrderingScreenState createState() => _NumberOrderingScreenState();
}

class _NumberOrderingScreenState extends State<NumberOrderingScreen> with SingleTickerProviderStateMixin {
  // Sound management
  final SoundManager _soundManager = SoundManager();
  bool _isMusicPlaying = true;
  
  // Animation controller for submit button
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    
    // Get music state
    _isMusicPlaying = _soundManager.isMusicEnabled;
    
    // Use only this method to start game music
    _soundManager.playGameMusic('Number_Ordering');
    
    // Setup bounce animation for submit button
    _bounceController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _playSound(bool correct) {
    if (!_soundManager.isMusicEnabled) return;
    
    final soundPath = correct ? 'sounds/correct.mp3' : 'sounds/wrong.mp3';
    _soundManager.playGameSound(soundPath);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Stop game music before navigating back
        await _soundManager.stopBackgroundMusic();
        return true;
      },
      child: ChangeNotifierProvider(
        create: (_) => NumberOrderingGame(
          widget.difficulty,
          onPlaySound: _playSound,
        ),
        child: Consumer<NumberOrderingGame>(
          builder: (context, game, child) {
            return Scaffold(
              extendBodyBehindAppBar: true,
              appBar: AppBar(
                title: Text('Balloon Numbers - ${widget.difficulty.capitalize()}'),
                backgroundColor: Colors.blue.shade400.withValues(alpha: 0.7),
                elevation: 0,
                actions: [
                  // Help button
                  IconButton(
                    icon: Icon(Icons.help_outline, color: Colors.white),
                    onPressed: () => showInstructions(
                      context, 
                      widget.difficulty,
                      game.hintsRemaining,
                      game.skipsRemaining,
                      game.hasTimeLimit,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Score: ${game.score}/${game.maxRounds}',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              body: Container(
                decoration: BoxDecoration(
                  // Gradient sky background
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.lightBlue.shade300, Colors.blue.shade100],
                  ),
                ),
                child: SafeArea(
                  child: game.gameOver 
                    ? _buildGameOverScreen(game)
                    : _buildGameScreen(game),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGameScreen(NumberOrderingGame game) {
    // Get screen size for responsive layout
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            // Round and time information
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 3,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'Round ${game.currentRound} of ${game.maxRounds}',
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                  if (game.hasTimeLimit)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(
                        color: game.remainingTime <= 5
                          ? Colors.red.shade400
                          : Colors.orange.shade400,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 3,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.timer, color: Colors.white, size: 20),
                          SizedBox(width: 5),
                          Text(
                            'Time: ${game.remainingTime} s',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Instructions
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: game.isAscending
                  ? Colors.green.shade100
                  : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: game.isAscending
                    ? Colors.green.shade800
                    : Colors.orange.shade800,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    game.isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    color: game.isAscending
                      ? Colors.green.shade800
                      : Colors.orange.shade800,
                    size: 24,
                  ),
                  SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      game.isAscending
                        ? 'Arrange balloons from SMALLEST to LARGEST'
                        : 'Arrange balloons from LARGEST to SMALLEST',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: game.isAscending
                          ? Colors.green.shade800
                          : Colors.orange.shade800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            // Feedback message
            if (game.lastAnswerCorrect != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: BoxDecoration(
                    color: game.lastAnswerCorrect!
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: game.lastAnswerCorrect!
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        game.lastAnswerCorrect!
                          ? Icons.check_circle
                          : Icons.warning_amber_rounded,
                        color: game.lastAnswerCorrect!
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        game.lastAnswerCorrect!
                          ? 'Correct!'
                          : 'Wrong!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: game.lastAnswerCorrect!
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Balloon section (make it flex to fit available space)
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  // Cloud decorations
                  buildClouds(),
                  
                  // Row of balloons
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(game.userPlacedNumbers.length, (index) {
                        bool showHint = game.hintPosition == index;
                        
                        // If position has a number, show a balloon with that number
                        if (game.userPlacedNumbers[index] != null) {
                          return buildBalloon(
                            game.userPlacedNumbers[index]!,
                            index,
                            onTap: () => game.removeNumber(index),
                          );
                        }
                        
                        // Empty slot or hint
                        return buildEmptyBalloonSpot(
                          showHint ? game.orderedNumbers[index] : null,
                          index,
                        );
                      }),
                    ),
                  ),
                  
                  // Order indicator
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          game.isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                          color: Colors.indigo,
                          size: 22,
                        ),
                        SizedBox(width: 5),
                        Text(
                          game.isAscending
                            ? 'Smallest to Largest'
                            : 'Largest to Smallest',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                        SizedBox(width: 5),
                        Icon(
                          game.isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                          color: Colors.indigo,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Submit button
            if (!game.userPlacedNumbers.contains(null) && !game.success)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
                child: ScaleTransition(
                  scale: _bounceAnimation,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      game.submitAnswer();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade500,
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 5,
                    ),
                    child: Text(
                      'Check Answer',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

            // Hint and Skip buttons
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: isSmallScreen ? 5.0 : 10.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: game.hintsRemaining > 0 && !game.success 
                      ? () {
                          HapticFeedback.lightImpact();
                          _soundManager.playButtonSound();
                          game.useHint();
                        }
                      : null,
                    icon: Icon(Icons.lightbulb_outline),
                    label: Text('Hint (${game.hintsRemaining})'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black87,
                      disabledBackgroundColor: Colors.grey.shade400,
                      padding: EdgeInsets.symmetric(
                        horizontal: 15, 
                        vertical: isSmallScreen ? 10 : 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                  SizedBox(width: 15),
                  ElevatedButton.icon(
                    onPressed: game.skipsRemaining > 0 && !game.success
                      ? () {
                          HapticFeedback.mediumImpact();
                          _soundManager.playButtonSound();
                          game.skipRound();
                        }
                      : null,
                    icon: Icon(Icons.skip_next),
                    label: Text('Skip (${game.skipsRemaining})'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade400,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade400,
                      padding: EdgeInsets.symmetric(
                        horizontal: 15, 
                        vertical: isSmallScreen ? 10 : 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Available numbers for selection - make responsive
            Container(
              height: isSmallScreen ? 100 : 120,
              padding: EdgeInsets.all(isSmallScreen ? 8 : 15),
              margin: EdgeInsets.all(isSmallScreen ? 5 : 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Wrap(
                  spacing: 15,
                  runSpacing: 15,
                  alignment: WrapAlignment.center,
                  children: game.numbers.map((number) {
                    bool isUsed = game.userPlacedNumbers.contains(number);
                    return buildNumberBubble(
                      number, 
                      isUsed,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        game.placeNumber(number);
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGameOverScreen(NumberOrderingGame game) {
    return Stack(
      children: [

        // Main content
        Center(
          child: Container(
            padding: EdgeInsets.all(25),
            margin: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Trophy icon with animation
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 1000),
                  curve: Curves.elasticOut,
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.emoji_events,
                          color: Colors.amber,
                          size: 80,
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 20),
                Text(
                  'Well Done!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                SizedBox(height: 20),
                // Score display with animation
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 800),
                  curve: Curves.easeOut,
                  builder: (context, double value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, (1-value) * 20),
                        child: Text(
                          'Your Score: ${game.score}/${game.maxRounds}',
                          style: TextStyle(
                            fontSize: 24, 
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _soundManager.playButtonSound();
                    game.restartGame();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.replay, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        'Play Again', 
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                TextButton.icon(
                  onPressed: () async {
                    _soundManager.playButtonSound();
                    
                    // Make sure we fully stop game music before navigating
                    await _soundManager.stopBackgroundMusic();
                    
                    if (!mounted) return;
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.home, color: Colors.white),
                  label: Text(
                    'Back to Home', 
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black38,
                    padding: EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}