import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService with WidgetsBindingObserver {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;

  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();

  bool _isPlaying = false;
  bool _isPaused = false; // track apakah sedang di-pause (bukan di-stop)
  bool _isEnabled = true;
  bool _initialized = false;

  /// INIT (WAJIB DI MAIN)
  Future<void> init() async {
    if (_initialized) return;

    WidgetsBinding.instance.addObserver(this);

    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('sound_enabled') ?? true;

    await _player.setReleaseMode(ReleaseMode.loop);

    if (_isEnabled) {
      await start();
    }

    _initialized = true;
  }

  /// START MUSIC (dari awal)
  Future<void> start() async {
    if (!_isEnabled || _isPlaying) return;

    await _player.play(AssetSource('sound/background.mp3'));
    _isPlaying = true;
    _isPaused = false;
  }

  /// STOP TOTAL
  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
    _isPaused = false;
  }

  /// PAUSE sementara (pindah halaman / keluar app)
  Future<void> pause() async {
    if (!_isPlaying) return;
    await _player.pause();
    _isPaused = true;
  }

  /// RESUME setelah pause
  Future<void> resume() async {
    if (!_isEnabled) return;

    if (_isPaused) {
      // Lanjut dari posisi terakhir
      await _player.resume();
      _isPaused = false;
    } else if (!_isPlaying) {
      // Belum pernah play, start dari awal
      await start();
    }
  }

  /// TOGGLE DARI SETTING
  Future<void> setEnabled(bool value) async {
    _isEnabled = value;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', value);

    if (value) {
      _isPlaying = false;
      _isPaused = false;
      await start();
    } else {
      await stop();
    }
  }

  /// GETTER
  bool get isEnabled => _isEnabled;
  bool get isPlaying => _isPlaying;

  /// HANDLE APP LIFECYCLE
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      pause();
    } else if (state == AppLifecycleState.resumed) {
      resume();
    }
  }
}
