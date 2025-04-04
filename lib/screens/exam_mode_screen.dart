import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exam_mode_game.dart';
import '../models/player.dart';
import '../utils/sound_manager.dart';
import '../widgets/exam_mode_widgets.dart';

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
                  create: (_) => ExamModeGame(
                    players: _players!,
                    onPlaySound: _playSound,
                    isMultiplayer: widget.isMultiplayer, // Add this line
                  ),
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
    return showDialog<List<String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
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
            ],
          ),
          actions: [
            TextButton(
              child: Text(
                'Start Game',
                style: TextStyle(color: Colors.green),
              ),
              onPressed: () {
                if (_player1Controller.text.isNotEmpty &&
                    _player2Controller.text.isNotEmpty) {
                  Navigator.of(context).pop(
                      [_player1Controller.text, _player2Controller.text]);
                }
              },
            ),
          ],
        ),
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
