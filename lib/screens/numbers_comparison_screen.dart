import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/numbers_comparison_game.dart';
import '../widgets/numbers_comparison_widgets.dart';
import '../utils/sound_manager.dart';

class NumberComparisonScreen extends StatefulWidget {
  final String difficulty;
  
  const NumberComparisonScreen({super.key, required this.difficulty});
  
  @override
  _NumberComparisonScreenState createState() => _NumberComparisonScreenState();
}

class _NumberComparisonScreenState extends State<NumberComparisonScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  int? selectedNumber;
  int _timeRemaining = 0;
  bool _timerActive = false;
  final _soundManager = SoundManager();
  bool _isMusicPlaying = true;
  
  @override
  void initState() {
    super.initState();
    
    // Play specific game music instead of generic game_music.mp3
    _soundManager.playGameMusic('Number_Comparison');
    _isMusicPlaying = _soundManager.isMusicEnabled;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  // Update the _playSound method:
  void _playSound(bool correct) {
    if (!_soundManager.isMusicEnabled) return;
    
    final soundPath = correct ? 'sounds/correct.mp3' : 'sounds/wrong.mp3';
    _soundManager.playGameSound(soundPath);
  }
  
  void _startTimer(NumberComparisonGame game) {
    if (game.getTimeLimit > 0 && !_timerActive && !game.isTransitioning) {
      _timerActive = true;
      _timeRemaining = game.getTimeLimit;
      
      Future.doWhile(() async {
        await Future.delayed(Duration(seconds: 1));
        if (mounted && !game.isTransitioning) { // Don't tick down during transitions
          setState(() {
            _timeRemaining--;
          });
          
          if (_timeRemaining <= 0) {
            // Time's up - count as wrong answer
            HapticFeedback.heavyImpact();
            _playSound(false);
            game.selectNumber(-1); // An invalid number that can't be correct
            _timerActive = false;
            
            // Add delay before next round
            if (!game.gameOver) {
              Future.delayed(Duration(milliseconds: 1500), () {
                if (mounted) {
                  game.prepareNextRound(); // Advance to next round after delay
                  setState(() {}); // Refresh UI
                }
              });
            }
            
            return false;
          }
        }
        return _timerActive && mounted && !game.isTransitioning;
      });
    }
  }
  
  void _showInstructions(NumberComparisonGame game) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue, size: 28),
            SizedBox(width: 10),
            Text('Game Instructions'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How to Play:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: 10),
              Text(
                '• The game will ask you to find either the BIGGER or SMALLER number',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '• Tap on the correct number to score a point',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '• Use hints to highlight the correct answer',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                '• Skip difficult questions (limited uses)',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 15),
              
              Text(
                'Current Difficulty: ${widget.difficulty.capitalize()}',
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 18, 
                  color: getDifficultyColor(widget.difficulty),
                ),
              ),
              SizedBox(height: 10),
              
              // Display difficulty-specific information
              _buildDifficultyInfo(game),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it!', style: TextStyle(fontSize: 16)),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        backgroundColor: Colors.white,
      ),
    );
  }
  
  Widget _buildDifficultyInfo(NumberComparisonGame game) {
    // Number range info based on difficulty
    String numberRange = "";
    String timeInfo = "";
    String roundsInfo = "";
    
    switch (widget.difficulty.toLowerCase()) {
      case 'easy':
        numberRange = "1 to 20";
        timeInfo = "No time limit";
        roundsInfo = "8 rounds";
        break;
      case 'medium':
        numberRange = "1 to 50";
        timeInfo = "No time limit";
        roundsInfo = "12 rounds";
        break;
      case 'hard':
        numberRange = "50 to 100";
        timeInfo = "5 seconds per question";
        roundsInfo = "15 rounds";
        break;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildInfoRow(Icons.format_list_numbered, "Number Range:", numberRange),
        buildInfoRow(Icons.timer, "Time Limit:", timeInfo),
        buildInfoRow(Icons.replay, "Total Rounds:", roundsInfo),
        buildInfoRow(Icons.lightbulb_outline, "Hints Available:", "${game.hintsRemaining}"),
        buildInfoRow(Icons.skip_next, "Skips Available:", "${game.skipsRemaining}"),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NumberComparisonGame(widget.difficulty),
      child: Consumer<NumberComparisonGame>(
        builder: (context, game, child) {
          // Start the timer for this round if needed
          if (game.getTimeLimit > 0 && !_timerActive && !game.isTransitioning) {
            _startTimer(game);
          }
          
          return WillPopScope(
            onWillPop: () async {
              // Stop game music when navigating back
              await _soundManager.stopBackgroundMusic();
              return true;
            },
            child: Scaffold(
              appBar: AppBar(
                title: Text('Number Comparison - ${widget.difficulty.capitalize()}'),
                backgroundColor: Colors.red.shade400,
                actions: [
                  // Help button
                  IconButton(
                    icon: Icon(Icons.help_outline, color: Colors.white),
                    onPressed: () => _showInstructions(game),
                  ),
                  // Score display
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Score: ${game.score}/${game.maxRounds}', 
                      style: TextStyle(fontSize: 18)
                    ),
                  ),
                ],
              ),
              body: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.red.shade200, Colors.orange.shade200],
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative background elements
                    ...buildBackgroundElements(context),
                    
                    // Main game content
                    game.gameOver 
                      ? _buildGameOverScreen(game)
                      : _buildGameScreen(game),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildGameScreen(NumberComparisonGame game) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bouncing round indicator
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0.9, end: 1.0),
                duration: Duration(milliseconds: 1000),
                curve: Curves.elasticOut,
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        'Round ${game.displayRound} of ${game.maxRounds}', // Use displayRound instead of currentRound
                        style: TextStyle(
                          fontSize: 24, 
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ),
                  );
                },
              ),
                
              SizedBox(height: 15),
              
              // Question instruction with animation
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 800),
                builder: (context, double value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, (1-value) * 20),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        decoration: BoxDecoration(
                          color: game.findBiggerNumber 
                              ? Colors.red.shade100 
                              : Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: game.findBiggerNumber 
                                ? Colors.red.shade800 
                                : Colors.blue.shade800,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              game.findBiggerNumber 
                                  ? Icons.arrow_upward 
                                  : Icons.arrow_downward,
                              color: game.findBiggerNumber 
                                  ? Colors.red.shade800 
                                  : Colors.blue.shade800,
                              size: 24,
                            ),
                            SizedBox(width: 10),
                            Text(
                              game.findBiggerNumber
                                  ? 'Tap the BIGGER number!'
                                  : 'Tap the SMALLER number!',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: game.findBiggerNumber 
                                    ? Colors.red.shade800 
                                    : Colors.blue.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              // Timer display for hard difficulty
              if (game.getTimeLimit > 0 && !game.isTransitioning)
                Padding(
                  padding: const EdgeInsets.only(top: 15.0),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                    decoration: BoxDecoration(
                      color: _timeRemaining <= 2 ? Colors.red.shade400 : Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer,
                          color: _timeRemaining <= 2 ? Colors.white : Colors.grey.shade800,
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Time: $_timeRemaining',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _timeRemaining <= 2 ? Colors.white : Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
              SizedBox(height: 15),
              
              // Correct/Wrong indicator
              if (game.lastAnswerCorrect != null)
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                  decoration: BoxDecoration(
                    color: game.lastAnswerCorrect! 
                        ? Colors.green.withValues(alpha: 0.2) 
                        : Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        game.lastAnswerCorrect! 
                            ? Icons.check_circle 
                            : Icons.cancel,
                        color: game.lastAnswerCorrect! 
                            ? Colors.green 
                            : Colors.red,
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        game.lastAnswerCorrect! ? 'Correct!' : 'Wrong!',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: game.lastAnswerCorrect! 
                              ? Colors.green 
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                
              SizedBox(height: 25),
              
              // Number containers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNumberContainer(context, game.leftNumber, game, true),
                  _buildNumberContainer(context, game.rightNumber, game, false),
                ],
              ),
              
              // Hint and Skip buttons
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Hint button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: ElevatedButton.icon(
                      onPressed: game.hintsRemaining > 0 && !game.isTransitioning && !game.hintActive
                        ? () {
                            bool hintUsed = game.useHint();
                            if (hintUsed) {
                              HapticFeedback.lightImpact();
                              _soundManager.playButtonSound();
                            }
                          }
                        : null, // Disable button when out of hints
                      icon: Icon(Icons.lightbulb_outline),
                      label: Text('Hint (${game.hintsRemaining})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black87,
                        disabledBackgroundColor: Colors.grey.shade400,
                        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                  
                  // Skip button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: ElevatedButton.icon(
                      onPressed: game.skipsRemaining > 0 && !game.isTransitioning
                        ? () {
                            bool skipped = game.skipQuestion();
                            if (skipped) {
                              HapticFeedback.mediumImpact();
                              _soundManager.playButtonSound();
                              // Show transition indicator
                              Future.delayed(Duration(milliseconds: 1500), () {
                                if (mounted && !game.gameOver) {
                                  game.prepareNextRound();
                                  setState(() {
                                    _timerActive = false;
                                  });
                                }
                              });
                            }
                          }
                        : null, // Disable button when out of skips
                      icon: Icon(Icons.skip_next),
                      label: Text('Skip (${game.skipsRemaining})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade400,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade400,
                        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              // Transitioning indicator
              if (game.isTransitioning)
                Padding(
                  padding: const EdgeInsets.only(top: 25.0),
                  child: buildTransitionIndicator(() {
                    // This callback runs after the delay
                    if (!game.gameOver) {
                      game.prepareNextRound();
                      setState(() {
                        _timerActive = false; // Reset timer state to prepare for next round
                      });
                    }
                  }),
                ),
                
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildNumberContainer(BuildContext context, int number, NumberComparisonGame game, bool isLeft) {
    // Determine if this number is the correct answer
    final correctAnswer = game.findBiggerNumber
        ? (game.leftNumber > game.rightNumber ? game.leftNumber : game.rightNumber)
        : (game.leftNumber < game.rightNumber ? game.leftNumber : game.rightNumber);
        
    final isCorrectAnswer = number == correctAnswer;
    
    // We don't need decimal formatting anymore since we're not using decimal numbers
    String displayNumber = '$number';
    
    return GestureDetector(
      onTap: game.isTransitioning ? null : () {
        selectedNumber = number;
        _animationController.reset();
        _animationController.forward();
        
        HapticFeedback.mediumImpact();
        
        // Reset timer state
        _timerActive = false;
        
        // Determine if this answer is correct based on whether we're looking for bigger or smaller
        final correctAnswer = game.findBiggerNumber
            ? (game.leftNumber > game.rightNumber ? game.leftNumber : game.rightNumber)
            : (game.leftNumber < game.rightNumber ? game.leftNumber : game.rightNumber);
        
        final isCorrect = (number == correctAnswer);
        
        // Play correct sound first, before any state changes
        _playSound(isCorrect);
        
        // Then update game state
        game.selectNumber(number);
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: selectedNumber == number ? _scaleAnimation.value : 1.0,
            child: Opacity(
              opacity: game.isTransitioning ? 0.6 : 1.0, // Dim during transitions
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      isLeft ? Colors.blue.shade400 : Colors.purple.shade400,
                      isLeft ? Colors.blue.shade600 : Colors.purple.shade600,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (game.hintActive && isCorrectAnswer) 
                          ? Colors.yellow.withValues(alpha: 0.8) 
                          : Colors.black26,
                      blurRadius: (game.hintActive && isCorrectAnswer) ? 15 : 10,
                      spreadRadius: (game.hintActive && isCorrectAnswer) ? 2 : 0,
                      offset: Offset(0, 5),
                    ),
                  ],
                  // Add highlight border when hint is active and this is the correct answer
                  border: (game.hintActive && isCorrectAnswer)
                      ? Border.all(color: Colors.yellow, width: 4)
                      : Border.all(color: Colors.white.withValues(alpha :0.2), width: 2),
                ),
                child: Stack(
                  children: [
                    // Background decorative circles
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 15,
                      left: 15,
                      child: Container(
                        width: 25,
                        height: 25,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                    
                    // Number display
                    Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            displayNumber,
                            style: TextStyle(
                              fontSize: 60,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
                      ),
                    ),
                    
                    // Hint indicator
                    if (game.hintActive && isCorrectAnswer)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.yellow,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.yellow.withValues(alpha: 0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            game.findBiggerNumber 
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: Colors.black87,
                            size: 24,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildGameOverScreen(NumberComparisonGame game) {
    return Stack(
      children: [
        // Background confetti-like elements for fun
        ...buildGameOverDecoration(context),
        
        // Main content
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
              
              SizedBox(height: 30),
              
              // Congratulations text
              Text(
                'Well Done!',
                style: TextStyle(
                  fontSize: 36, 
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              
              // Score display
              Container(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      'Your Score:',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '${game.score}/${game.maxRounds}',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.stars,
                          color: getDifficultyColor(widget.difficulty),
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Difficulty: ${widget.difficulty.capitalize()}',
                          style: TextStyle(
                            fontSize: 18,
                            color: getDifficultyColor(widget.difficulty),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 40),
              
              // Play again button
              ElevatedButton(
                onPressed: () {
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
                    Icon(Icons.replay, size: 24),
                    SizedBox(width: 10),
                    Text('Play Again', style: TextStyle(fontSize: 20)),
                  ],
                ),
              ),
              
              SizedBox(height: 20),
              
              // Back to home button
              TextButton.icon(
                onPressed: () async {
                  _soundManager.playButtonSound();
                  
                  // First stop the current game music completely
                  await _soundManager.stopBackgroundMusic();
                  
                  // Then navigate back
                  if (!mounted) return;
                  Navigator.pop(context);
                },
                icon: Icon(Icons.home, color: Colors.white, size: 24),
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
      ],
    );
  }
}