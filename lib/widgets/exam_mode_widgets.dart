import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/exam_mode_game.dart';

class ComparisonGameWidget extends StatefulWidget {
  final ExamModeGame game; // Change type to ExamModeGame
  final Function(bool) onPlaySound;
  final AnimationController animationController;

  const ComparisonGameWidget({
    super.key,
    required this.game,
    required this.onPlaySound,
    required this.animationController,
  });

  @override
  State<ComparisonGameWidget> createState() => _ComparisonGameWidgetState();
}

class OrderingGameWidget extends StatefulWidget {
  final ExamModeGame game; // Change type to ExamModeGame
  final Function(bool) onPlaySound;
  final AnimationController animationController;

  const OrderingGameWidget({
    super.key,
    required this.game,
    required this.onPlaySound,
    required this.animationController,
  });

  @override
  State<OrderingGameWidget> createState() => _OrderingGameWidgetState();
}

class ComposingGameWidget extends StatefulWidget {
  final ExamModeGame game; // Change type to ExamModeGame
  final Function(bool) onPlaySound;
  final AnimationController animationController;

  const ComposingGameWidget({
    super.key,
    required this.game,
    required this.onPlaySound,
    required this.animationController,
  });

  @override
  State<ComposingGameWidget> createState() => _ComposingGameWidgetState();
}

class _ComparisonGameWidgetState extends State<ComparisonGameWidget> {
  // Add overlay key
  final GlobalKey<OverlayState> overlayKey = GlobalKey<OverlayState>();

  void _showFeedbackOverlay(bool isCorrect) {
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final center = renderBox.localToGlobal(
      Offset(size.width / 2, size.height / 2),
    );

    OverlayEntry overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: center.dy - 50,
            left: center.dx - 50,
            child: TweenAnimationBuilder(
              duration: Duration(milliseconds: 800),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: 1 - value,
                    child: Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      size: 100,
                      color: isCorrect ? Colors.green : Colors.red,
                    ),
                  ),
                );
              },
            ),
          ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(Duration(milliseconds: 800), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          game.findBiggerNumber
              ? 'Tap the BIGGER number!'
              : 'Tap the SMALLER number!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color:
                game.findBiggerNumber
                    ? Colors.red.shade800
                    : Colors.blue.shade800,
          ),
        ),
        SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () {
                if (!game.isTransitioning) {
                  game.selectComparisonNumber(game.leftNumber);
                  _showFeedbackOverlay(game.lastAnswerCorrect ?? false);
                }
              },
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${game.leftNumber}',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                if (!game.isTransitioning) {
                  game.selectComparisonNumber(game.rightNumber);
                  _showFeedbackOverlay(game.lastAnswerCorrect ?? false);
                }
              },
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${game.rightNumber}',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OrderingGameWidgetState extends State<OrderingGameWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _bounceAnimation;

  // Add overlay key
  final GlobalKey<OverlayState> overlayKey = GlobalKey<OverlayState>();

  void _showFeedbackOverlay(bool isCorrect) {
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final center = renderBox.localToGlobal(
      Offset(size.width / 2, size.height / 2),
    );

    OverlayEntry overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: center.dy - 50,
            left: center.dx - 50,
            child: TweenAnimationBuilder(
              duration: Duration(milliseconds: 800),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: 1 - value,
                    child: Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      size: 100,
                      color: isCorrect ? Colors.green : Colors.red,
                    ),
                  ),
                );
              },
            ),
          ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(Duration(milliseconds: 800), () {
      overlayEntry.remove();
    });
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildGameScreen(widget.game);
  }

  // Change parameter type to ExamModeGame
  Widget _buildGameScreen(ExamModeGame game) {
    final isSmallScreen = MediaQuery.of(context).size.height < 700;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Game instructions
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            game.isAscending
                ? 'Arrange numbers in ASCENDING order'
                : 'Arrange numbers in DESCENDING order',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color:
                  game.isAscending
                      ? Colors.green.shade800
                      : Colors.orange.shade800,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        // Number slots
        Container(
          margin: EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              game.userPlacedNumbers.length,
              (index) => _buildOrderingSlot(index, game),
            ),
          ),
        ),

        // Number options
        Container(
          margin: EdgeInsets.symmetric(vertical: 10),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children:
                game.numbers.map((number) {
                  bool isUsed = game.userPlacedNumbers.contains(number);
                  return GestureDetector(
                    onTap:
                        isUsed
                            ? null
                            : () {
                              if (!game.isTransitioning) {
                                game.placeNumber(number);
                                HapticFeedback.selectionClick();
                              }
                            },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color:
                            isUsed
                                ? Colors.grey.shade300
                                : Colors.blue.shade400,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow:
                            isUsed
                                ? []
                                : [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 5,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                      ),
                      child: Center(
                        child: Text(
                          '$number',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isUsed ? Colors.grey.shade500 : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),

        // Add submit button when all slots are filled
        if (!game.userPlacedNumbers.contains(null) && !game.isTransitioning)
          Padding(
            padding: EdgeInsets.only(top: 20),
            child: ElevatedButton(
              onPressed: () {
                _checkOrderingAnswer(game);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Submit Answer',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Add this method to handle the ordering answer submission
  void _checkOrderingAnswer(ExamModeGame game) {
    // Create correctly ordered list
    List<int> correctOrder = List.from(game.numbers);
    if (game.isAscending) {
      correctOrder.sort();
    } else {
      correctOrder.sort((a, b) => b.compareTo(a));
    }
    
    // Check if user's order is correct
    bool isCorrect = true;
    for (int i = 0; i < correctOrder.length; i++) {
      if (game.userPlacedNumbers[i] != correctOrder[i]) {
        isCorrect = false;
        break;
      }
    }
    
    // Update game state
    game.lastAnswerCorrect = isCorrect;
    widget.onPlaySound(isCorrect);
    _showFeedbackOverlay(isCorrect);
    
    if (isCorrect) {
      game.players[game.currentPlayerIndex].score += 10;
    }
    
    game.isTransitioning = true;
    
    // Move to next question after delay
    Future.delayed(Duration(milliseconds: 1500), () {
      if (game.isMultiplayer) {
        if (game.currentQuestion >= 10 && game.currentPlayerIndex == 0) {
          // First player finished their 10 questions
          if (game.onPlayerSwitch != null) {
            game.onPlayerSwitch!(); // Trigger the player switch callback
          } else {
            game.switchToPlayer2();
          }
        } else if (game.currentQuestion >= 10 && game.currentPlayerIndex == 1) {
          // Second player finished their 10 questions
          game.gameOver = true;
        } else {
          // Continue with next question
          game.currentQuestion++;
        }
      } else {
        // Single player mode
        if (game.currentQuestion >= 20) {
          game.gameOver = true;
        } else {
          game.currentQuestion++;
        }
      }
      
      if (!game.gameOver) {
        game.generateNextQuestion();
      }
      game.notifyListeners();
    });
  }

  // Add this method to the _OrderingGameWidgetState class in exam_mode_widgets.dart
  Widget _buildOrderingSlot(int index, ExamModeGame game) {
    return GestureDetector(
      onTap: game.userPlacedNumbers[index] != null 
          ? () {
              if (!game.isTransitioning) {
                game.removeNumber(index);
                HapticFeedback.lightImpact();
              }
            } 
          : null,
      child: Container(
        width: 60,
        height: 60,
        margin: EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: game.userPlacedNumbers[index] != null 
              ? Colors.green.shade400 
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.grey.shade400,
            width: 2,
          ),
        ),
        child: Center(
          child: game.userPlacedNumbers[index] != null
              ? Text(
                  '${game.userPlacedNumbers[index]}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey.shade400,
                ),
        ),
      ),
    );
  }
}

class _ComposingGameWidgetState extends State<ComposingGameWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _bounceAnimation;

  // Add overlay key
  final GlobalKey<OverlayState> overlayKey = GlobalKey<OverlayState>();

  void _showFeedbackOverlay(bool isCorrect) {
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final center = renderBox.localToGlobal(
      Offset(size.width / 2, size.height / 2),
    );

    OverlayEntry overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: center.dy - 50,
            left: center.dx - 50,
            child: TweenAnimationBuilder(
              duration: Duration(milliseconds: 800),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: 1 - value,
                    child: Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      size: 100,
                      color: isCorrect ? Colors.green : Colors.red,
                    ),
                  ),
                );
              },
            ),
          ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(Duration(milliseconds: 800), () {
      overlayEntry.remove();
    });
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildGameScreen(widget.game);
  }

  // In _ComposingGameWidgetState class
    Widget _buildGameScreen(ExamModeGame game) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    final isVerySmallScreen = screenSize.height < 600;
    
    int currentSum = game.selectedNumbers.fold(0, (sum, number) => sum + number);
    
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Instructions
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: EdgeInsets.symmetric(
              horizontal: 16, 
              vertical: isSmallScreen ? 6 : 8
            ),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.orange.shade800),
            ),
            child: Text(
              'Select numbers that add up to the target',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w500,
                color: Colors.orange.shade800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Target number in circle
          Container(
            margin: EdgeInsets.symmetric(vertical: 12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Circle background
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.purple.shade400,
                        Colors.purple.shade800,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                
                // Target number
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'TARGET',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    Text(
                      '${game.targetNumber}',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Display selected numbers without color indication
          if (game.selectedNumbers.isNotEmpty)
            Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),  // Always use white background
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Selected: ${game.selectedNumbers.join(" + ")}',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,  // Always use white text
                ),
              ),
            ),
          
          // Number grid
          Container(
            height: isVerySmallScreen ? 120 : isSmallScreen ? 150 : 180,
            margin: EdgeInsets.symmetric(
              horizontal: 12, 
              vertical: isSmallScreen ? 5 : 10
            ),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.7),
              borderRadius: BorderRadius.circular(15),
            ),
            child: GridView.builder(
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                childAspectRatio: 1.0,
                crossAxisSpacing: isSmallScreen ? 5 : 8, 
                mainAxisSpacing: isSmallScreen ? 5 : 8,
              ),
              itemCount: game.numberOptions.length, // Will show 10 numbers
              itemBuilder: (context, index) {
                int number = game.numberOptions[index];
                bool isSelected = game.isIndexSelected(index);
                
                return GestureDetector(
                  onTap: () {
                    if (!game.isTransitioning) {
                      game.toggleNumber(index);
                      HapticFeedback.selectionClick();
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.purple.shade400 : Colors.white, // Changed to purple when selected
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.grey.shade400,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 3,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$number',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 18 : 22,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Submit button
          if (game.selectedNumbers.length >= 2 && !game.isTransitioning)
            Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: ElevatedButton(
                onPressed: () {
                  game.submitAnswer();
                  _showFeedbackOverlay(game.lastAnswerCorrect ?? false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(
                    horizontal: 20, 
                    vertical: isSmallScreen ? 5 : 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Submit Answer',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
