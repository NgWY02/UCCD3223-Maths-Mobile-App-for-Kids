import 'package:flutter/foundation.dart';
import 'dart:math';
import 'dart:async';
import 'player.dart';


class ExamModeGame extends ChangeNotifier {
  // Add these properties to track question types
  List<String> player1QuestionTypes = [];
  List<String> player2QuestionTypes = [];
  
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

  // Add this to the ExamModeGame class properties
  VoidCallback? onPlayerSwitch;

  // Add a new property to track selected indices
  Set<int> selectedIndices = {};

  ExamModeGame({
    required this.players,
    required this.onPlaySound,
    required this.isMultiplayer,  // Add this parameter
  }) : remainingSeconds = isMultiplayer ? 60 : 120 {  // Initialize based on mode
    // Initialize the question types for both players
    _initializeQuestionTypes();
    generateNextQuestion();
    startTimer();
  }

  void _initializeQuestionTypes() {
    // Create balanced question distribution for each player
    player1QuestionTypes = [];
    player2QuestionTypes = [];
    
    // For first player: 3 of each type + 1 random
    player1QuestionTypes.addAll(['comparison', 'comparison', 'comparison']);
    player1QuestionTypes.addAll(['ordering', 'ordering', 'ordering']);
    player1QuestionTypes.addAll(['composing', 'composing', 'composing']);
    // Add one random question type
    player1QuestionTypes.add(['comparison', 'ordering', 'composing'][_random.nextInt(3)]);
    
    // Shuffle to randomize the order
    player1QuestionTypes.shuffle(_random);
    
    // For multiplayer, initialize player 2's questions
    if (isMultiplayer) {
      player2QuestionTypes.addAll(['comparison', 'comparison', 'comparison']);
      player2QuestionTypes.addAll(['ordering', 'ordering', 'ordering']);
      player2QuestionTypes.addAll(['composing', 'composing', 'composing']);
      player2QuestionTypes.add(['comparison', 'ordering', 'composing'][_random.nextInt(3)]);
      
      // Shuffle player 2's questions
      player2QuestionTypes.shuffle(_random);
    } else {
      // For single player mode, add 10 more questions with the same distribution
      List<String> secondHalf = [];
      secondHalf.addAll(['comparison', 'comparison', 'comparison']);
      secondHalf.addAll(['ordering', 'ordering', 'ordering']);
      secondHalf.addAll(['composing', 'composing', 'composing']);
      secondHalf.add(['comparison', 'ordering', 'composing'][_random.nextInt(3)]);
      secondHalf.shuffle(_random);
      
      // Combine for 20 questions total
      player1QuestionTypes.addAll(secondHalf);
    }
  }

  void generateNextQuestion() {
    isTransitioning = false;
    lastAnswerCorrect = null;
    selectedNumbers.clear();
    selectedIndices.clear(); // Clear selected indices too
    
    // Get game type from the predefined list based on player and question number
    List<String> currentPlayerQuestions = currentPlayerIndex == 0 
        ? player1QuestionTypes 
        : player2QuestionTypes;
    
    // Adjust for 0-based index
    int questionIndex = currentQuestion - 1;
    
    // Safety check
    if (questionIndex < currentPlayerQuestions.length) {
      currentGameType = currentPlayerQuestions[questionIndex];
    } else {
      // Fallback to random if somehow out of bounds
      List<String> gameTypes = ['comparison', 'ordering', 'composing'];
      currentGameType = gameTypes[_random.nextInt(gameTypes.length)];
    }

    switch (currentGameType) {
      case 'comparison':
        // Generate comparison numbers
        do {
          leftNumber = 1 + _random.nextInt(100);
          rightNumber = 1 + _random.nextInt(100);
        } while (leftNumber == rightNumber);
        findBiggerNumber = _random.nextBool();
        break;

      case 'ordering':
        // Generate unique ordering numbers using a Set
        Set<int> uniqueNumbers = {};
        
        // Change these min and max values to adjust the range
        int minOrderingNumber = 1;   
        int maxOrderingNumber = 50;  
        
        while (uniqueNumbers.length < 5) {
          uniqueNumbers.add(minOrderingNumber + 
            _random.nextInt(maxOrderingNumber - minOrderingNumber + 1));
        }
        numbers = uniqueNumbers.toList()..shuffle();
        userPlacedNumbers = List.filled(5, null);
        isAscending = _random.nextBool();
        break;

      case 'composing':
        // Generate target number in range 2-50
        targetNumber = 2 + _random.nextInt(49); // 2 to 50 inclusive
        selectedNumbers.clear();
        selectedIndices.clear();
        
        // Create a guaranteed solution by selecting a valid pair of numbers
        int firstNumber = 1 + _random.nextInt(targetNumber - 1);
        int secondNumber = targetNumber - firstNumber;
        
        // Create a set to avoid duplicate values
        Set<int> uniqueNumbers = {};
        
        // First add our solution numbers
        uniqueNumbers.add(firstNumber);
        uniqueNumbers.add(secondNumber);
        
        // Fill the remaining slots with other numbers
        while (uniqueNumbers.length < 10) {
          // Generate a random number between 1 and 50
          int newNum = 1 + _random.nextInt(50);
          
          // Skip if it's equal to the target (makes it too obvious)
          if (newNum == targetNumber) continue;
          
          // Add the number if it's unique
          uniqueNumbers.add(newNum);
        }
        
        // Convert to list and shuffle
        numberOptions = uniqueNumbers.toList()..shuffle(_random);
        
        // Double-check that our solution numbers are included
        // This ensures we always have a valid solution
        bool containsFirst = numberOptions.contains(firstNumber);
        bool containsSecond = numberOptions.contains(secondNumber);
        
        // If either solution number is missing after shuffling, force them back in
        if (!containsFirst) {
          numberOptions[0] = firstNumber;
        }
        if (!containsSecond) {
          // Make sure we don't replace the first solution number
          int replaceIndex = numberOptions.indexOf(firstNumber) == 1 ? 2 : 1;
          numberOptions[replaceIndex] = secondNumber;
        }
        
        // Verify that the solution exists
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
        
        // If no solution exists, force one
        if (!hasSolution) {
          numberOptions[0] = firstNumber;
          numberOptions[1] = secondNumber;
        }
        
        break;
    }

    notifyListeners();
  }

  // Replace the startTimer method
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
          if (currentPlayerIndex == 0) {
            // First player's time is up, switch to second player
            if (onPlayerSwitch != null) {
              onPlayerSwitch!(); // Trigger the player switch callback
            } else {
              // If no callback is provided, just switch directly
              switchToPlayer2();
            }
          } else {
            // Second player's time is up, end game
            gameOver = true;
            notifyListeners();
          }
        } else {
          // Single player mode
          gameOver = true;
          notifyListeners();
        }
      }
    });
  }

  // Improved player switching method
  void switchToPlayer2() {
    // First, stop any ongoing timers
    _timer?.cancel();
    
    // Update player index
    currentPlayerIndex = 1;
    currentQuestion = 1;
    
    // Reset game state for the new player
    isTransitioning = false;
    lastAnswerCorrect = null;
    selectedNumbers.clear();
    selectedIndices.clear();
    
    // Reset timer
    remainingSeconds = 60;
    
    // Generate a fresh question for player 2
    generateNextQuestion();
    
    // Start timer after everything else is set up
    startTimer();
    
    // Explicitly notify listeners about the change
    notifyListeners();
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
    
    // Regenerate question types for a fresh game
    _initializeQuestionTypes();
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

  // Modify the isIndexSelected method to check indices not values
  bool isIndexSelected(int index) {
    // Check if the index is in our selected indices
    return selectedIndices.contains(index);
  }

  bool isHintNumber(int number) {
    return hintActive && number <= targetNumber;
  }

  // Update the toggleNumber method to track indices
  void toggleNumber(int index) {
    if (!isTransitioning) {
      final number = numberOptions[index];
      
      if (selectedIndices.contains(index)) {
        // Remove this specific index
        selectedIndices.remove(index);
        // Remove one instance of this number from selected numbers
        selectedNumbers.remove(number);
      } else {
        // Add this specific index
        selectedIndices.add(index);
        // Add this number to selected numbers
        selectedNumbers.add(number);
      }
      
      notifyListeners();
    }
  }

  // Update submitAnswer method
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
            if (onPlayerSwitch != null) {
              onPlayerSwitch!(); // Trigger the player switch callback
            } else {
              switchToPlayer2();
            }
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
          selectedIndices.clear(); // Clear indices before next question
          generateNextQuestion();
        }
        notifyListeners();
      });
    }
  }

  // Update selectComparisonNumber method
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
          if (onPlayerSwitch != null) {
            onPlayerSwitch!(); // Trigger the player switch callback
          } else {
            switchToPlayer2();
          }
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

