import 'package:flutter/material.dart';

class LyricsScreen extends StatelessWidget {
  final String songTitle;
  final String artistName;

  const LyricsScreen({super.key, required this.songTitle, required this.artistName});

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
            Text(songTitle, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(artistName, style: const TextStyle(fontSize: 16, color: Colors.white70)),
            const SizedBox(height: 48),
            const Text(
              "Mon amour,\n"
              "Je t'ai promis la lune,\n"
              "Mais je n'ai que mon cœur à t'offrir.\n\n"
              "Épouse-moi,\n"
              "Devenons une seule âme,\n"
              "Construisons notre avenir dès ce soir.\n\n"
              "Tu es ma reine,\n"
              "Ma vie, mon tout,\n"
              "Je ne vois que toi,\n"
              "Dans la foule, partout.\n\n"
              "Le temps s'arrête,\n"
              "Quand tes yeux croisent les miens,\n"
              "Je t'aimerai,\n"
              "Jusqu'au bout du chemin.\n\n"
              "Épouse-moi...",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, height: 1.5, color: Colors.white),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
