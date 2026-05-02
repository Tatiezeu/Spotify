import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class LyricsScreen extends StatefulWidget {
  final String songTitle;
  final String artistName;

  const LyricsScreen({super.key, required this.songTitle, required this.artistName});

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen> {
  String _lyrics = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLyrics();
  }

  Future<void> _fetchLyrics() async {
    final lyrics = await ApiService().getLyrics(widget.artistName, widget.songTitle);
    if (mounted) {
      setState(() {
        _lyrics = lyrics;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF630D0D), // Matching the Dadju reel theme
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(icon: const Icon(Icons.ios_share), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.songTitle, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(widget.artistName, style: const TextStyle(fontSize: 16, color: Colors.white70)),
            const SizedBox(height: 48),
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: Colors.white))
            else
              Text(
                _lyrics,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, height: 1.5, color: Colors.white),
              ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
