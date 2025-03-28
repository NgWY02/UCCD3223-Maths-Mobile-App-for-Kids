import 'package:flutter/material.dart';
import '../utils/string_utils.dart';

// List of balloon colors
final List<Color> balloonColors = [
  Colors.red.shade400,
  Colors.orange.shade400,
  Colors.green.shade400,
  Colors.purple.shade400,
  Colors.blue.shade400,
  Colors.pink.shade400,
  Colors.teal.shade400,
];

// Widget to build a balloon with a number
Widget buildBalloon(int number, int colorIndex, {VoidCallback? onTap}) {
  final color = balloonColors[colorIndex % balloonColors.length];

  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Balloon string
          Container(width: 2, height: 40, color: Colors.grey.shade700),

          // Balloon
          Container(
            width: 60,
            height: 75,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 5,
                  offset: Offset(2, 3),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Balloon shine
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // Number
                Center(
                  child: Text(
                    '$number',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// Widget for empty balloon spot or hint
Widget buildEmptyBalloonSpot(int? hintNumber, int index) {
  final bool showHint = hintNumber != null;

  return Container(
    margin: EdgeInsets.symmetric(horizontal: 5),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Dashed string
        Container(
          width: 2,
          height: 40,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: Colors.grey.shade400,
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
          ),
        ),

        // Empty balloon or hint
        Container(
          width: 60,
          height: 75,
          decoration: BoxDecoration(
            color: showHint
                ? Colors.yellow.withOpacity(0.7)
                : Colors.grey.shade200.withOpacity(0.7),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: showHint ? Colors.yellow.shade800 : Colors.grey.shade400,
              width: 2,
            ),
          ),
          child: Center(
            child: showHint
                ? Text(
                  '$hintNumber',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                )
                : Icon(Icons.add, color: Colors.grey.shade600, size: 24),
          ),
        ),
      ],
    ),
  );
}

// Widget for number bubble in selection area
Widget buildNumberBubble(int number, bool isUsed, {VoidCallback? onTap}) {
  return GestureDetector(
    onTap: isUsed ? null : onTap,
    child: AnimatedContainer(
      duration: Duration(milliseconds: 200),
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        color: isUsed ? Colors.grey.shade300 : Colors.blue.shade400,
        shape: BoxShape.circle,
        boxShadow: isUsed
            ? []
            : [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 3,
                offset: Offset(0, 2),
              ),
            ],
      ),
      child: Center(
        child: Text(
          '$number',
          style: TextStyle(
            color: isUsed ? Colors.grey.shade600 : Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  );
}

// Widget for decorative clouds
Widget buildClouds() {
  return Stack(
    children: [
      Positioned(top: 20, left: 20, child: buildCloud(80)),
      Positioned(top: 50, right: 40, child: buildCloud(60)),
      Positioned(top: 120, left: 100, child: buildCloud(70)),
    ],
  );
}

// Single cloud widget
Widget buildCloud(double size) {
  return Container(
    width: size,
    height: size * 0.6,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.8),
      borderRadius: BorderRadius.circular(size / 2),
    ),
  );
}

// Instructions dialog
void showInstructions(BuildContext context, String difficulty, int hintsRemaining, int skipsRemaining, bool hasTimeLimit) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue, size: 28),
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
              'Balloon Numbers Game:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 10),
            Text(
              '• Arrange the balloons in the correct order',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              '• Tap a number to place it on the next empty balloon',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              '• Tap a balloon to remove its number',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              '• Use Submit button to check your answer',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              '• Use hints to see the correct number for a position',
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
            
            buildInfoRow(Icons.format_list_numbered, "Balloon Count:", getCountInfo(difficulty)),
            buildInfoRow(Icons.timer, "Time Limit:", hasTimeLimit ? "30 seconds" : "No time limit"),
            buildInfoRow(Icons.lightbulb_outline, "Hints Available:", "$hintsRemaining"),
            buildInfoRow(Icons.skip_next, "Skips Available:", "$skipsRemaining"),
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

// Get count info based on difficulty
String getCountInfo(String difficulty) {
  switch (difficulty.toLowerCase()) {
    case 'easy':
      return "3 numbers (1-10)";
    case 'medium':
      return "4 numbers (1-30)";
    case 'hard':
      return "5 numbers (10-50)";
    default:
      return "4 numbers";
  }
}

