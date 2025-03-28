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
  
  // Enhanced method to play background music
  Future<void> playBackgroundMusic(String assetPath) async {
    try {
      // If the SAME music is already playing AND the player exists, don't restart it
      if (_currentMusic == assetPath && _backgroundPlayer != null) {
        print("Music is already playing: $assetPath - skipping");
        return;
      }
      
      print("Attempting to play: $assetPath (Current: $_currentMusic)");
      
      // Always stop previous music first
      await stopBackgroundMusic();
      
      // Save current music path BEFORE attempting to play
      _currentMusic = assetPath;
      
      // Skip actual playback if sound is off
      if (!_isMusicEnabled) {
        print("Music is disabled, not playing");
        return;
      }
      
      _backgroundPlayer = AudioPlayer();
      await _backgroundPlayer!.play(AssetSource(assetPath));
      await _backgroundPlayer!.setReleaseMode(ReleaseMode.loop);
      print("Now playing: $assetPath");
    } catch (e) {
      print("Error playing background music: $e");
    }
  }
  
  // Dedicated method to play home music
  Future<void> playHomeMusic() async {
    // Extra check - if home music is already playing, don't do anything
    if (_currentMusic == 'sounds/home_music.mp3' && _backgroundPlayer != null) {
      print("Home music is already playing - skipping");
      return;
    }
    
    print("Starting home music");
    await playBackgroundMusic('sounds/home_music.mp3');
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
  
  // Play specific game music
  Future<void> playGameMusic(String gameName) async {
    String musicPath;
    switch (gameName.toLowerCase()) {
      case 'number duel':
        musicPath = 'sounds/number_duel_music.mp3';
        break;
      case 'balloon numbers':
      case 'number ladder': // Add this alias
        musicPath = 'sounds/balloon_numbers_music.mp3';
        break;
      case 'build a number':
        musicPath = 'sounds/build_number_music.mp3';
        break;
      default:
        musicPath = 'sounds/game_music.mp3'; // fallback
    }
    await playBackgroundMusic(musicPath);
  }
  
  // Restore home music method (used when returning from games)
  Future<void> restoreHomeMusic() async {
    await playHomeMusic();
  }
  
  // Robust method to stop background music
  Future<void> stopBackgroundMusic() async {
    if (_backgroundPlayer != null) {
      print("Stopping previous music: $_currentMusic");
      try {
        await _backgroundPlayer!.stop();
        await _backgroundPlayer!.dispose();
      } catch (e) {
        print("Error stopping music: $e");
      } finally {
        _backgroundPlayer = null;
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
}