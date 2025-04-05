import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

class NumberComposingGame extends ChangeNotifier {
  int targetNumber = 0;
  List<int> numberOptions = [];
  List<int> selectedNumbers = [];
  Set<int> selectedIndices = {};
  int score = 0;
  int currentRound = 1;
  int displayRound = 1; // Add this new property
  bool gameOver = false;
  bool? lastAnswerCorrect;
  int maxRounds = 10;
  bool isTransitioning = false;
  
  // Timer functionality
  bool _hasTimeLimit = false;
  int _timeLimit = 30; // seconds
  int _remainingTime = 30;
  Timer? _timer;
  
  // Hint and skip functionality
  int _hintsRemaining = 0;
  int _skipsRemaining = 0;
  bool hintActive = false;
  List<int> hintNumbers = [];
  String? _difficulty;
  
  // Callbacks
  Function(bool)? onPlaySound;
  VoidCallback? onTimerTick;
  
  // Getters
  int get hintsRemaining => _hintsRemaining;
  int get skipsRemaining => _skipsRemaining;
  bool get hasTimeLimit => _hasTimeLimit;
  int get remainingTime => _remainingTime;
  
  // Difficulty parameters
  int _minTargetNumber = 2; // Changed from 1 to 2 to avoid impossible target=1
  int _maxTargetNumber = 10;
  final int _optionsCount = 10;
  
  final Random random = Random();
  
  NumberComposingGame(String difficulty, {this.onPlaySound}) {
    _difficulty = difficulty;
    _configureDifficulty(difficulty);
    generateNewRound();
  }
  
  void _configureDifficulty(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        _minTargetNumber = 2;  // Min 2 to avoid impossible target=1
        _maxTargetNumber = 10;
        maxRounds = 8;
        _hintsRemaining = 3;
        _skipsRemaining = 2;
        _hasTimeLimit = false; // No time limit for easy
        break;
      case 'medium':
        _minTargetNumber = 2;  // Min 2 to avoid impossible target=1
        _maxTargetNumber = 30;
        maxRounds = 12;
        _hintsRemaining = 2;
        _skipsRemaining = 1;
        _hasTimeLimit = false; // No time limit for medium
        break;
      case 'hard':
        _minTargetNumber = 2;  // Min 2 to avoid impossible target=1
        _maxTargetNumber = 50;
        maxRounds = 15;
        _hintsRemaining = 1;
        _skipsRemaining = 1;
        _hasTimeLimit = true; // Add time limit for hard mode
        _timeLimit = 30; // 20 seconds per round for hard mode
        break;
      default:
        _minTargetNumber = 2;
        _maxTargetNumber = 10;
        maxRounds = 8;
        _hintsRemaining = 3;
        _skipsRemaining = 2;
        _hasTimeLimit = false;
    }
    _remainingTime = _timeLimit; // Initialize remaining time
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
        // Time's up - auto-submit with a "wrong" result
        if (!gameOver && !isTransitioning) {
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
    try {
      // Generate target number between min and max (avoiding 1)
      targetNumber = _minTargetNumber + random.nextInt(_maxTargetNumber - _minTargetNumber + 1);
      
      // Clear previous selections
      selectedNumbers = [];
      selectedIndices = {};
      numberOptions = [];
      hintNumbers = [];
      hintActive = false;
      lastAnswerCorrect = null;
      
      // Create a valid solution pair that sums to target
      int maxFirstNumber = targetNumber - 1; // Ensure secondNumber is at least 1
      int firstNumber = 1 + random.nextInt(maxFirstNumber);
      int secondNumber = targetNumber - firstNumber;
      
      // Start with our guaranteed solution pair
      List<int> numbers = [];
      
      // Add solution numbers to the list
      numbers.add(firstNumber);
      numbers.add(secondNumber);
      
      // Set hint numbers
      hintNumbers = [firstNumber, secondNumber];
      
      // Add more random numbers to fill our options
      int maxOption;
      // Adjust the range based on difficulty
      if (_difficulty == 'easy') {
        maxOption = 10; // Easy mode: numbers 1-10
      } else if (_difficulty == 'medium') {
        maxOption = min(30, targetNumber * 2); // Medium: reasonable range
      } else {
        maxOption = min(50, targetNumber * 3); // Hard: wider range
      }
      
      int attempts = 0;
      while (numbers.length < _optionsCount && attempts < 100) {
        // Generate numbers appropriate for the target
        int newNum = 1 + random.nextInt(maxOption);
        
        // Skip the target number itself - we don't want players to just select it
        if (newNum == targetNumber) continue;
        
        // Avoid too many duplicates
        if (numbers.where((n) => n == newNum).length < 2) {
          numbers.add(newNum);
        }
        attempts++;
      }
      
      // If we still need more numbers, just add some small ones
      while (numbers.length < _optionsCount) {
        int newNum = 1 + random.nextInt(5);
        numbers.add(newNum);
      }
      
      // Shuffle and assign to options
      numbers.shuffle();
      numberOptions = numbers;
      
      // Double-check that our solution numbers are included
      bool hasFirst = numberOptions.contains(firstNumber);
      bool hasSecond = numberOptions.contains(secondNumber);
      
      // If either solution number is missing, replace random elements
      if (!hasFirst) {
        int replaceIndex = random.nextInt(numberOptions.length);
        numberOptions[replaceIndex] = firstNumber;
      }
      
      if (!hasSecond) {
        // Find a position that doesn't have the first solution number
        int replaceIndex;
        do {
          replaceIndex = random.nextInt(numberOptions.length);
        } while (numberOptions[replaceIndex] == firstNumber);
        
        numberOptions[replaceIndex] = secondNumber;
      }
      
      // Verify we have a solution
      bool hasSolution = false;
      for (int i = 0; i < numberOptions.length; i++) {
        for (int j = i + 1; j < numberOptions.length; j++) {
          if (numberOptions[i] + numberOptions[j] == targetNumber) {
            hasSolution = true;
            break;
          }
        }
        if (hasSolution) break;
      }
      
      // If still no solution, force one
      if (!hasSolution) {
        numberOptions[0] = firstNumber;
        numberOptions[1] = secondNumber;
      }
      
      // Start timer if needed
      if (_hasTimeLimit) {
        _startTimer();
      }
      
      notifyListeners();
    } catch (e) {
      print("Error in generateNewRound: $e");
      // Fallback values for stability
      targetNumber = 5;
      numberOptions = [1, 2, 3, 4, 6, 7, 8, 9, 2, 3];
      hintNumbers = [2, 3];
    }
  }
  
  // Toggle selection by index instead of value
  void toggleNumber(int index) {
    try {
      if (index < 0 || index >= numberOptions.length) return;
      
      int value = numberOptions[index];
      
      if (selectedIndices.contains(index)) {
        // Unselect this index
        selectedIndices.remove(index);
        selectedNumbers.remove(value);
      } else {
        // Select this index
        selectedIndices.add(index);
        selectedNumbers.add(value);
      }
      
      notifyListeners();
    } catch (e) {
      print("Error toggling number: $e");
    }
  }
  
  bool useHint() {
    if (_hintsRemaining > 0 && !hintActive) {
      _hintsRemaining--;
      hintActive = true;
      notifyListeners();
      
      Future.delayed(Duration(milliseconds: 2000), () {
        if (!gameOver) {
          hintActive = false;
          notifyListeners();
        }
      });
      return true;
    }
    return false;
  }
  
  bool skipQuestion() {
    if (_skipsRemaining > 0) {
      _skipsRemaining--;
      
      // Stop the timer
      _timer?.cancel();
      
      if (currentRound < maxRounds) {
        currentRound++;
        lastAnswerCorrect = null;
        generateNewRound();
      } else {
        gameOver = true;
      }
      
      notifyListeners();
      return true;
    }
    return false;
  }
  
  void submitAnswer() {
    if (selectedNumbers.length < 2) return;
    if (isTransitioning) return; // Add this guard
    
    // Stop the timer
    _timer?.cancel();
    
    int sum = selectedNumbers.fold(0, (sum, number) => sum + number);
    isTransitioning = true; // Set this before showing feedback
    
    if (sum == targetNumber) {
      // Correct answer
      lastAnswerCorrect = true;
      if (onPlaySound != null) onPlaySound!(true);
      score++;
      
      if (currentRound < maxRounds) {
        currentRound++;
        _autoAdvanceToNextRound();
      } else {
        gameOver = true;
      }
    } else {
      // Wrong answer
      lastAnswerCorrect = false;
      if (onPlaySound != null) onPlaySound!(false);
      
      if (currentRound < maxRounds) {
        currentRound++;
        _autoAdvanceToNextRound();
      } else {
        gameOver = true;
      }
    }
    
    notifyListeners();
  }

  void _autoAdvanceToNextRound() {
      // Wait a moment, then update round and show new question
      Future.delayed(Duration(milliseconds: 1500), () {
        displayRound = currentRound;
        generateNewRound();
        isTransitioning = false;
        notifyListeners();
      });
  }
  
  
  void restartGame() {
    // First, handle any ongoing transitions or timers
    isTransitioning = false;  // Reset transition state first
    _timer?.cancel();  // Cancel any running timer
    
    // Reset all game states
    score = 0;
    currentRound = 1;
    displayRound = 1;
    gameOver = false;
    lastAnswerCorrect = null;
    selectedNumbers = [];
    selectedIndices = {};
    hintActive = false;
    
    // Reconfigure difficulty settings
    _configureDifficulty(_difficulty ?? 'easy');
    
    // Generate new round after a short delay to ensure clean state
    Future.delayed(Duration(milliseconds: 100), () {
      generateNewRound();
      notifyListeners();
    });
  }
  
  bool isHintNumber(int number) {
    return hintActive && hintNumbers.contains(number);
  }
  
  // Check if an index is selected
  bool isIndexSelected(int index) {
    return selectedIndices.contains(index);
  }
  
  int getCurrentSum() {
    return selectedNumbers.isEmpty 
      ? 0 
      : selectedNumbers.fold(0, (sum, number) => sum + number);
  }
}