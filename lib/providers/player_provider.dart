import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../models/song.dart';
import '../services/api_service.dart';

class PlayerProvider extends ChangeNotifier {
  Song? _currentSong;
  late YoutubePlayerController _controller;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  PlayerProvider() {
    _initController();
  }

  // Getters
  Song? get currentSong => _currentSong;
  YoutubePlayerController get controller => _controller;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  Duration get position => _position;
  Duration get duration => _duration;

  void _initController() {
    _controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: false,
        showFullscreenButton: false,
        mute: false,
        showVideoAnnotations: false,
        enableJavaScript: true,
        playsInline: true,
        enableCaption: false,
      ),
    );

    // 1. Listen to position changes (Separate stream in 5.x)
    _controller.videoStateStream.listen((state) {
      _position = state.position;
      notifyListeners();
    });

    // 2. Listen to metadata/state changes
    _controller.listen((value) {
      _duration = value.metaData.duration;
      _isPlaying = value.playerState == PlayerState.playing;
      notifyListeners();
    });
  }

  Future<void> playSong(Song song) async {
    if (_currentSong?.id == song.id) {
      if (!_isPlaying) resume();
      return;
    }

    _currentSong = song;
    _isLoading = true;
    _position = Duration.zero;
    _duration = Duration.zero;
    notifyListeners();

    try {
      debugPrint('Fetching YouTube ID for: ${song.artist} - ${song.title}');
      final videoId = await ApiService().getYoutubeVideoId(song.artist, song.title);
      
      if (videoId != null) {
        _controller.loadVideoById(videoId: videoId);
        // Ensure it starts playing
        _controller.playVideo();
      }
    } catch (e) {
      debugPrint('Error playing song: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void pause() {
    _controller.pauseVideo();
    _isPlaying = false;
    notifyListeners();
  }

  void resume() {
    _controller.playVideo();
    _isPlaying = true;
    notifyListeners();
  }

  void seekTo(Duration position) {
    _controller.seekTo(seconds: position.inSeconds.toDouble());
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }
}
