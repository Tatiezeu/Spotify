import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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

  // Helper to estimate genre based on artist or title keywords for Smart Radio recommendations
  String _estimateGenre(Song song) {
    final title = song.title.toLowerCase();
    final artist = song.artist.toLowerCase();
    
    if (artist.contains('swift') || artist.contains('pop') || title.contains('pop')) return 'Pop';
    if (artist.contains('dadju') || artist.contains('tayc') || artist.contains('wizkid') || artist.contains('burna') || artist.contains('rema') || title.contains('afro') || title.contains('urbaine')) return 'Afrobeats';
    if (artist.contains('eminem') || artist.contains('drake') || artist.contains('kendrick') || artist.contains('cole') || artist.contains('franglish') || title.contains('hip-hop') || title.contains('rap')) return 'Hip-Hop';
    if (title.contains('sleep') || title.contains('lofi') || title.contains('relax') || title.contains('chill')) return 'Lofi/Chill';
    if (song.type == 'podcast' || artist.contains('rogan') || artist.contains('fridman') || artist.contains('huberman') || artist.contains('daily')) return 'Podcast';
    
    return 'General';
  }

  // Calculates a real-time behavioral and content similarity score for Smart Radio
  double _calculateSimilarityScore(Song current, Song candidate) {
    double score = 0;
    
    // 1. Same Artist Boost
    if (current.artist.toLowerCase() == candidate.artist.toLowerCase()) {
      score += 30.0;
    }
    
    // 2. Same Genre Match (collaborative filtering & content classification mockup)
    final currentGenre = _estimateGenre(current);
    final candidateGenre = _estimateGenre(candidate);
    if (currentGenre == candidateGenre && currentGenre != 'General') {
      score += 40.0;
    }
    
    // 3. Keyword Title Similarity
    final currentWords = current.title.toLowerCase().split(RegExp(r'\s+')).where((w) => w.length > 2 && w != 'the' && w != 'and');
    final candidateWords = candidate.title.toLowerCase().split(RegExp(r'\s+')).where((w) => w.length > 2 && w != 'the' && w != 'and');
    int commonWords = 0;
    for (var w in currentWords) {
      if (candidateWords.contains(w)) {
        commonWords++;
      }
    }
    score += commonWords * 15.0;
    
    // 4. User Taste Profile Boost (History & Liked status)
    bool isInHistory = _history.any((s) => s.artist.toLowerCase() == candidate.artist.toLowerCase());
    bool isLikedTrack = isLiked(candidate.id);
    if (isInHistory) score += 10.0;
    if (isLikedTrack) score += 15.0;
    
    // 5. Behavioral Discount: Mock Skip-Rate
    final int hash = candidate.id.hashCode.abs();
    final double mockSkipRate = (hash % 100) / 100.0; // 0.0 to 1.0
    score -= (mockSkipRate * 20.0);
    
    return score;
  }

  Future<void> _playAutoplaySong() async {
    if (_currentSong == null) return;
    
    final current = _currentSong!;
    debugPrint('Queue empty. Starting Smart Radio for: ${current.artist} - ${current.title}');
    try {
      final searchQueries = [current.artist, _estimateGenre(current)];
      List<Song> candidates = [];
      for (var query in searchQueries) {
        if (query.isNotEmpty) {
          final results = await ApiService().searchSpotify(query);
          candidates.addAll(results);
        }
      }
      
      // De-duplicate items and remove the current track
      final uniqueCandidatesMap = <String, Song>{};
      for (var c in candidates) {
        if (c.id != current.id) {
          uniqueCandidatesMap[c.id] = c;
        }
      }
      var pool = uniqueCandidatesMap.values.toList();
      
      if (pool.isNotEmpty) {
        final scoredCandidates = pool.map((song) {
          final score = _calculateSimilarityScore(current, song);
          return _ScoredSong(song, score);
        }).toList();
        
        // Sort descending by calculated similarity score
        scoredCandidates.sort((a, b) => b.score.compareTo(a.score));
        
        debugPrint('--- Autoplay Similarity Ranking for "${current.title}" ---');
        for (var i = 0; i < scoredCandidates.length.clamp(0, 5); i++) {
          final sc = scoredCandidates[i];
          debugPrint('#$i: ${sc.song.artist} - ${sc.song.title} | Score: ${sc.score.toStringAsFixed(1)} (Genre: ${_estimateGenre(sc.song)})');
        }
        debugPrint('---------------------------------------------------------');
        
        if (scoredCandidates.isNotEmpty) {
          playSong(scoredCandidates.first.song);
        }
      } else {
        debugPrint('Smart Radio: No candidates found, repeating current song.');
        playSong(current);
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
    // 2. On Web: mutes and plays synchronously to capture the user gesture for autoplay.
    // 3. On Mobile: pauses the previous video to prevent overlapping audio.
    // 4. Asynchronously fetches lyrics from LRCLIB while keeping the UI responsive.
    // 5. Calls the custom backend `/api/youtube/search` to find the audio stream.
    // 6. Loads the video by ID, unmutes (Web), and plays the stream.
    _currentSong = song;
    _currentLyrics = []; // Clear old lyrics
    _addToHistory(song);
    _isLoading = true;
    _isFetchingLyrics = true;
    _position = Duration.zero;
    _duration = Duration.zero;
    
    if (kIsWeb) {
      // WEB AUTOPLAY UNLOCK:
      // Browsers require a synchronous user-gesture-initiated play() call.
      // We mute first so the browser allows the play, then unmute after loading
      // the actual video. This call must happen BEFORE any async gap (await).
      _controller.mute();
      _controller.playVideo();
    } else {
      // MOBILE: Just stop the previous video audio immediately
      _controller.pauseVideo();
    }
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
          if (kIsWeb) {
            // Unmute after loading the real video content
            _controller.unMute();
          }
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

  void clearQueue() {
    _queue.clear();
    notifyListeners();
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

class _ScoredSong {
  final Song song;
  final double score;
  _ScoredSong(this.song, this.score);
}
