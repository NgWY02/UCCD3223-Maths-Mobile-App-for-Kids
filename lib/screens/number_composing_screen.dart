import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/numbers_composing_game.dart';
import '../widgets/numbers_composing_widgets.dart';
import '../utils/sound_manager.dart';
import '../utils/string_utils.dart';

class NumberComposingScreen extends StatefulWidget {
  final String difficulty;
  
  const NumberComposingScreen({super.key, required this.difficulty});
  
  @override
  State<NumberComposingScreen> createState() => _NumberComposingScreenState();
}

class _NumberComposingScreenState extends State<NumberComposingScreen> with SingleTickerProviderStateMixin {
  // Sound manager instance
  final _soundManager = SoundManager();
  
  // Animation for submit button
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Play game music
    _soundManager.playGameMusic('Number_Composing');
    
    // Setup animation for submit button
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
  
  // Sound method
  void _playSound(bool correct) {
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
        create: (_) {
          final game = NumberComposingGame(
            widget.difficulty, 
            onPlaySound: _playSound,
          );
          // Set the timer tick callback to trigger UI updates
          game.onTimerTick = () {
            if (mounted) setState(() {});
          };
          return game;
        },
        child: Consumer<NumberComposingGame>(
          builder: (context, game, child) {
            return Scaffold(
              extendBodyBehindAppBar: true,
              appBar: AppBar(
                title: Text('Build a Number - ${widget.difficulty.capitalize()}'),
                backgroundColor: Colors.orange.shade400.withValues(alpha:0.8),
                elevation: 0,
                actions: [
                  // Help button
                  IconButton(
                    icon: Icon(Icons.help_outline, color: Colors.white),
                    onPressed: () => showBuildNumberInstructions(
                      context, 
                      widget.difficulty,
                      game.hintsRemaining,
                      game.skipsRemaining,
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Score: ${game.score}/${game.maxRounds}', 
                      style: const TextStyle(fontSize: 18)
                    ),
                  ),
                ],
              ),
              body: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.orange.shade200, 
                      Colors.yellow.shade100, 
                      Colors.orange.shade50
                    ],
                  ),
                ),
                child: game.gameOver 
                  ? _buildGameOverScreen(game)
                  : _buildGameScreen(game),
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildGameScreen(NumberComposingGame game) {
    // Get screen size for responsive layout
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    final isVerySmallScreen = screenSize.height < 600; // Add this line
    
    int currentSum = game.getCurrentSum();
    
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Keep the top round/time info bar
              Padding(
                padding: EdgeInsets.all(isSmallScreen ? 6.0 : 10.0), // Reduce padding for small screens
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.7),
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
                          fontSize: 20, 
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
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
              // Reduce this padding
              const SizedBox(height: 2), // Reduced from 5
              
              // Make instructions more compact for small screens
              Container(
                margin: EdgeInsets.symmetric(
                  horizontal: 16.0, 
                  vertical: isSmallScreen ? 2.0 : 5.0, // Reduced vertical margin
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: 20, 
                  vertical: isSmallScreen ? 5 : 8, // Reduced vertical padding
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.orange.shade800,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: Colors.orange.shade800,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Select numbers that add up to the target',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange.shade800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Make feedback message more compact
              if (game.lastAnswerCorrect != null)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 4.0 : 8.0), // Reduced padding
                  child: buildFeedbackMessage(game.lastAnswerCorrect),
                ),
              
              // Reduce spacing
              SizedBox(height: isSmallScreen ? 5 : 10), // Reduced from 10
              
              // Target number display - can't reduce much here
              buildTargetDisplay(game.targetNumber),
              
              // Reduce spacing
              SizedBox(height: isSmallScreen ? 10 : 20), // Reduced from 20
              
              // Current sum display
              buildSumDisplay(currentSum, game.targetNumber),
              
              // Reduce spacing
              SizedBox(height: isSmallScreen ? 5 : 10), // Reduced from 10
              
              // Selected numbers - keep this compact
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: isSmallScreen ? 2 : 5), // Reduced vertical margin
                child: Text(
                  game.selectedNumbers.isEmpty
                      ? 'Selected: None'
                      : 'Selected: ${game.selectedNumbers.join(" + ")}',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18, // Smaller text on small screens 
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              
              // Submit button - keep this with reduced vertical padding
              if (game.selectedNumbers.length >= 2 && !game.isTransitioning)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 5.0 : 10.0), // Reduced padding
                  child: ScaleTransition(
                    scale: _bounceAnimation,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        game.submitAnswer();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade500,
                        padding: EdgeInsets.symmetric(
                          horizontal: 30, 
                          vertical: isSmallScreen ? 8 : 12, // Reduced vertical padding
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 5,
                      ),
                      child: Text(
                        'Submit Answer',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              
              // Hint and Skip buttons - more compact for small screens
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: isSmallScreen ? 2.0 : 5.0, // Reduced further
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: game.hintsRemaining > 0 && !game.hintActive && !game.isTransitioning
                        ? () {
                            bool hintUsed = game.useHint();
                            if (hintUsed) {
                              HapticFeedback.lightImpact();
                              _soundManager.playButtonSound();
                            }
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
                      onPressed: game.skipsRemaining > 0 && !game.isTransitioning
                        ? () {
                            bool skipped = game.skipQuestion();
                            if (skipped) {
                              HapticFeedback.mediumImpact();
                              _soundManager.playButtonSound();
                            }
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
              
              // Number grid - reduce height for small screens
              Container(
                height: MediaQuery.of(context).size.width > 600 
                    ? 220 // For larger screens (tablets)
                    : isVerySmallScreen ? 140 : isSmallScreen ? 150 : 180, // Further reduced for very small screens
                margin: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8.0 : 15.0,
                  vertical: isSmallScreen ? 2.0 : 5.0, // Reduced vertical margin
                ),
                padding: EdgeInsets.all(isSmallScreen ? 8.0 : 12.0),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    childAspectRatio: 1.0, 
                    crossAxisSpacing: isSmallScreen ? 5 : 8,
                    mainAxisSpacing: isSmallScreen ? 5 : 8,
                  ),
                  itemCount: game.numberOptions.length,
                  itemBuilder: (context, index) {
                    int number = game.numberOptions[index];
                    bool isSelected = game.isIndexSelected(index);
                    bool isHintNumber = game.isHintNumber(number);
                    
                    return buildNumberTile(
                      number: number,
                      isSelected: isSelected,
                      isHintNumber: isHintNumber,
                      onTap: () {
                        if (!game.isTransitioning) {
                          HapticFeedback.selectionClick();
                          game.toggleNumber(index);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildGameOverScreen(NumberComposingGame game) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(25),
        margin: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha:0.9),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
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
                          color: Colors.amber.withValues(alpha:0.5),
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
                color: Colors.orange.shade800,
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
                        color: Colors.orange.shade700,
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
                
                // Stop game music before navigating
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
    );
  }
}