import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/song.dart';
import 'lyrics_screen.dart';
import 'queue_screen.dart';
import '../../services/api_service.dart';
import '../../providers/player_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class NowPlayingScreen extends StatefulWidget {
  final Song? song;
  const NowPlayingScreen({super.key, this.song});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  bool _isLiked = true;
  bool _isShuffle = true;

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  Future<void> _downloadSong(Song? song) async {
    if (song == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing download...')),
    );

    try {
      final videoId = await ApiService().getYoutubeVideoId(song.artist, song.title);
      if (videoId != null) {
        final downloadUrl = Uri.parse(
          '${ApiService.baseUrl}/youtube/download?videoId=$videoId&title=${Uri.encodeComponent("${song.artist} - ${song.title}")}'
        );
        if (await canLaunchUrl(downloadUrl)) {
          await launchUrl(downloadUrl, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      debugPrint('Download Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);
    final song = widget.song ?? player.currentSong;

    if (song == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text('No song selected')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF536D6D),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.2),
              Colors.black.withOpacity(0.5),
              AppColors.primaryBackground,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      _buildAlbumArt(song),
                      const SizedBox(height: 48),
                      _buildSongInfo(song),
                      const SizedBox(height: 24),
                      _buildProgressBar(context, player),
                      const SizedBox(height: 16),
                      _buildControls(player),
                      const SizedBox(height: 32),
                      _buildFooterActions(song),
                      const SizedBox(height: 40),
                      _buildLyricsSection(song),
                      const SizedBox(height: 24),
                      _buildSongDNASection(),
                      const SizedBox(height: 24),
                      _buildAboutArtistSection(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, size: 32, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Text(
            'Briel\'s vibes',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(Song song) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: NetworkImage(song.coverUrl),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSongInfo(Song song) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  song.artist,
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: AppColors.spotifyGreen, size: 32),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, PlayerProvider player) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white.withOpacity(0.2),
              thumbColor: Colors.white,
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: player.position.inSeconds.toDouble(),
              max: player.duration.inSeconds > 0 ? player.duration.inSeconds.toDouble() : 300.0,
              onChanged: (value) {
                player.seekTo(Duration(seconds: value.toInt()));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(player.position), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text('-${_formatDuration(player.duration - player.position)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(PlayerProvider player) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.shuffle, color: _isShuffle ? AppColors.spotifyGreen : Colors.white, size: 28),
            onPressed: () => setState(() => _isShuffle = !_isShuffle),
          ),
          const Icon(Icons.skip_previous, size: 48, color: Colors.white),
          GestureDetector(
            onTap: () {
              if (player.isPlaying) {
                player.pause();
              } else {
                player.resume();
              }
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 4),
              ),
              child: player.isLoading 
                  ? const Center(child: CircularProgressIndicator(color: Colors.black))
                  : Icon(player.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.black, size: 48),
            ),
          ),
          const Icon(Icons.skip_next, size: 48, color: Colors.white),
          const Icon(Icons.repeat, color: Colors.white, size: 28),
        ],
      ),
    );
  }

  Widget _buildFooterActions(Song song) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.download_for_offline_outlined, color: Colors.white, size: 24),
            onPressed: () => _downloadSong(song),
          ),
          const Spacer(),
          const Icon(Icons.ios_share, color: Colors.white, size: 24),
          const SizedBox(width: 32),
          IconButton(
            icon: const Icon(Icons.queue_music, color: Colors.white, size: 24),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => QueueScreen(
                queue: const [
                  {'title': 'One Of The Girls - Sped Up', 'artist': 'The Weeknd', 'image': 'https://picsum.photos/200?track=1'},
                  {'title': 'Bring It On', 'artist': 'P-Square', 'image': 'https://picsum.photos/200?track=2'},
                  {'title': 'Super-Héros', 'artist': 'Tayc', 'image': 'https://picsum.photos/200?track=3'},
                ],
                onPlay: (index) {},
              )));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsSection(Song song) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF4A5D5D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LyricsScreen(
                    songTitle: song.title,
                    artistName: song.artist,
                  ),
                ),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Lyrics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                Row(
                  children: const [
                    Icon(Icons.ios_share, color: Colors.white, size: 20),
                    SizedBox(width: 16),
                    Icon(Icons.open_in_full, color: Colors.white, size: 20),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (song.previewUrl.isEmpty)
            const Text("Preview not available for this track", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            "Tap to see full lyrics...",
            style: TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.w900, 
              color: Colors.black.withOpacity(0.8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongDNASection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2E2E), // Darker section
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('SongDNA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.spotifyGreen, borderRadius: BorderRadius.circular(4)),
                child: const Text('Beta', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildDNAArtist('The Weeknd', 'Main Artist + 1 more', 'https://picsum.photos/200?w'),
              const SizedBox(width: 24),
              _buildDNAArtist('JENNIE', 'Main Artist', 'https://picsum.photos/200?j'),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('One Of The Girls - Sped Up', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  SizedBox(height: 4),
                  Text('9 contributors', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Explore', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Discover the people behind the song.', style: TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildDNAArtist(String name, String role, String imageUrl) {
    return Column(
      children: [
        CircleAvatar(radius: 45, backgroundImage: NetworkImage(imageUrl)),
        const SizedBox(height: 8),
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
        Text(role, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  Widget _buildAboutArtistSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF1B2E2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network('https://picsum.photos/600/350?artist2', height: 200, width: double.infinity, fit: BoxFit.cover),
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Discover more about The Weeknd', 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
