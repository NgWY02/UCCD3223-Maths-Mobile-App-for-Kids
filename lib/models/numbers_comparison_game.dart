import 'package:flutter/material.dart';
import 'dart:math';

class NumberComparisonGame with ChangeNotifier {
  // Game state
  int _score = 0;
  int _currentRound = 1;
  int _leftNumber = 0;
  int _rightNumber = 0;
  bool _findBiggerNumber = true;
  bool _gameOver = false;
  bool _isTransitioning = false;
  bool _hintActive = false;
  int _hintsRemaining = 0;
  int _skipsRemaining = 0;
  int _maxRounds = 0;
  bool? _lastAnswerCorrect;

  // Game settings based on difficulty
  final Random _random = Random();
  late int _minNumber;
  late int _maxNumber;
  late int _timeLimit;

  // Getters
  int get score => _score;
  int get currentRound => _currentRound;
  int get leftNumber => _leftNumber;
  int get rightNumber => _rightNumber;
  bool get findBiggerNumber => _findBiggerNumber;
  bool get gameOver => _gameOver;
  bool get isTransitioning => _isTransitioning;
  bool get hintActive => _hintActive;
  int get hintsRemaining => _hintsRemaining;
  int get skipsRemaining => _skipsRemaining;
  int get maxRounds => _maxRounds;
  bool? get lastAnswerCorrect => _lastAnswerCorrect;
  int get getTimeLimit => _timeLimit;

  // Constructor
  NumberComparisonGame(String difficulty) {
    // Set game parameters based on difficulty
    switch(difficulty.toLowerCase()) {
      case 'easy':
        _minNumber = 1;
        _maxNumber = 20;
        _maxRounds = 8;
        _timeLimit = 0; // No time limit
        _hintsRemaining = 3;
        _skipsRemaining = 2;
        break;
      case 'medium':
        _minNumber = 1;
        _maxNumber = 50;
        _maxRounds = 12;
        _timeLimit = 0; // No time limit
        _hintsRemaining = 2;
        _skipsRemaining = 2;
        break;
      case 'hard':
        _minNumber = 50;
        _maxNumber = 100;
        _maxRounds = 15;
        _timeLimit = 10; // 10 seconds per question
        _hintsRemaining = 1;
        _skipsRemaining = 1;
        break;
      default:
        // Default to medium if invalid difficulty
        _minNumber = 1;
        _maxNumber = 50;
        _maxRounds = 12;
        _timeLimit = 0;
        _hintsRemaining = 2;
        _skipsRemaining = 2;
    }
    
    // Initialize the first round
    prepareNextRound();
  }

  // Generate a new round of numbers
  void prepareNextRound() {
    // Reset state for the new round
    _isTransitioning = false;
    _hintActive = false;
    _lastAnswerCorrect = null;
    
    // Generate two different random numbers
    do {
      _leftNumber = _minNumber + _random.nextInt(_maxNumber - _minNumber + 1);
      _rightNumber = _minNumber + _random.nextInt(_maxNumber - _minNumber + 1);
    } while (_leftNumber == _rightNumber); // Ensure numbers are different
    
    // Randomly decide if we're looking for the bigger or smaller number
    _findBiggerNumber = _random.nextBool();
    
    notifyListeners();
  }

  // Process a player's number selection
  void selectNumber(int selectedNumber) {
    if (_isTransitioning) return; // Prevent multiple selections during transition
    
    int correctNumber;
    if (_findBiggerNumber) {
      correctNumber = _leftNumber > _rightNumber ? _leftNumber : _rightNumber;
    } else {
      correctNumber = _leftNumber < _rightNumber ? _leftNumber : _rightNumber;
    }
    
    // Check if the answer is correct
    bool isCorrect = selectedNumber == correctNumber;
    _lastAnswerCorrect = isCorrect;
    
    if (isCorrect) {
      _score++;
    }
    
    // Start transition to next round
    _isTransitioning = true;
    
    // Check if game is over
    if (_currentRound >= _maxRounds) {
      _gameOver = true;
    } else {
      _currentRound++;
    }
    
    notifyListeners();
  }

  // Use a hint to highlight the correct answer
  bool useHint() {
    if (_hintsRemaining <= 0 || _hintActive) return false;
    
    _hintsRemaining--;
    _hintActive = true;
    notifyListeners();
    return true;
  }

  // Skip the current question
  bool skipQuestion() {
    if (_skipsRemaining <= 0 || _isTransitioning) return false;
    
    _skipsRemaining--;
    _isTransitioning = true;
    
    // Increment round counter without changing score
    if (_currentRound >= _maxRounds) {
      _gameOver = true;
    } else {
      _currentRound++;
    }
    
    notifyListeners();
    return true;
  }

  // Restart the game with the same settings
  void restartGame() {
    _score = 0;
    _currentRound = 1;
    _gameOver = false;
    _isTransitioning = false;
    _hintActive = false;
    _lastAnswerCorrect = null;
    
    // Reset hints and skips based on difficulty
    switch(_maxRounds) {
      case 8: // Easy
        _hintsRemaining = 3;
        _skipsRemaining = 2;
        break;
      case 12: // Medium
        _hintsRemaining = 2;
        _skipsRemaining = 2;
        break;
      case 15: // Hard
        _hintsRemaining = 1;
        _skipsRemaining = 1;
        break;
    }
    
    prepareNextRound();
  }
}