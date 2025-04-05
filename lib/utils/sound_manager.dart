import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  
  factory SoundManager() {
    return _instance;
  }
  
  SoundManager._internal();
  
  AudioPlayer? _backgroundPlayer;
  String? _currentMusic;
  bool _isMusicEnabled = true;

  
  bool get isMusicEnabled => _isMusicEnabled;
  String? get currentMusic => _currentMusic;
  
  // Fix playBackgroundMusic to use _playMusic
  Future<void> playBackgroundMusic(String assetPath) async {
    try {
      // Don't play music if we're in the name input dialog
      if (_currentMusic == "disabled_during_setup") {
        print("Music disabled during player setup - skipping playback");
        return;
      }
      
      // If the same music is already playing, don't restart it
      if (_currentMusic == assetPath && _backgroundPlayer != null) {
        print("Music already playing: $assetPath - skipping");
        return;
      }
      
      print("Attempting to play: $assetPath (Current: $_currentMusic)");
      
      // Skip actual playback if sound is off
      if (!_isMusicEnabled) {
        print("Music is disabled, not playing");
        _currentMusic = assetPath; // Still update current music
        return;
      }
      
      await _playMusic(assetPath);
      _currentMusic = assetPath;
    } catch (e) {
      print("Error playing background music: $e");
    }
  }
  
  // Fix playHomeMusic to be more consistent
  Future<void> playHomeMusic() async {
    if (!_isMusicEnabled) return;
    
    // Only change music if we're not already playing home music
    if (_currentMusic != 'sounds/home_music.mp3') {
      print("Playing home music");
      await stopBackgroundMusic();
      await playBackgroundMusic('sounds/home_music.mp3');
    }
  }
  
  // Additional method to ensure single music instance when navigating
  Future<void> ensureHomeMusic() async {
    // Only start home music if it's not already playing
    if (_currentMusic != 'sounds/home_music.mp3') {
      print("Ensuring home music is playing");
      await playHomeMusic();
    } else {
      print("Home music already playing - no action needed");
    }
  }
  
  // Fix the playGameMusic method to correctly identify exam mode music
  Future<void> playGameMusic(String gameName) async {
    if (!_isMusicEnabled) return;
    
    print("Request to play game music: $gameName");
    
    // Skip if music is disabled during setup
    if (_currentMusic == "disabled_during_setup") {
      print("Music is disabled during setup - ignoring request");
      return;
    }
    
    // Always stop current music first
    await stopBackgroundMusic();
    
    String musicPath;
    switch (gameName) {
      case 'Exam_Mode':
        musicPath = 'sounds/exam_mode_music.mp3';
        break;
      case 'Number_Comparison':
        musicPath = 'sounds/number_comparison_music.mp3';
        break;
      case 'Number_Ordering':
        musicPath = 'sounds/number_ordering_music.mp3';
        break;
      case 'Number_Composing':
        musicPath = 'sounds/number_composing_music.mp3';
        break;
      default:
        musicPath = 'sounds/home_music.mp3';
    }
    
    print("Playing game music: $musicPath for game: $gameName");
    await _playMusic(musicPath);
    _currentMusic = musicPath;  // Store the path, not the game name
  }
  
  // Restore home music method (used when returning from games)
  Future<void> restoreHomeMusic() async {
    await playHomeMusic();
  }
  
  
  // Robust method to stop background music
  Future<void> stopBackgroundMusic() async {
    if (_backgroundPlayer != null) {
      try {
        await _backgroundPlayer!.stop();
        await _backgroundPlayer!.dispose();
        _backgroundPlayer = null;
        _currentMusic = null;
      } catch (e) {
        print("Error stopping music: $e");
      }
    }
  }
  
  // Fixed toggle music method that prevents crashes
  void toggleMusic() {
    _isMusicEnabled = !_isMusicEnabled;
    print("Music toggled to: ${_isMusicEnabled ? 'ON' : 'OFF'}");
    
    try {
      if (_isMusicEnabled) {
        // Resume playing current music if there is any
        if (_currentMusic != null) {
          playBackgroundMusic(_currentMusic!);
        } else {
          playHomeMusic();
        }
      } else {
        // Just stop the music when toggling off
        stopBackgroundMusic();
      }
    } catch (e) {
      print("Error toggling music: $e");
    }
  }

  // Play button sound effect - using a simpler approach
  Future<void> playButtonSound() async {
    if (!_isMusicEnabled) return;
    
    try {
      final effectPlayer = AudioPlayer();
      await effectPlayer.play(AssetSource('sounds/button_click.mp3'));
      
      // Just use the delayed disposal approach - it's more reliable
      Future.delayed(Duration(milliseconds: 1000), () {
        try {
          effectPlayer.dispose();
        } catch (e) {
          print("Error disposing effect player: $e");
        }
      });
    } catch (e) {
      print("Error playing button sound: $e");
    }
  }
  
  // Play game sound effects - simplified
  Future<void> playGameSound(String assetPath) async {
    if (!_isMusicEnabled) return;
    
    try {
      final effectPlayer = AudioPlayer();
      await effectPlayer.play(AssetSource(assetPath));
      
      // Just use the delayed disposal approach
      Future.delayed(Duration(milliseconds: 2000), () {
        try {
          effectPlayer.dispose();
        } catch (e) {
          print("Error disposing effect player: $e");
        }
      });
    } catch (e) {
      print("Error playing game sound: $e");
    }
  }
  
  // Cleanup resources
  Future<void> dispose() async {
    await stopBackgroundMusic();
  }

  // Add this method to SoundManager class
  void disableMusicDuringSetup() {
    _currentMusic = "disabled_during_setup";
  }

  void enableMusic() {
  print("Enabling music again");
  _currentMusic = null; // Clear the disabled flag
}

// Add a new low-level method to actually play the music
Future<void> _playMusic(String assetPath) async {
  try {
    if (_backgroundPlayer != null) {
      await _backgroundPlayer!.stop();
      await _backgroundPlayer!.dispose();
      _backgroundPlayer = null;
    }
    
    _backgroundPlayer = AudioPlayer();
    await _backgroundPlayer!.play(AssetSource(assetPath));
    await _backgroundPlayer!.setReleaseMode(ReleaseMode.loop);
    print("Now playing: $assetPath");
  } catch (e) {
    print("Error playing music: $e");
  }
}

// Updated forceExamModeMusic method
Future<void> forceExamModeMusic() async {
  // First check if music is enabled
  if (!_isMusicEnabled) {
    print("Music is disabled, not starting exam mode music");
    _currentMusic = 'sounds/exam_mode_music.mp3'; // Still update the current music
    return;
  }
  
  // Stop any existing player first
  if (_backgroundPlayer != null) {
    try {
      await _backgroundPlayer!.stop();
      await _backgroundPlayer!.dispose();
    } catch (e) {
      print("Error stopping previous music: $e");
    }
    _backgroundPlayer = null;
  }
  
  try {
    // Create new player and play directly
    final player = AudioPlayer();
    await player.setReleaseMode(ReleaseMode.loop);
    await player.play(AssetSource('sounds/exam_mode_music.mp3'));
    
    // Only assign to _backgroundPlayer after successful playback
    _backgroundPlayer = player;
    _currentMusic = 'sounds/exam_mode_music.mp3';
    print("✓ Successfully started exam mode music");
  } catch (e) {
    print("ERROR playing exam mode music: $e");
  }
}
}