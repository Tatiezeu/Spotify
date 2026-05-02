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

  String? _token;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
    print('ApiService initialized. Token: ${_token != null ? "Loaded" : "Not Found"}');
  }
  
  void setToken(String token) {
    _token = token;
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
        print('Login Successful. Token set for requests.');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', _token!);
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
        print('Registration Successful. Token set for requests.');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', _token!);
        return true;
      }
    } catch (e) {
      print('Register Error: $e');
    }
    return false;
  }

  Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  bool get isLoggedIn => _token != null;

  // --- Spotify Search ---
  
  Future<List<Song>> searchSongs(String query, {String type = 'track'}) async {
    if (query.isEmpty) return [];
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/spotify/search?q=${Uri.encodeComponent(query)}&type=$type'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Handle different search result structures based on type
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

        print('Search successful. Found ${items.length} results for "$query" (type: $type)');
        return items.map((item) => Song.fromJson(item)).toList();
      } else {
        print('Search failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Search Error: $e');
    }
    return [];
  }

  Future<String> getLyrics(String artist, String title) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/spotify/lyrics?artist=${Uri.encodeComponent(artist)}&title=${Uri.encodeComponent(title)}'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['lyrics'] ?? 'Lyrics not available.';
      }
    } catch (e) {
      print('Lyrics Error: $e');
    }
    return 'Lyrics not available.';
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

  Future<bool> createPlaylist(String name) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/playlists'),
        headers: _headers,
        body: jsonEncode({'name': name, 'tracks': []}),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Create Playlist Error: $e');
    }
    return false;
  }

  Future<Playlist?> getPlaylist(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/playlists/$id'), headers: _headers);
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
      return response.statusCode == 200 || response.statusCode == 204;
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
        Uri.parse('$baseUrl/playlists/$playlistId/add'),
        headers: _headers,
        body: jsonEncode(song.toJson()),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Add Track to Playlist Error: $e');
    }
    return false;
  }
}
