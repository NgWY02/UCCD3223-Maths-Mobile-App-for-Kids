import 'package:flutter/foundation.dart';
import 'dart:math';
import 'dart:async';
import 'player.dart';


class ExamModeGame extends ChangeNotifier {
  
  
  // Add properties needed for comparison game
  int currentQuestion = 1;
  bool findBiggerNumber = true;
  int leftNumber = 0;
  int rightNumber = 0;
  bool isTransitioning = false;
  bool hintActive = false;
  bool? lastAnswerCorrect;

  // Add properties needed for ordering game
  List<int> numbers = [];
  List<int?> userPlacedNumbers = [];
  bool isAscending = true;
  int? hintPosition;
  List<int> orderedNumbers = [];
  bool success = false;

  // Add properties needed for composing game
  int targetNumber = 0;
  List<int> selectedNumbers = [];
  List<int> numberOptions = [];

  // Common properties
  final List<Player> players;
  final Function(bool) onPlaySound;
  int currentPlayerIndex = 0;
  String currentGameType = 'comparison';
  bool gameOver = false;
  bool hasTimeLimit = true;

  // Add this property
  final Random _random = Random();

  // Add timer properties
  Timer? _timer;
  int remainingSeconds;
  final bool isMultiplayer;

  ExamModeGame({
    required this.players,
    required this.onPlaySound,
    required this.isMultiplayer,  // Add this parameter
  }) : remainingSeconds = isMultiplayer ? 60 : 120 {  // Initialize based on mode
    generateNextQuestion();
    startTimer();
  }

  void generateNextQuestion() {
    isTransitioning = false;
    lastAnswerCorrect = null;
    selectedNumbers.clear();
    
    // Randomly select game type if not cycling
    if (currentQuestion == 1 || currentQuestion % 5 == 0) {
      List<String> gameTypes = ['comparison', 'ordering', 'composing'];
      gameTypes.remove(currentGameType); // Remove current type
      currentGameType = gameTypes[_random.nextInt(gameTypes.length)];
    }

    switch (currentGameType) {
      case 'comparison':
        // Generate comparison numbers
        do {
          leftNumber = 1 + _random.nextInt(50);
          rightNumber = 1 + _random.nextInt(50);
        } while (leftNumber == rightNumber);
        findBiggerNumber = _random.nextBool();
        break;

      case 'ordering':
        // Generate unique ordering numbers using a Set
        Set<int> uniqueNumbers = {};
        while (uniqueNumbers.length < 5) {
          uniqueNumbers.add(1 + _random.nextInt(30));
        }
        numbers = uniqueNumbers.toList()..shuffle();
        userPlacedNumbers = List.filled(5, null);
        isAscending = _random.nextBool();
        break;

      case 'composing':
        // Generate composing numbers
        targetNumber = 5 + _random.nextInt(20);
        
        // Generate unique numbers for options
        Set<int> uniqueNumbers = {};
        while (uniqueNumbers.length < 10) { // Changed to 10 numbers
          uniqueNumbers.add(1 + _random.nextInt(15));
        }
        numberOptions = uniqueNumbers.toList()..shuffle();
        selectedNumbers.clear();
        break;
    }

    notifyListeners();
  }

  void startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        remainingSeconds--;
        notifyListeners();
      } else {
        // Time's up
        _timer?.cancel();
        if (isMultiplayer) {
          // For multiplayer, switch players or end game
          if (currentPlayerIndex == 0 && currentQuestion <= 10) {
            // Switch to player 2
            currentPlayerIndex = 1;
            currentQuestion = 1; // Reset question count for player 2
            remainingSeconds = 60;
            startTimer();
          } else {
            gameOver = true;
          }
        } else {
          // For single player, just end the game
          gameOver = true;
        }
        notifyListeners();
      }
    });
  }

  void selectNumber(int number) {
    // Implement number selection logic
  }

  String getCurrentGameTypeLabel() {
    switch (currentGameType) {
      case 'comparison':
        return 'Number Comparison';
      case 'ordering':
        return 'Number Ordering';
      case 'composing':
        return 'Number Composing';
      default:
        return 'Unknown Game';
    }
  }

  void restartGame() {
    _timer?.cancel();
    currentQuestion = 1;
    currentPlayerIndex = 0;
    gameOver = false;
    remainingSeconds = isMultiplayer ? 60 : 120;
    for (var player in players) {
      player.score = 0;
    }
    generateNextQuestion();
    startTimer();
    notifyListeners();
  }

  // Add methods needed for ordering game
  void removeNumber(int index) {
    if (isTransitioning) return;
    
    if (index >= 0 && index < userPlacedNumbers.length && userPlacedNumbers[index] != null) {
      userPlacedNumbers[index] = null;
      notifyListeners();
    }
  }

  void placeNumber(int number) {
    if (isTransitioning) return;
    
    // Find the first empty slot
    int emptyIndex = userPlacedNumbers.indexOf(null);
    if (emptyIndex == -1) return; // No empty slots
    
    // Place the number in the first empty slot
    userPlacedNumbers[emptyIndex] = number;
    
    // Important: Force a UI refresh here regardless of whether all slots are filled
    notifyListeners();
    
    // The auto-checking code remains but is separate from the UI refresh
    if (!userPlacedNumbers.contains(null)) {
      // Create ordered list for comparison
      List<int> correctOrder = List.from(numbers);
      if (isAscending) {
        correctOrder.sort();
      } else {
        correctOrder.sort((a, b) => b.compareTo(a));
      }
      
      // We're not automatically checking here anymore
      // Instead we'll wait for the user to press the submit button
    }
  }

  bool isIndexSelected(int index) {
    return selectedNumbers.contains(numberOptions[index]);
  }

  bool isHintNumber(int number) {
    return hintActive && number <= targetNumber;
  }

  void toggleNumber(int index) {
    if (!isTransitioning) {
      final number = numberOptions[index];
      if (selectedNumbers.contains(number)) {
        selectedNumbers.remove(number);
      } else {
        selectedNumbers.add(number);
      }
      notifyListeners();
    }
  }

  void submitAnswer() {
    if (!isTransitioning && selectedNumbers.length >= 2) {
      final sum = selectedNumbers.fold(0, (sum, number) => sum + number);
      lastAnswerCorrect = sum == targetNumber;
      onPlaySound(lastAnswerCorrect!);
      isTransitioning = true;
      
      if (lastAnswerCorrect!) {
        // Handle correct answer
        players[currentPlayerIndex].score += 10;
      }
      
      // Move to next question regardless of correct/wrong answer
      Future.delayed(Duration(milliseconds: 1500), () {
        if (isMultiplayer) {
          if (currentQuestion >= 10 && currentPlayerIndex == 0) {
            // First player finished their 10 questions
            currentPlayerIndex = 1;
            currentQuestion = 1;
            remainingSeconds = 60; // Reset timer for second player
            startTimer();
          } else if (currentQuestion >= 10 && currentPlayerIndex == 1) {
            // Second player finished their 10 questions
            gameOver = true;
          } else {
            // Continue with next question
            currentQuestion++;
          }
        } else {
          // Single player mode
          if (currentQuestion >= 20) {
            gameOver = true;
          } else {
            currentQuestion++;
          }
        }
        
        if (!gameOver) {
          generateNextQuestion();
        }
        notifyListeners();
      });
    }
  }

  void selectComparisonNumber(int selectedNumber) {
    if (isTransitioning) return;
    
    int correctNumber = findBiggerNumber
        ? (leftNumber > rightNumber ? leftNumber : rightNumber)
        : (leftNumber < rightNumber ? leftNumber : rightNumber);
    
    lastAnswerCorrect = selectedNumber == correctNumber;
    onPlaySound(lastAnswerCorrect!);
    
    if (lastAnswerCorrect!) {
      players[currentPlayerIndex].score += 10;
    }
    
    isTransitioning = true;
    notifyListeners();

    Future.delayed(Duration(milliseconds: 1000), () {
      if (isMultiplayer) {
        if (currentQuestion >= 10 && currentPlayerIndex == 0) {
          // First player finished their 10 questions
          currentPlayerIndex = 1;
          currentQuestion = 1;
          remainingSeconds = 60; // Reset timer for second player
          startTimer();
        } else if (currentQuestion >= 10 && currentPlayerIndex == 1) {
          // Second player finished their 10 questions
          gameOver = true;
        } else {
          // Continue with next question
          currentQuestion++;
        }
      } else {
        // Single player mode - Fix this condition
        if (currentQuestion >= 20) {  // Changed from >= 1 to >= 20
          gameOver = true;
        } else {
          currentQuestion++;
        }
      }
      
      if (!gameOver) {
        generateNextQuestion();
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ... implement other necessary methods ...
}

