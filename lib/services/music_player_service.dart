import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models.dart';
import 'user_data_service.dart';

class MusicPlayerService extends ChangeNotifier {
  static final MusicPlayerService _instance = MusicPlayerService._internal();
  factory MusicPlayerService() => _instance;
  
  MusicPlayerService._internal() {
    _initializePlayer();
  }

  final AudioPlayer _audioPlayer = AudioPlayer();
  final UserDataService _userDataService = UserDataService();
  
  MusicItem? _currentSong;
  List<MusicItem> _playlist = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isMinimized = true;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _stateSubscription;
  
  // 記錄播放開始時間
  DateTime? _playStartTime;

  MusicItem? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  bool get isMinimized => _isMinimized;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  bool get hasSong => _currentSong != null;

  void _initializePlayer() {
    // Listen to position changes
    _positionSubscription = _audioPlayer.onPositionChanged.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });

    // Listen to duration changes
    _durationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
      _totalDuration = duration;
      notifyListeners();
    });

    // Listen to player state changes
    _stateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      
      // 記錄播放開始
      if (state == PlayerState.playing && _playStartTime == null) {
        _playStartTime = DateTime.now();
        debugPrint('🎵 開始播放：${_currentSong?.title}');
      }
      
      // 記錄播放完成
      if (state == PlayerState.completed) {
        _recordListeningHistory(completed: true);
        playNext();
      }
      
      notifyListeners();
    });
  }
  
  /// 記錄聽歌歷史
  Future<void> _recordListeningHistory({bool completed = false}) async {
    if (_currentSong == null || _playStartTime == null) return;
    
    try {
      final playDuration = DateTime.now().difference(_playStartTime!).inSeconds;
      
      await _userDataService.addListeningHistory(
        songTitle: _currentSong!.title,
        artist: _currentSong!.artist,
        album: _currentSong!.albumName,
        duration: playDuration,
        completed: completed,
      );
      
      debugPrint('✅ 已記錄播放：${_currentSong!.title} ($playDuration 秒, 完成: $completed)');
      _playStartTime = null; // 重置計時
    } catch (e) {
      debugPrint('❌ 記錄播放失敗: $e');
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _stateSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> playSong(MusicItem song, {List<MusicItem>? playlist, int? index}) async {
    // 記錄上一首歌的播放（如果有的話）
    if (_currentSong != null && _playStartTime != null) {
      await _recordListeningHistory(completed: false);
    }
    
    debugPrint('Playing song: ${song.title} by ${song.artist}');
    _currentSong = song;
    _playStartTime = null; // 重置計時，會在開始播放時設定
    
    if (playlist != null) {
      _playlist = playlist;
      _currentIndex = index ?? 0;
    } else {
      _playlist = [song];
      _currentIndex = 0;
    }
    
    _isMinimized = false;
    
    // Play audio if URL exists
    if (song.audioUrl != null && song.audioUrl!.isNotEmpty) {
      try {
        await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource(song.audioUrl!));
        debugPrint('Audio URL: ${song.audioUrl}');
      } catch (e) {
        debugPrint('Error playing audio: $e');
      }
    } else {
      debugPrint('No audio URL available for this song');
    }
    
    debugPrint('Player state - Playing: $_isPlaying, Minimized: $_isMinimized');
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    debugPrint('Maximized play/pause pressed');
    if (_currentSong == null) return;
    
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  Future<void> playNext() async {
    debugPrint('Next button pressed');
    if (_playlist.isEmpty) return;
    
    _currentIndex = (_currentIndex + 1) % _playlist.length;
    final nextSong = _playlist[_currentIndex];
    await playSong(nextSong, playlist: _playlist, index: _currentIndex);
  }

  Future<void> playPrevious() async {
    debugPrint('Previous button pressed');
    if (_playlist.isEmpty) return;
    
    // If more than 3 seconds into the song, restart it
    if (_currentPosition.inSeconds > 3) {
      await _audioPlayer.seek(Duration.zero);
      return;
    }
    
    _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    final previousSong = _playlist[_currentIndex];
    await playSong(previousSong, playlist: _playlist, index: _currentIndex);
  }

  void toggleMinimize() {
    _isMinimized = !_isMinimized;
    notifyListeners();
  }

  void minimize() {
    _isMinimized = true;
    notifyListeners();
  }

  void maximize() {
    _isMinimized = false;
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  /// 停止播放並清除所有狀態
  Future<void> stop() async {
    // 記錄最後播放的歌曲
    if (_currentSong != null && _playStartTime != null) {
      await _recordListeningHistory(completed: false);
    }
    
    // 停止播放
    await _audioPlayer.stop();
    
    // 清除所有狀態
    _currentSong = null;
    _playlist.clear();
    _currentIndex = 0;
    _isPlaying = false;
    _currentPosition = Duration.zero;
    _totalDuration = Duration.zero;
    _playStartTime = null;
    
    notifyListeners();
    debugPrint('🛑 音樂服務已完全停止並清除狀態');
  }
}
