class Player {
  final String name;
  int score = 0;
  int questionsAnswered = 0;
  List<String> gameResults = []; // Store results of each question
  
  Player(this.name);
  
  void addResult(bool correct) {
    gameResults.add(correct ? '✓' : '✗');
    if (correct) score++;
    questionsAnswered++;
  }
  
  bool get isDone => questionsAnswered >= 10;
}