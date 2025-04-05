import 'package:flutter/material.dart';
import '../utils/string_utils.dart';

// Widget to build the target number display
Widget buildTargetDisplay(int target) {
  return Container(
    width: 120,
    height: 120,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.orange.shade400, Colors.amber.shade300],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: Colors.amber.withValues(alpha:0.4),
          blurRadius: 12,
          spreadRadius: 2,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        // Decorative circles
        Positioned(
          top: 15,
          left: 15,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
          ),
        ),
        
        // Target text
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'TARGET',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '$target',
                style: const TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// Widget for the current sum display
Widget buildSumDisplay(int currentSum, int targetNumber) {
  Color textColor;
  IconData icon;
  
  if (currentSum > targetNumber) {
    textColor = Colors.red.shade700;
    icon = Icons.arrow_upward;
  } else if (currentSum == targetNumber) {
    textColor = Colors.green.shade700;
    icon = Icons.check_circle;
  } else {
    textColor = Colors.black87;
    icon = Icons.add;
  }
  
  return Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 7,
          offset: const Offset(0, 3),
        ),
      ],
      border: Border.all(
        color: currentSum == targetNumber 
            ? Colors.green.shade300 
            : currentSum > targetNumber
                ? Colors.red.shade300
                : Colors.grey.shade300,
        width: 2,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: textColor, size: 20),
        const SizedBox(width: 10),
        Text(
          'Sum: $currentSum',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    ),
  );
}

// Widget for number tiles
Widget buildNumberTile({
  required int number,
  required bool isSelected,
  required bool isHintNumber,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        gradient: isSelected 
            ? LinearGradient(
                colors: [Colors.amber.shade300, Colors.orange.shade300],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isSelected ? null : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isHintNumber ? Colors.yellow.withValues(alpha: 0.8) : Colors.black12,
            blurRadius: isHintNumber ? 10 : 3,
            spreadRadius: isHintNumber ? 1 : 0,
            offset: const Offset(0, 2),
          ),
        ],
        border: isSelected 
            ? Border.all(color: Colors.orange.shade600, width: 3) 
            : isHintNumber
                ? Border.all(color: Colors.yellow.shade600, width: 2)
                : Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isSelected)
            Positioned(
              top: 5,
              right: 5,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          
          Center(
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.brown.shade800 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// Widget for feedback message
Widget buildFeedbackMessage(bool? lastAnswerCorrect) {
  if (lastAnswerCorrect == null) return SizedBox.shrink();
  
  return AnimatedOpacity(
    opacity: 1.0,
    duration: Duration(milliseconds: 300),
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: lastAnswerCorrect 
            ? Colors.green.shade100 
            : Colors.red.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: lastAnswerCorrect 
              ? Colors.green.shade600 
              : Colors.red.shade600,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            lastAnswerCorrect 
                ? Icons.check_circle_outline 
                : Icons.highlight_off,
            color: lastAnswerCorrect 
                ? Colors.green.shade700 
                : Colors.red.shade700,
            size: 20,
          ),
          SizedBox(width: 6),
          Text(
            lastAnswerCorrect 
                ? 'Correct! Good job!' 
                : 'Not quite right!',
            style: TextStyle(
              fontSize:  18,
              fontWeight: FontWeight.bold,
              color: lastAnswerCorrect 
                  ? Colors.green.shade700 
                  : Colors.red.shade700,
            ),
          ),
        ],
      ),
    ),
  );
}


// Show instructions dialog
void showBuildNumberInstructions(BuildContext context, String difficulty, int hintsRemaining, int skipsRemaining) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange, size: 28),
          SizedBox(width: 10),
          Text('How to Play'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Build a Number Game:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              '• Select numbers that add up to the target',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              '• You must select at least 2 numbers',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              '• Tap a selected number to unselect it',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              '• Click Submit when you are ready to check',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 15),
            
            Text(
              'Difficulty: ${difficulty.capitalize()}',
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 18, 
                color: getDifficultyColor(difficulty),
              ),
            ),
            SizedBox(height: 10),
            
            buildInfoRow(Icons.filter_9_plus, "Target Range:", getDifficultyRange(difficulty)),
            buildInfoRow(Icons.lightbulb_outline, "Hints Available:", "$hintsRemaining"),
            buildInfoRow(Icons.skip_next, "Skips Available:", "$skipsRemaining"),

            if (difficulty.toLowerCase() == 'hard')
              buildInfoRow(Icons.timer, "Time Limit:", "20 seconds per round"),
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

// Helper for instruction dialog
Widget buildInfoRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
        ),
        SizedBox(width: 5),
        Text(
          value,
          style: TextStyle(fontSize: 15),
        ),
      ],
    ),
  );
}

// Get color for difficulty
Color getDifficultyColor(String difficulty) {
  switch (difficulty.toLowerCase()) {
    case 'easy':
      return Colors.green;
    case 'medium':
      return Colors.orange;
    case 'hard':
      return Colors.red;
    default:
      return Colors.blue;
  }
}

// Get difficulty range description
String getDifficultyRange(String difficulty) {
  switch (difficulty.toLowerCase()) {
    case 'easy':
      return "2-10";
    case 'medium':
      return "2-30";
    case 'hard':
      return "2-50";
    default:
      return "2-10";
  }
}