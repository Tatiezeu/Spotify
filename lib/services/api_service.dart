import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../models/playlist.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5000/api';
  
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
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

  Future<List<Song>> searchSongs(String query) async {
    if (query.isEmpty) return [];
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/spotify/search?q=$query&type=track'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['tracks']?['items'] as List? ?? [];
        print('Found ${items.length} results');
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
}
