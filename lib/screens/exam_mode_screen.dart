import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exam_mode_game.dart';
import '../models/player.dart';
import '../utils/sound_manager.dart';
import '../widgets/exam_mode_widgets.dart';
import 'dart:async';

class ExamModeScreen extends StatefulWidget {
  final bool isMultiplayer;

  const ExamModeScreen({required this.isMultiplayer, super.key});

  @override
  State<ExamModeScreen> createState() => _ExamModeScreenState();
}

class _ExamModeScreenState extends State<ExamModeScreen>
    with SingleTickerProviderStateMixin {
  final _soundManager = SoundManager();
  final _player1Controller = TextEditingController();
  final _player2Controller = TextEditingController();
  List<Player>? _players;
  late AnimationController _animationController;


  @override
  void initState() {
    super.initState();

    if (!widget.isMultiplayer) {
      _soundManager.stopBackgroundMusic();
      _soundManager.playGameMusic('Exam_Mode');
      _players = [Player("Player 1")];
      
      // Add post-frame callback to show countdown for single player
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSinglePlayerCountdown(context);
      });
    } else {
      // For multiplayer, initialize players which will handle music
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializePlayers();
      });
    }

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  Future<void> _initializePlayers() async {
    // First fully stop any playing music
    await _soundManager.stopBackgroundMusic();
    _soundManager.disableMusicDuringSetup();
    
    final names = await _getPlayerNames(context);
    if (names != null) {
      setState(() {
        _players = [Player(names[0]), Player(names[1])];
      });
      
      // Wait for UI to update before changing music
      await Future.delayed(Duration(milliseconds: 300));
      await _soundManager.forceExamModeMusic();
      
      // Show countdown for Player 1 before starting the game
      _showPlayer1Countdown(context, names[0]);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _player1Controller.dispose();
    _player2Controller.dispose();
    _animationController.dispose();
    super.dispose();
    // Don't handle music in dispose since back button already handles it
  }

  void _playSound(bool correct) {
    if (!_soundManager.isMusicEnabled) return;
    final soundPath = correct ? 'sounds/correct.mp3' : 'sounds/wrong.mp3';
    _soundManager.playGameSound(soundPath);
  }

  Widget _buildGameContent(ExamModeGame game) {
    return Column(
      children: [
        // Add back button row at the top
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () async {
                  // First stop exam mode music
                  await _soundManager.stopBackgroundMusic();
                  // Then play home music before navigating
                  await _soundManager.playHomeMusic();
                  // Wait a tiny bit to ensure music starts
                  await Future.delayed(Duration(milliseconds: 100));
                  Navigator.of(context).pop();
                },
              ),
              Text(
                game.getCurrentGameTypeLabel(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 48), // Balance the layout
            ],
          ),
        ),
        _buildGameHeader(game),
        Expanded(child: _buildCurrentGame(game)),
        _buildScoreDisplay(game),
      ],
    );
  }

  Widget _buildCurrentGame(ExamModeGame game) {
    switch (game.currentGameType) {
      case 'comparison':
        return ComparisonGameWidget(
          game: game,
          onPlaySound: _playSound,
          animationController: _animationController,
        );
      case 'ordering':
        return OrderingGameWidget(
          game: game,
          onPlaySound: _playSound,
          animationController: _animationController,
        );
      case 'composing':
        return ComposingGameWidget(
          game: game,
          onPlaySound: _playSound,
          animationController: _animationController,
        );
      default:
        return const Center(child: Text('Loading...'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Remove the AppBar completely
      appBar: null, // Or just remove this line entirely
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple.shade900, Colors.black],
          ),
        ),
        child: SafeArea(
          child: _players == null
              ? const Center(child: CircularProgressIndicator())
              : ChangeNotifierProvider(
                  create: (_) {
                    final game = ExamModeGame(
                      players: _players!,
                      onPlaySound: _playSound,
                      isMultiplayer: widget.isMultiplayer,
                    );
                    
                    // Add player switch callback for multiplayer
                    if (widget.isMultiplayer) {
                      game.onPlayerSwitch = () {
                        _showPlayerSwitchCountdown(context, game);
                      };
                    }
                    
                    return game;
                  },
                  child: Consumer<ExamModeGame>(
                    builder: (context, game, child) {
                      return game.gameOver
                          ? _buildGameOverScreen(game)
                          : _buildGameContent(game);
                    },
                  ),
                ),
        ),
      ),
    );
  }

  Future<List<String>?> _getPlayerNames(BuildContext context) {
    String? errorMessage; // Nullable String to store the error message

    return showDialog<List<String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              backgroundColor: Colors.grey[900],
              title: Text(
                'Enter Player Names',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _player1Controller,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Player 1',
                      labelStyle: TextStyle(color: Colors.blue[300]),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue[300]!),
                      ),
                    ),
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    textInputAction: TextInputAction.next,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _player2Controller,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Player 2',
                      labelStyle: TextStyle(color: Colors.orange[300]),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.orange[300]!),
                      ),
                    ),
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    textInputAction: TextInputAction.done,
                  ),
                  if (errorMessage != null) // Display error message if it exists
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        errorMessage ?? '', // Provide a default empty string
                        style: TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text(
                    'Start Game',
                    style: TextStyle(color: Colors.green),
                  ),
                  onPressed: () {
                    final player1Name = _player1Controller.text.trim();
                    final player2Name = _player2Controller.text.trim();

                    if (player1Name.isEmpty || player2Name.isEmpty) {
                      setState(() {
                        errorMessage = 'Both names must be filled.';
                      });
                    } else if (player1Name == player2Name) {
                      setState(() {
                        errorMessage = 'Player names must be different.';
                      });
                    } else {
                      Navigator.of(context).pop([player1Name, player2Name]);
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGameScreenContent(ExamModeGame game) {
    return Column(
      children: [
        // Header with game info
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Question counter
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  'Q${game.currentQuestion}/20',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade800,
                  ),
                ),
              ),

              // Player indicator
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: game.currentPlayerIndex == 0
                      ? Colors.blue.shade400
                      : Colors.orange.shade400,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  game.players[game.currentPlayerIndex].name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Current game type
        Container(
          margin: EdgeInsets.symmetric(vertical: 8),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: _getGameTypeColor(game.currentGameType),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            game.getCurrentGameTypeLabel(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),

        // Feedback message
        if (game.lastAnswerCorrect != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  game.lastAnswerCorrect!
                      ? Icons.check_circle_outline
                      : Icons.highlight_off,
                  color: game.lastAnswerCorrect! ? Colors.green : Colors.red,
                  size: 32,
                ),
                SizedBox(width: 10),
                Text(
                  game.lastAnswerCorrect! ? 'Correct!' : 'Wrong!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: game.lastAnswerCorrect! ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),

        // Game content
        Expanded(child: _buildGameContent(game)),

        // Score display
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          color: Colors.black.withOpacity(0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: game.players.map((player) {
              return _buildPlayerScore(
                player.name,
                player.score,
                game.players[game.currentPlayerIndex] == player,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerScore(String playerName, int score, bool isActive) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? Colors.blue.shade400 : Colors.black12,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(
            playerName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverScreen(ExamModeGame game) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Game Over',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 30),

          Text(
            'Final Scores',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: game.players.map((player) {
              return _buildFinalScore(
                player.name,
                player.score,
                Colors.blue.shade400,
              );
            }).toList(),
          ),
          SizedBox(height: 20),
          if (widget.isMultiplayer) 
            Text(
              game.players[0].score > game.players[1].score
                  ? '${game.players[0].name} Wins!'
                  : game.players[1].score > game.players[0].score
                      ? '${game.players[1].name} Wins!'
                      : 'It\'s a Tie!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.yellow,
              ),
            ),

          SizedBox(height: 40),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  game.restartGame();
                },
                icon: Icon(Icons.replay),
                label: Text('Play Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  await _soundManager.stopBackgroundMusic();
                  await _soundManager.playHomeMusic();
                  Navigator.pop(context);
                },
                icon: Icon(Icons.home),
                label: Text('Home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinalScore(String player, int score, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(
            player,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          Text(
            '$score',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Color _getGameTypeColor(String type) {
    switch (type) {
      case 'comparison':
        return Colors.red.shade400;
      case 'ordering':
        return Colors.green.shade400;
      case 'composing':
        return Colors.orange.shade400;
      default:
        return Colors.blue.shade400;
    }
  }

  Widget _buildTimerDisplay(ExamModeGame game) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: game.remainingSeconds <= 30
            ? Colors.red.shade400
            : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            color: game.remainingSeconds <= 30
                ? Colors.white
                : Colors.purple.shade800,
            size: 22,
          ),
          SizedBox(width: 8),
          Text(
            '${(game.remainingSeconds ~/ 60).toString().padLeft(2, '0')}:'
            '${(game.remainingSeconds % 60).toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: game.remainingSeconds <= 30
                  ? Colors.white
                  : Colors.purple.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameHeader(ExamModeGame game) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Question counter
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              widget.isMultiplayer 
                  ? 'Q${game.currentQuestion}/10' 
                  : 'Q${game.currentQuestion}/20',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade800,
              ),
            ),
          ),

          // Timer
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: game.remainingSeconds <= 30 
                  ? Colors.red.shade400 
                  : Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer,
                  color: game.remainingSeconds <= 30 
                      ? Colors.white 
                      : Colors.purple.shade800,
                ),
                SizedBox(width: 8),
                Text(
                  '${(game.remainingSeconds ~/ 60).toString().padLeft(2, '0')}:'
                  '${(game.remainingSeconds % 60).toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: game.remainingSeconds <= 30 
                        ? Colors.white 
                        : Colors.purple.shade800,
                  ),
                ),
              ],
            ),
          ),

          // Player indicator
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: game.currentPlayerIndex == 0
                  ? Colors.blue.shade400
                  : Colors.orange.shade400,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              game.players[game.currentPlayerIndex].name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDisplay(ExamModeGame game) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      color: Colors.black.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: game.players.map((player) {
          return _buildPlayerScore(
            player.name,
            player.score,
            game.players[game.currentPlayerIndex] == player,
          );
        }).toList(),
      ),
    );
  }

  void _showPlayerSwitchCountdown(BuildContext context, ExamModeGame game) {
    int initialCount = 3;
    bool dialogActive = true;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final countdownState = _CountdownState(initialCount);
        
        return StatefulBuilder(
          builder: (builderContext, setState) {
            countdownState.timer ??= Timer.periodic(Duration(seconds: 1), (timer) {
                if (!dialogActive) {
                  timer.cancel();
                  countdownState.timer = null;
                  return;
                }
                
                if (dialogActive) {
                  setState(() {
                    countdownState.count--;
                  });
                  
                  if (countdownState.count < 0) {
                    timer.cancel();
                    countdownState.timer = null;
                    
                    if (dialogActive) {
                      dialogActive = false;
                      Navigator.of(dialogContext).pop();
                      
                      // Small delay before switching player
                      Future.delayed(Duration(milliseconds: 100), () {
                        if (mounted) {
                          game.switchToPlayer2();
                        }
                      });
                    }
                  }
                }
              });
            
            return WillPopScope(
              onWillPop: () {
                dialogActive = false;
                if (countdownState.timer != null) {
                  countdownState.timer!.cancel();
                  countdownState.timer = null;
                }
                return Future.value(true);
              },
              child: AlertDialog(
                backgroundColor: Colors.purple.shade900.withOpacity(0.9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${game.players[1].name}'s Turn",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Get ready to solve 10 math puzzles!",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 30),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Center(
                        child: Text(
                          countdownState.count > 0 ? "${countdownState.count}" : "GO!",
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      dialogActive = false;
    });
  }

  void _showPlayer1Countdown(BuildContext context, String playerName) {
    int initialCount = 3;
    bool dialogActive = true;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final countdownState = _CountdownState(initialCount);
        
        return StatefulBuilder(
          builder: (builderContext, setState) {
            countdownState.timer ??= Timer.periodic(Duration(seconds: 1), (timer) {
                if (!dialogActive) {
                  timer.cancel();
                  countdownState.timer = null;
                  return;
                }
                
                if (dialogActive) {
                  setState(() {
                    countdownState.count--;
                  });
                  
                  if (countdownState.count < 0) {
                    timer.cancel();
                    countdownState.timer = null;
                    
                    if (dialogActive) {
                      dialogActive = false;
                      Navigator.of(dialogContext).pop();
                    }
                  }
                }
              });
            
            return WillPopScope(
              onWillPop: () {
                dialogActive = false;
                if (countdownState.timer != null) {
                  countdownState.timer!.cancel();
                  countdownState.timer = null;
                }
                return Future.value(true);
              },
              child: AlertDialog(
                backgroundColor: Colors.blue.shade700.withOpacity(0.9), // Blue for Player 1
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "$playerName's Turn",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Get ready to solve 10 math puzzles!",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 30),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Center(
                        child: Text(
                          countdownState.count > 0 ? "${countdownState.count}" : "GO!",
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700, // Match dialog color
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      dialogActive = false;
    });
  }

  // Add this method for single player countdown
  void _showSinglePlayerCountdown(BuildContext context) {
    int initialCount = 3;
    Timer? countdownTimer;
    
    // This variable helps us track if the dialog was closed early
    bool dialogActive = true;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        // Create the countdown state object
        final countdownState = _CountdownState(initialCount);
        
        return StatefulBuilder(
          builder: (builderContext, setState) {
            // Create timer only once when dialog is shown
            countdownState.timer ??= Timer.periodic(Duration(seconds: 1), (timer) {
                // First check if the dialog is still active
                if (!dialogActive) {
                  timer.cancel();
                  countdownState.timer = null;
                  return;
                }
                
                // Try to update state safely
                if (dialogActive) {
                  setState(() {
                    countdownState.count--;
                  });
                  
                  if (countdownState.count < 0) {
                    timer.cancel();
                    countdownState.timer = null;
                    
                    // Check if dialog is still active before popping
                    if (dialogActive) {
                      dialogActive = false;
                      Navigator.of(dialogContext).pop();
                    }
                  }
                }
              });
            
            return WillPopScope(
              onWillPop: () {
                dialogActive = false;
                if (countdownState.timer != null) {
                  countdownState.timer!.cancel();
                  countdownState.timer = null;
                }
                return Future.value(true);
              },
              child: AlertDialog(
                backgroundColor: Colors.green.shade800.withOpacity(0.9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Get Ready!",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Solve 20 math puzzles to get the highest score!",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 30),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Center(
                        child: Text(
                          countdownState.count > 0 ? "${countdownState.count}" : "GO!",
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      // Ensure timer is cleaned up when dialog is closed
      dialogActive = false;
      if (countdownTimer != null) {
        countdownTimer!.cancel();
        countdownTimer = null;
      }
    });
  }
}

class _CountdownState {
  int count;
  Timer? timer;
  
  _CountdownState(this.count);
}

Widget buildFeedbackMessage(bool? isCorrect) {
  if (isCorrect == null) return SizedBox.shrink();

  return Container(
    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
    decoration: BoxDecoration(
      color: isCorrect ? Colors.green.shade100 : Colors.red.shade100,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(
        color: isCorrect ? Colors.green.shade800 : Colors.red.shade800,
        width: 1,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isCorrect ? Icons.check_circle : Icons.warning_amber_rounded,
          color: isCorrect ? Colors.green.shade700 : Colors.red.shade700,
          size: 24,
        ),
        SizedBox(width: 8),
        Text(
          isCorrect ? 'Correct!' : 'Wrong!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isCorrect ? Colors.green.shade700 : Colors.red.shade700,
          ),
        ),
      ],
    ),
  );
}
