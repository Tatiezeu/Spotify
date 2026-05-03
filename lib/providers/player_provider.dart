import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../models/song.dart';
import '../services/api_service.dart';

class PlayerProvider extends ChangeNotifier {
  Song? _currentSong;
  List<Song> _queue = [];
  late YoutubePlayerController _controller;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isLooping = false;
  bool _isShuffle = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Set<String> _likedSongIds = {};
  List<Song> _likedSongs = [];
  List<Song> _history = [];

  List<Map<String, dynamic>> _currentLyrics = [];
  bool _isFetchingLyrics = false;

  PlayerProvider() {
    _likedSongIds = {};
    _currentLyrics = [];
    _initController();
    _fetchLikedSongs();
  }

  // Getters
  Song? get currentSong => _currentSong;
  List<Map<String, dynamic>> get currentLyrics => _currentLyrics;
  bool get isFetchingLyrics => _isFetchingLyrics;
  List<Song> get queue => _queue;
  bool get isLooping => _isLooping;
  bool get isShuffle => _isShuffle;
  YoutubePlayerController get controller => _controller;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  Duration get position => _position;
  Duration get duration => _duration;
  Set<String> get likedSongIds => _likedSongIds;
  List<Song> get likedSongs => _likedSongs;
  List<Song> get history => _history;

  bool isLiked(String? songId) {
    if (songId == null) return false;
    try {
      // In some JS environments, initialized sets can occasionally be 
      // seen as undefined during hot-restart cycles.
      return (_likedSongIds).contains(songId);
    } catch (e) {
      return false;
    }
  }

  Future<void> _fetchLikedSongs() async {
    try {
      final likedSongs = await ApiService().getLikedSongs();
      _likedSongs = likedSongs;
      _likedSongIds = likedSongs.map((s) => s.id).toSet();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching liked songs: $e');
    }
  }

  Future<void> toggleLike(Song song) async {
    final success = await ApiService().toggleLikeSong(song);
    if (success) {
      if (_likedSongIds.contains(song.id)) {
        _likedSongIds.remove(song.id);
        _likedSongs.removeWhere((s) => s.id == song.id);
      } else {
        _likedSongIds.add(song.id);
        _likedSongs.add(song);
      }
      notifyListeners();
    }
  }

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
      
      // Auto-advance to next song in queue
      if (value.playerState == PlayerState.ended) {
        if (_isLooping) {
          _controller.seekTo(seconds: 0);
          _controller.playVideo();
        } else {
          playNextInQueue();
        }
      }
      
      notifyListeners();
    });
  }

  void toggleLoop() {
    _isLooping = !_isLooping;
    notifyListeners();
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  void addToQueue(Song song) {
    _queue.add(song);
    notifyListeners();
  }

  void setQueue(List<Song> songs) {
    _queue.clear();
    _queue.addAll(songs);
    notifyListeners();
  }

  void playNext(Song song) {
    _queue.insert(0, song);
    notifyListeners();
  }

  void removeFromQueue(int index) {
    if (index >= 0 && index < _queue.length) {
      _queue.removeAt(index);
      notifyListeners();
    }
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, item);
    notifyListeners();
  }

  void playNextInQueue() {
    if (_queue.isNotEmpty) {
      int nextIndex = 0;
      if (_isShuffle) {
        nextIndex = (DateTime.now().millisecondsSinceEpoch % _queue.length).toInt();
      }
      final nextSong = _queue.removeAt(nextIndex);
      playSong(nextSong);
    } else if (_currentSong != null) {
      // Smart Radio: Fetch suggestions if queue is empty
      _playAutoplaySong();
    }
  }

  Future<void> _playAutoplaySong() async {
    if (_currentSong == null) return;
    
    debugPrint('Queue empty. Starting Smart Radio for: ${_currentSong!.artist}');
    try {
      final suggestions = await ApiService().searchSpotify(_currentSong!.artist);
      if (suggestions.isNotEmpty) {
        // Filter out the current song to avoid repeats
        final filteredSuggestions = suggestions.where((s) => s.id != _currentSong!.id).toList();
        
        if (filteredSuggestions.isNotEmpty) {
          // Shuffle and pick the first one
          filteredSuggestions.shuffle();
          playSong(filteredSuggestions.first);
        } else {
          // If only the current song was found, just play a random one from the original list
          suggestions.shuffle();
          playSong(suggestions.first);
        }
      }
    } catch (e) {
      debugPrint('Autoplay Error: $e');
    }
  }

  void updateCurrentSong(Song song) {
    if (_currentSong?.id == song.id) {
      _currentSong = song;
      notifyListeners();
    }
  }

  Future<void> playSong(Song song) async {
    if (_currentSong?.id == song.id) {
      if (!_isPlaying) resume();
      return;
    }

    // CORE PLAYBACK ORCHESTRATION:
    // 1. Instantly updates the UI state to show the new song metadata (cover, title).
    // 2. Pauses the `youtube_player_iframe` to prevent overlapping audio.
    // 3. Asynchronously fetches lyrics from LRCLIB while keeping the UI responsive.
    // 4. Calls the custom backend `/api/youtube/search` to find the audio stream.
    // 5. Plays the stream natively in the hidden iframe.
    _currentSong = song;
    _currentLyrics = []; // Clear old lyrics
    _addToHistory(song);
    _isLoading = true;
    _isFetchingLyrics = true;
    _position = Duration.zero;
    _duration = Duration.zero;
    
    // Stop the previous video audio immediately
    _controller.pauseVideo();
    notifyListeners();

    // Fetch lyrics in background
    ApiService().getParsedLyrics(song.artist, song.title).then((lyrics) {
      if (_currentSong?.id == song.id) {
        _currentLyrics = lyrics;
        _isFetchingLyrics = false;
        notifyListeners();
      }
    });

    try {
      if (song.artist.isEmpty || song.title.isEmpty) {
        debugPrint('Error: Missing artist or title for playback');
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      debugPrint('Fetching YouTube ID for: ${song.artist} - ${song.title}');
      final videoId = await ApiService().getYoutubeVideoId(song.artist, song.title);
      
      // Verify we are still on the same song after the await
      if (_currentSong?.id == song.id) {
        if (videoId != null) {
          _controller.loadVideoById(videoId: videoId);
          _controller.playVideo();
        } else {
          debugPrint('Error: Could not fetch YouTube ID for ${song.title}');
          _controller.pauseVideo(); // Stop any pending audio
        }
      }
    } catch (e) {
      debugPrint('Error playing song: $e');
      _controller.pauseVideo();
    } finally {
      if (_currentSong?.id == song.id) {
        _isLoading = false;
        notifyListeners();
      }
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
    _controller.seekTo(seconds: position.inSeconds.toDouble(), allowSeekAhead: true);
  }

  void _addToHistory(Song song) {
    _history.removeWhere((s) => s.id == song.id);
    _history.insert(0, song);
    if (_history.length > 50) _history.removeLast();
    notifyListeners();
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }
}
