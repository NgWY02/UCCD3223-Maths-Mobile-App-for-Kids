import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

class NumberOrderingGame extends ChangeNotifier {
  // Game state
  List<int> numbers = [];
  List<int> orderedNumbers = [];
  List<int?> userPlacedNumbers = [];
  bool isAscending = true;
  int score = 0;
  int currentRound = 1;
  int displayRound = 1; // This represents what's shown to the user
  bool gameOver = false;
  bool? lastAnswerCorrect;
  bool success = false;
  bool isTransitioning = false;

  // Game settings
  late int maxRounds;
  int _minNumber = 1;
  int _maxNumber = 10;
  int _hintsRemaining = 0;
  int _skipsRemaining = 0;
  bool _hasTimeLimit = false;
  int _timeLimit = 30; // seconds
  int _remainingTime = 30;
  Timer? _timer;
  int _hintPosition = -1;
  
  final Random random = Random();
  final String difficulty;
  Function(bool)? onPlaySound;
  VoidCallback? onTimerTick;
  
  // Getters
  int get hintsRemaining => _hintsRemaining;
  int get skipsRemaining => _skipsRemaining;
  int get remainingTime => _remainingTime;
  bool get hasTimeLimit => _hasTimeLimit;
  int get hintPosition => _hintPosition;
  
  NumberOrderingGame(this.difficulty, {this.onPlaySound}) {
    _configureDifficulty();
    currentRound = 1;
    displayRound = 1; // Initialize display round
    generateNewRound();
    
    if (_hasTimeLimit) {
      _startTimer();
    }
  }
  
  void _configureDifficulty() {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        maxRounds = 5;
        _minNumber = 1;
        _maxNumber = 10;
        _hintsRemaining = 3;
        _skipsRemaining = 2;
        _hasTimeLimit = false;
        break;
      case 'medium':
        maxRounds = 8;
        _minNumber = 1;
        _maxNumber = 30;
        _hintsRemaining = 2;
        _skipsRemaining = 1;
        _hasTimeLimit = false;
        break;
      case 'hard':
        maxRounds = 10;
        _minNumber = 10;
        _maxNumber = 50;
        _hintsRemaining = 1;
        _skipsRemaining = 1;
        _hasTimeLimit = true;
        _timeLimit = 30; // seconds
        break;
      default:
        maxRounds = 8;
        _minNumber = 1;
        _maxNumber = 30;
        _hintsRemaining = 2;
        _skipsRemaining = 1;
        _hasTimeLimit = false;
    }

    _remainingTime = _timeLimit;
  }
  
  void _startTimer() {
    _timer?.cancel();
    _remainingTime = _timeLimit;

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        _remainingTime--;
        if (onTimerTick != null) onTimerTick!();
        notifyListeners();
      } else {
        timer.cancel();
        // Handle time up - move to next round or end game
        if (!success && !gameOver) {
          lastAnswerCorrect = false;
          if (onPlaySound != null) onPlaySound!(false);
          
          if (currentRound < maxRounds) {
            currentRound++;
            _autoAdvanceToNextRound();
          } else {
            gameOver = true;
          }
          notifyListeners();
        }
      }
    });
  }
  
  void generateNewRound() {
    // Clear previous round data
    numbers = [];
    orderedNumbers = [];
    userPlacedNumbers = [];
    success = false;
    lastAnswerCorrect = null;
    _hintPosition = -1;

    // Randomly decide if ordering should be ascending or descending
    isAscending = random.nextBool();

    // Set fixed number count based on difficulty
    int count;

    // Apply the exact limits requested
    if (difficulty.toLowerCase() == 'easy') {
      count = 3; // Always exactly 3 numbers for easy mode
    } else if (difficulty.toLowerCase() == 'medium') {
      count = 4; // Always exactly 4 numbers for medium mode
    } else {
      count = 5; // Always exactly 5 numbers for hard mode
    }

    // Generate random numbers within the difficulty range
    Set<int> uniqueNumbers = {};
    while (uniqueNumbers.length < count) {
      uniqueNumbers.add(
        _minNumber + random.nextInt(_maxNumber - _minNumber + 1),
      );
    }

    numbers = uniqueNumbers.toList();

    // Create correctly ordered list
    orderedNumbers = List.from(numbers);
    if (isAscending) {
      orderedNumbers.sort();
    } else {
      orderedNumbers.sort((a, b) => b.compareTo(a));
    }

    // Initialize user placed numbers with nulls
    userPlacedNumbers = List.filled(count, null);

    // Reset timer for hard mode
    if (_hasTimeLimit) {
      _startTimer();
    }
    
    notifyListeners();
  }
  
  void placeNumber(int number) {
    if (success) return;
    
    // Find the first empty slot
    int emptyIndex = userPlacedNumbers.indexOf(null);
    if (emptyIndex == -1) return; // No empty slots
    
    // Check if number is already placed somewhere
    int existingIndex = userPlacedNumbers.indexOf(number);
    if (existingIndex != -1) {
      userPlacedNumbers[existingIndex] = null;
    }
    
    // Add to first available position
    userPlacedNumbers[emptyIndex] = number;
    
    // Reset hint position
    _hintPosition = -1;
    
    notifyListeners();
  }
  
  void removeNumber(int position) {
    if (position >= 0 &&
        position < userPlacedNumbers.length &&
        userPlacedNumbers[position] != null) {
      userPlacedNumbers[position] = null;
      notifyListeners();
    }
  }
  
  void submitAnswer() {
    // Only submit if all positions are filled
    if (userPlacedNumbers.contains(null)) return;
    
    // Compare user's order with the correct order
    bool correct = true;
    for (int i = 0; i < orderedNumbers.length; i++) {
      if (userPlacedNumbers[i] != orderedNumbers[i]) {
        correct = false;
        break;
      }
    }

    lastAnswerCorrect = correct;

    if (correct) {
      success = true;
      score++; // Only increment score if correct
      if (onPlaySound != null) onPlaySound!(true);
    } else {
      // Play wrong sound
      if (onPlaySound != null) onPlaySound!(false);
    }

    // Either way (correct or incorrect), advance to next round after a delay
    if (currentRound < maxRounds) {
      currentRound++; // Only increment internal counter, not display counter
      // Auto-advance to next round after delay
      _autoAdvanceToNextRound();
    } else {
      // Game is over
      gameOver = true;
      _timer?.cancel();
    }
    
    notifyListeners();
  }
  
  void _autoAdvanceToNextRound() {
    if (isTransitioning) return;
    isTransitioning = true;

    _timer?.cancel();

    // Wait 1.5 seconds before advancing to next round
    Future.delayed(Duration(milliseconds: 1500), () {
      // Only update displayRound after the delay
      displayRound = currentRound;
      
      generateNewRound();
      isTransitioning = false;
      notifyListeners();
    });
  }
  
  void restartGame() {
    _timer?.cancel();

    score = 0;
    currentRound = 1;
    displayRound = 1; // Reset display round too
    gameOver = false;
    _configureDifficulty(); // Reset hints and skips
    
    generateNewRound();
  }
  
  void useHint() {
    if (_hintsRemaining <= 0 || success) return;

    // Find the first empty position
    int firstEmptyPos = userPlacedNumbers.indexOf(null);
    if (firstEmptyPos == -1) return; // No empty positions

    _hintsRemaining--;
    _hintPosition = firstEmptyPos;
    
    notifyListeners();

    // Auto-hide hint after 2 seconds
    Future.delayed(Duration(seconds: 2), () {
      if (_hintPosition == firstEmptyPos) {
        _hintPosition = -1;
        notifyListeners();
      }
    });
  }
  
  void skipRound() {
    if (_skipsRemaining <= 0) return;

    _timer?.cancel();
    _skipsRemaining--;

    if (currentRound < maxRounds) {
      currentRound++;
      generateNewRound();
    } else {
      gameOver = true;
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
