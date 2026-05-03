import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../providers/player_provider.dart';
import '../../core/constants/app_colors.dart';

class LyricsScreen extends StatefulWidget {
  final String songTitle;
  final String artistName;

  const LyricsScreen({super.key, required this.songTitle, required this.artistName});

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen> {
  List<Map<String, dynamic>> _parsedLyrics = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchLyrics();
  }

  Future<void> _fetchLyrics() async {
    setState(() {
      _isLoading = true;
      _parsedLyrics = [];
    });
    final lyrics = await ApiService().getParsedLyrics(widget.artistName, widget.songTitle);
    if (mounted) {
      setState(() {
        _parsedLyrics = lyrics;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF630D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(icon: const Icon(Icons.ios_share), onPressed: () {}),
        ],
      ),
      body: Consumer<PlayerProvider>(
        builder: (context, player, child) {
          final currentPosition = player.position;
          
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          if (_parsedLyrics.isEmpty) {
            return const Center(child: Text('Lyrics not available.', style: TextStyle(color: Colors.white, fontSize: 18)));
          }

          // Find current line index
          int currentIndex = -1;
          for (int i = 0; i < _parsedLyrics.length; i++) {
            if (currentPosition >= _parsedLyrics[i]['time']) {
              currentIndex = i;
            } else {
              break;
            }
          }

          // Auto-scroll logic
          if (currentIndex != -1 && _scrollController.hasClients) {
            _scrollController.animateTo(
              currentIndex * 45.0, // Approximate line height
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            itemCount: _parsedLyrics.length,
            itemBuilder: (context, index) {
              final isCurrent = index == currentIndex;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _parsedLyrics[index]['text'],
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                    color: isCurrent ? Colors.white : Colors.white38,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
