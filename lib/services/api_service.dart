import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform, NetworkInterface, InternetAddressType, Socket;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';
import '../models/playlist.dart';

class ApiService {
  static String _baseUrl = _getDefaultBaseUrl();
  static String get baseUrl => _baseUrl;

  static final List<String> _candidates = [
    'http://192.168.1.169:5001',
    'http://localhost:5001',
    'http://127.0.0.1:5001',
    'http://10.0.2.2:5001',
    'http://192.168.1.156:5001',
  ];

  static String _getDefaultBaseUrl() {
    if (kIsWeb) return 'http://localhost:5001/api';
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:5001/api';
      }
      if (Platform.isIOS) {
        // On a physical iOS device, localhost points to the phone itself,
        // so we must use the Mac's LAN IP address.
        return 'http://192.168.1.169:5001/api';
      }
      if (Platform.isMacOS) {
        return 'http://localhost:5001/api';
      }
    } catch (_) {}
    return 'http://192.168.1.169:5001/api';
  }
  
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
    await _probeBaseUrl();
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
    _firstname = prefs.getString('firstname');
    _email = prefs.getString('email');
    _profileImagePath = prefs.getString('profile_image_path');
    print('ApiService initialized. Token: ${_token != null ? "Loaded" : "Not Found"}');
  }

  static bool _isProbing = false;

  static Future<List<String>> _getLocalSubnets() async {
    final subnets = <String>[];
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          final ip = addr.address;
          if (ip.startsWith('127.') || ip.startsWith('169.254.')) continue;
          final parts = ip.split('.');
          if (parts.length == 4) {
            subnets.add('${parts[0]}.${parts[1]}.${parts[2]}');
          }
        }
      }
    } catch (_) {}
    return subnets;
  }

  static Future<String?> _scanSubnetsForBackend() async {
    final subnets = await _getLocalSubnets();
    if (subnets.isEmpty) return null;

    final port = 5001;
    final List<String> candidateIps = [];
    
    for (final subnet in subnets) {
      for (int i = 1; i <= 254; i++) {
        candidateIps.add('$subnet.$i');
      }
    }

    // Probe in parallel chunks of 50 to prevent system socket overhead
    const chunkSize = 50;
    for (int i = 0; i < candidateIps.length; i += chunkSize) {
      final chunk = candidateIps.sublist(
        i, 
        i + chunkSize > candidateIps.length ? candidateIps.length : i + chunkSize
      );

      final List<Future<String?>> chunkProbes = chunk.map((ip) async {
        try {
          final socket = await Socket.connect(ip, port, timeout: const Duration(milliseconds: 500));
          socket.destroy();
          
          // Verify with HTTP endpoint
          final uri = Uri.parse('http://$ip:$port/api');
          final client = http.Client();
          try {
            final res = await client.get(uri).timeout(const Duration(milliseconds: 800));
            if (res.statusCode == 200 || res.statusCode == 404) {
              return 'http://$ip:$port/api';
            }
          } catch (_) {} finally {
            client.close();
          }
        } catch (_) {}
        return null;
      }).toList();

      final results = await Future.wait(chunkProbes);
      final active = results.firstWhere((ip) => ip != null, orElse: () => null);
      if (active != null) {
        return active;
      }
    }
    return null;
  }

  static Future<void> _probeBaseUrl() async {
    if (_isProbing) return;
    _isProbing = true;
    final client = http.Client();
    try {
      print('ApiService: Starting backend resolution...');
      
      // 1. Probe the standard candidates list in parallel first
      final probes = _candidates.map((url) async {
        try {
          final uri = Uri.parse(url);
          final response = await client.get(uri).timeout(const Duration(milliseconds: 1200));
          if (response.statusCode == 200) {
            return '$url/api';
          }
        } catch (_) {}
        return null;
      });

      final results = await Future.wait(probes);
      final activeUrl = results.firstWhere((url) => url != null, orElse: () => null);
      if (activeUrl != null) {
        _baseUrl = activeUrl;
        print('ApiService: Resolved active backend from candidates: $_baseUrl');
        return;
      }

      // 2. Fallback to subnet auto-discovery if all candidates fail
      if (!kIsWeb) {
        print('ApiService: Unreachable candidates. Scanning local subnet...');
        final scannedUrl = await _scanSubnetsForBackend();
        if (scannedUrl != null) {
          _baseUrl = scannedUrl;
          print('ApiService: Auto-discovered active backend: $_baseUrl');
          return;
        }
      }
      
      print('ApiService: Network discovery yielded no active backend, keeping default: $_baseUrl');
    } catch (e) {
      print('ApiService: Discovery error: $e');
    } finally {
      client.close();
      _isProbing = false;
    }
  }

  static void _triggerProbeOnFailure() {
    _probeBaseUrl();
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
      ).timeout(const Duration(seconds: 10));

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
      _triggerProbeOnFailure();
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
      ).timeout(const Duration(seconds: 10));

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
      _triggerProbeOnFailure();
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
      ).timeout(const Duration(seconds: 10));

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
      _triggerProbeOnFailure();
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
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List items = data['artists'] ?? [];
        return items.map((item) => Song.fromJson({...item, 'type': 'artist'})).toList();
      }
    } catch (e) {
      _triggerProbeOnFailure();
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
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List items = data['tracks'] ?? [];
        return items.map((item) => Song.fromJson(item)).toList();
      }
    } catch (e) {
      _triggerProbeOnFailure();
      print('Deezer Search Error: $e');
    }
    return [];
  }

  Future<String> getLyrics(String artist, String title) async {
    try {
      final url = 'https://lrclib.net/api/get?artist_name=${Uri.encodeComponent(artist)}&track_name=${Uri.encodeComponent(title)}';
      print('Fetching lyrics from: $url');
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['syncedLyrics'] ?? data['plainLyrics'] ?? 'Lyrics not available.';
      } else {
        print('LRCLIB Lyrics failed with status: ${response.statusCode}');
        // Try a search if exact match fails
        final searchUrl = 'https://lrclib.net/api/search?q=${Uri.encodeComponent("$artist $title")}';
        final searchRes = await http.get(Uri.parse(searchUrl)).timeout(const Duration(seconds: 5));
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

  // Parses synced LRC format lyrics into a structured list of timestamps and text.
  // Heavily optimized to support different LRC layouts (e.g. no decimals, multiple timestamps, offset values).
  Future<List<Map<String, dynamic>>> getParsedLyrics(String artist, String title) async {
    final lyrics = await getLyrics(artist, title);
    if (lyrics == 'Lyrics not available.') return [];
    
    final List<Map<String, dynamic>> parsed = [];
    final lines = lyrics.split('\n');
    
    // Regular expression matching standard LRC timestamps:
    // [mm:ss], [mm:ss.xx], [mm:ss.xxx], [mm:ss:xx], etc.
    // Group 1: minutes, Group 2: seconds, Group 3: optional decimals/milliseconds
    final regExp = RegExp(r'\[(\d+):(\d+)(?:[.:](\d+))?\]');
    
    // Regular expression matching metadata tags, e.g. [ti:Song Title] or [ar:Artist]
    final metadataRegExp = RegExp(r'^\[[a-zA-Z]+:');
    
    // Regular expression for the LRC offset tag, e.g. [offset:500] (in milliseconds)
    final offsetRegExp = RegExp(r'^\[offset:\s*([+-]?\d+)\s*\]$', caseSensitive: false);
    
    int offsetMs = 0;

    for (var line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;
      
      // Check and parse LRC offset tags to adjust all lyrics timings
      final offsetMatch = offsetRegExp.firstMatch(trimmedLine);
      if (offsetMatch != null) {
        offsetMs = int.tryParse(offsetMatch.group(1)!) ?? 0;
        continue;
      }
      
      // Skip generic metadata headers (like artist, album, title, creator info)
      if (metadataRegExp.hasMatch(trimmedLine)) {
        continue;
      }

      final matches = regExp.allMatches(trimmedLine);
      if (matches.isNotEmpty) {
        // Clean the timestamps from the lyric line to get the raw text
        final text = trimmedLine.replaceAll(regExp, '').trim();
        if (text.isNotEmpty) {
          for (var match in matches) {
            final minutes = int.parse(match.group(1)!);
            final seconds = int.parse(match.group(2)!);
            int milliseconds = 0;
            
            // Convert centiseconds, deciseconds, or milliseconds cleanly
            if (match.group(3) != null) {
              final msStr = match.group(3)!;
              if (msStr.length == 1) {
                milliseconds = int.parse(msStr) * 100;
              } else if (msStr.length == 2) {
                milliseconds = int.parse(msStr) * 10;
              } else if (msStr.length == 3) {
                milliseconds = int.parse(msStr);
              } else {
                milliseconds = int.parse(msStr.substring(0, 3));
              }
            }
            
            // Apply the offset (if specified) to the parsed timestamp
            final time = Duration(
              minutes: minutes, 
              seconds: seconds, 
              milliseconds: milliseconds
            ) + Duration(milliseconds: offsetMs);
            
            parsed.add({'time': time, 'text': text});
          }
        }
      } else {
        // Fallback for plain lyrics (ensure we don't display metadata brackets as lyric lines)
        if (!trimmedLine.startsWith('[') || !trimmedLine.endsWith(']')) {
          parsed.add({'time': Duration.zero, 'text': trimmedLine});
        }
      }
    }
    
    // Sort parsed lyrics chronologically to handle out-of-order lines (or multiple timestamps)
    parsed.sort((a, b) => (a['time'] as Duration).compareTo(b['time'] as Duration));
    return parsed;
  }

  // --- Deezer Audio ---

  Future<String?> getDeezerPreview(String artist, String title) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/deezer/track?artist=${Uri.encodeComponent(artist)}&title=${Uri.encodeComponent(title)}'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['preview']; // This is the audio URL
      } else {
        print('Deezer lookup failed: ${response.statusCode}');
      }
    } catch (e) {
      _triggerProbeOnFailure();
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
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['videoId'];
      } else {
        print('YouTube lookup failed with status: ${response.statusCode}');
        print('YouTube response: ${response.body}');
      }
    } catch (e) {
      _triggerProbeOnFailure();
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
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((item) => Playlist.fromJson(item)).toList();
      }
    } catch (e) {
      _triggerProbeOnFailure();
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
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 201) {
        notifyPlaylistsChanged();
        return true;
      }
    } catch (e) {
      _triggerProbeOnFailure();
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
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 201) {
        notifyPlaylistsChanged();
        return true;
      }
    } catch (e) {
      _triggerProbeOnFailure();
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
      _triggerProbeOnFailure();
      print('Get Playlist Error: $e');
    }
    return null;
  }

  Future<List<Song>> getLikedSongs() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/playlists/favorites'), headers: _headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((s) => Song.fromJson(s)).toList();
      }
    } catch (e) {
      _triggerProbeOnFailure();
      print('Get Liked Songs Error: $e');
    }
    return [];
  }

  Future<bool> deletePlaylist(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/playlists/$id'), headers: _headers).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 || response.statusCode == 204) {
        notifyPlaylistsChanged();
        return true;
      }
    } catch (e) {
      _triggerProbeOnFailure();
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
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      _triggerProbeOnFailure();
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
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      _triggerProbeOnFailure();
      print('Add Track Error: $e');
    }
    return false;
  }

  Future<bool> removeTrackFromPlaylist(String playlistId, String trackId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/playlists/$playlistId/tracks/$trackId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      _triggerProbeOnFailure();
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
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        notifyPlaylistsChanged();
        return true;
      }
    } catch (e) {
      _triggerProbeOnFailure();
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
      ).timeout(const Duration(seconds: 10));

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
      _triggerProbeOnFailure();
      print('Get Album Tracks Error: $e');
    }
    return [];
  }
}
