import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../models/playlist.dart';

class ApiService {
  static const String baseUrl = 'http://172.20.10.3:5001/api';
  
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _playlistUpdateController = StreamController<void>.broadcast();
  Stream<void> get onPlaylistsChanged => _playlistUpdateController.stream;

  void notifyPlaylistsChanged() {
    _playlistUpdateController.add(null);
  }

  final _profileUpdateController = StreamController<void>.broadcast();
  Stream<void> get onProfileChanged => _profileUpdateController.stream;

  void notifyProfileChanged() {
    _profileUpdateController.add(null);
  }

  String? _token;
  String? _firstname;
  String? _email;
  String? _profileImagePath;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
    _firstname = prefs.getString('firstname');
    _email = prefs.getString('email');
    _profileImagePath = prefs.getString('profile_image_path');
    print('ApiService initialized. Token: ${_token != null ? "Loaded" : "Not Found"}');
  }
  
  void setToken(String token) {
    _token = token;
  }

  String get firstname => _firstname ?? 'User';
  String get email => _email ?? '';
  String? get profileImagePath => _profileImagePath;

  Future<void> updateProfileImage(String path) async {
    _profileImagePath = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_image_path', path);
    notifyProfileChanged();
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // --- Authentication ---
  
  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _firstname = data['firstname'];
        _email = data['email'];
        print('Login Successful. Token set for requests.');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', _token!);
        if (_firstname != null) await prefs.setString('firstname', _firstname!);
        if (_email != null) await prefs.setString('email', _email!);
        return true;
      }
    } catch (e) {
      print('Login Error: $e');
    }
    return false;
  }

  Future<bool> register(String firstname, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'firstname': firstname, 'email': email, 'password': password}),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _firstname = data['firstname'];
        _email = data['email'];
        print('Registration Successful. Token set for requests.');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', _token!);
        if (_firstname != null) await prefs.setString('firstname', _firstname!);
        if (_email != null) await prefs.setString('email', _email!);
        return true;
      }
    } catch (e) {
      print('Register Error: $e');
    }
    return false;
  }

  Future<void> logout() async {
    _token = null;
    _firstname = null;
    _email = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('firstname');
    await prefs.remove('email');
  }

  bool get isLoggedIn => _token != null;

  // --- Spotify Search ---
  
  Future<List<Song>> searchSpotify(String query, {String type = 'track'}) async {
    if (query.isEmpty) return [];
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/spotify/search?q=${Uri.encodeComponent(query)}&type=$type&limit=50'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        List items = [];
        if (type.contains('track')) {
          items.addAll(data['tracks']?['items'] as List? ?? []);
        }
        if (type.contains('artist') && !type.contains('track')) {
          items.addAll(data['artists']?['items'] as List? ?? []);
        }
        if (type.contains('album') && !type.contains('track') && !type.contains('artist')) {
          items.addAll(data['albums']?['items'] as List? ?? []);
        }

        return items.map((item) => Song.fromJson(item)).toList();
      }
    } catch (e) {
      print('Spotify Search Error: $e');
    }
    return [];
  }

  Future<List<Song>> getRelatedArtists(String artistId) async {
    if (artistId.isEmpty) return [];
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/spotify/artist/$artistId/related-artists'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List items = data['artists'] ?? [];
        return items.map((item) => Song.fromJson({...item, 'type': 'artist'})).toList();
      }
    } catch (e) {
      print('Related Artists Error: $e');
    }
    return [];
  }

  Future<List<Song>> searchDeezer(String query) async {
    if (query.isEmpty) return [];
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/deezer/search?q=${Uri.encodeComponent(query)}'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List items = data['tracks'] ?? [];
        return items.map((item) => Song.fromJson(item)).toList();
      }
    } catch (e) {
      print('Deezer Search Error: $e');
    }
    return [];
  }

  Future<String> getLyrics(String artist, String title) async {
    try {
      final url = 'https://lrclib.net/api/get?artist_name=${Uri.encodeComponent(artist)}&track_name=${Uri.encodeComponent(title)}';
      print('Fetching lyrics from: $url');
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['syncedLyrics'] ?? data['plainLyrics'] ?? 'Lyrics not available.';
      } else {
        print('LRCLIB Lyrics failed with status: ${response.statusCode}');
        // Try a search if exact match fails
        final searchUrl = 'https://lrclib.net/api/search?q=${Uri.encodeComponent("$artist $title")}';
        final searchRes = await http.get(Uri.parse(searchUrl));
        if (searchRes.statusCode == 200) {
          final List results = jsonDecode(searchRes.body);
          if (results.isNotEmpty) {
            return results[0]['syncedLyrics'] ?? results[0]['plainLyrics'] ?? 'Lyrics not available.';
          }
        }
      }
    } catch (e) {
      print('LRCLIB Lyrics Error: $e');
    }
    return 'Lyrics not available.';
  }

  Future<List<Map<String, dynamic>>> getParsedLyrics(String artist, String title) async {
    final lyrics = await getLyrics(artist, title);
    if (lyrics == 'Lyrics not available.') return [];
    
    final List<Map<String, dynamic>> parsed = [];
    final lines = lyrics.split('\n');
    final regExp = RegExp(r'\[(\d+):(\d+\.\d+)\]');

    for (var line in lines) {
      final match = regExp.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = double.parse(match.group(2)!);
        final time = Duration(milliseconds: (minutes * 60000 + seconds * 1000).toInt());
        final text = line.replaceAll(regExp, '').trim();
        if (text.isNotEmpty) {
          parsed.add({'time': time, 'text': text});
        }
      } else if (line.trim().isNotEmpty) {
        // Fallback for plain lyrics
        parsed.add({'time': Duration.zero, 'text': line.trim()});
      }
    }
    return parsed;
  }

  // --- Deezer Audio ---

  Future<String?> getDeezerPreview(String artist, String title) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/deezer/track?artist=${Uri.encodeComponent(artist)}&title=${Uri.encodeComponent(title)}'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['preview']; // This is the audio URL
      } else {
        print('Deezer lookup failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Deezer Error: $e');
    }
    return null;
  }

  // --- YouTube Bridge ---
  // BACKEND CONNECTION:
  // This calls our custom backend endpoint `/api/youtube/search`.
  // The backend uses `yt-search` to find the exact audio track (avoiding music videos
  // with long intros). It returns a `videoId`, which `PlayerProvider` passes to the
  // `youtube_player_iframe` package to silently stream the audio.
  Future<String?> getYoutubeVideoId(String artist, String title) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/youtube/search?q=${Uri.encodeComponent("$artist $title")}'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['videoId'];
      } else {
        print('YouTube lookup failed with status: ${response.statusCode}');
        print('YouTube response: ${response.body}');
      }
    } catch (e) {
      print('YouTube Error: $e');
    }
    return null;
  }

  // --- Playlists ---

  Future<List<Playlist>> getPlaylists() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/playlists'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((item) => Playlist.fromJson(item)).toList();
      }
    } catch (e) {
      print('Get Playlists Error: $e');
    }
    return [];
  }

  Future<bool> createPlaylist(String name, {String coverUrl = '', bool isAlbum = false}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/playlists'),
        headers: _headers,
        body: jsonEncode({
          'name': name, 
          'tracks': [], 
          'coverUrl': coverUrl,
          'description': isAlbum ? 'ALBUM_SAVED' : ''
        }),
      );
      if (response.statusCode == 201) {
        notifyPlaylistsChanged();
        return true;
      }
    } catch (e) {
      print('Create Playlist Error: $e');
    }
    return false;
  }

  Future<bool> saveFullAlbum(String name, String coverUrl, List<Song> tracks) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/playlists'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'tracks': tracks.map((s) => s.toJson()).toList(),
          'coverUrl': coverUrl,
          'description': 'ALBUM_SAVED'
        }),
      );
      if (response.statusCode == 201) {
        notifyPlaylistsChanged();
        return true;
      }
    } catch (e) {
      print('Save Album Error: $e');
    }
    return false;
  }

  Future<Playlist?> getPlaylist(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/playlists/$id'), 
        headers: _headers
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return Playlist.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      print('Get Playlist Error: $e');
    }
    return null;
  }

  Future<List<Song>> getLikedSongs() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/playlists/favorites'), headers: _headers);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((s) => Song.fromJson(s)).toList();
      }
    } catch (e) {
      print('Get Liked Songs Error: $e');
    }
    return [];
  }

  Future<bool> deletePlaylist(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/playlists/$id'), headers: _headers);
      if (response.statusCode == 200 || response.statusCode == 204) {
        notifyPlaylistsChanged();
        return true;
      }
    } catch (e) {
      print('Delete Playlist Error: $e');
    }
    return false;
  }

  Future<bool> toggleLikeSong(Song song) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/playlists/favorites'),
        headers: _headers,
        body: jsonEncode(song.toJson()),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Toggle Like Error: $e');
    }
    return false;
  }

  Future<bool> addTrackToPlaylist(String playlistId, Song song) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/playlists/$playlistId/tracks'),
        headers: _headers,
        body: jsonEncode(song.toJson()),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Add Track Error: $e');
    }
    return false;
  }

  Future<bool> removeTrackFromPlaylist(String playlistId, String trackId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/playlists/$playlistId/tracks/$trackId'),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Remove Track Error: $e');
    }
    return false;
  }

  Future<bool> updatePlaylistCover(String playlistId, String coverUrl) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/playlists/$playlistId'),
        headers: _headers,
        body: jsonEncode({'coverUrl': coverUrl}),
      );
      if (response.statusCode == 200) {
        notifyPlaylistsChanged();
        return true;
      }
    } catch (e) {
      print('Update Playlist Cover Error: $e');
    }
    return false;
  }

  // BACKEND CONNECTION:
  // Calls the custom backend `/api/spotify/album/:id` endpoint.
  // The backend was specifically engineered to return the FULL album object 
  // (instead of just the tracks) so we can manually map the album `name` 
  // and `cover image` down into each individual track here on the frontend.
  // This ensures that when a song is played, `NowPlayingScreen` has an image to display.
  Future<List<Song>> getAlbumTracks(String albumId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/spotify/album/$albumId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List tracksData = data['tracks']?['items'] ?? [];
        final albumName = data['name'];
        final albumCover = (data['images'] as List?)?.isNotEmpty == true ? data['images'][0]['url'] : null;
        final artistData = (data['artists'] as List?)?.isNotEmpty == true ? data['artists'][0] : null;

        return tracksData.map((track) {
          final trackMap = Map<String, dynamic>.from(track);
          // Inject album context into the track object for Song.fromJson to pick up
          trackMap['album'] = {
            'id': albumId,
            'name': albumName,
            'images': albumCover != null ? [{'url': albumCover}] : [],
          };
          if (trackMap['artists'] == null || (trackMap['artists'] as List).isEmpty) {
            trackMap['artists'] = artistData != null ? [artistData] : [];
          }
          return Song.fromJson(trackMap);
        }).toList();
      }
    } catch (e) {
      print('Get Album Tracks Error: $e');
    }
    return [];
  }
}
