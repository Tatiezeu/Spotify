import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/song.dart';
import 'lyrics_screen.dart';
import '../playlist/create_playlist_screen.dart';
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
  bool _isDragging = false;
  double _dragValue = 0.0;
  Future<List<Song>>? _relatedArtistsFuture;
  String? _lastArtistId;

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
    // Always use the global current song if it exists, otherwise use the one passed to the widget
    final song = player.currentSong ?? widget.song;

    if (song != null && song.artistId != _lastArtistId) {
      _lastArtistId = song.artistId;
      _relatedArtistsFuture = ApiService().getRelatedArtists(song.artistId);
    }

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
              _buildHeader(context, song),
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
                      _buildCreditsSection(song),
                      const SizedBox(height: 24),
                      _buildAboutArtistSection(song),
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

  Widget _buildHeader(BuildContext context, Song song) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, size: 32, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Text(
            '${ApiService().firstname}\'s vibes',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
          ),
          Consumer<PlayerProvider>(
            builder: (context, player, child) {
              final isLiked = player.isLiked(song.id);
              return IconButton(
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? AppColors.spotifyGreen : Colors.white,
                ),
                onPressed: () => player.toggleLike(song),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.white),
            onPressed: () => _showSongOptions(context, song),
          ),
        ],
      ),
    );
  }

  ImageProvider _getImageProvider(String url) {
    if (url.startsWith('http') || url.startsWith('blob:')) {
      return NetworkImage(url);
    }
    if (kIsWeb) {
      return NetworkImage(url);
    }
    return FileImage(File(url));
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
              image: _getImageProvider(song.coverUrl),
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
              value: _isDragging 
                  ? _dragValue 
                  : player.position.inSeconds.toDouble().clamp(0, player.duration.inSeconds > 0 ? player.duration.inSeconds.toDouble() : 300.0),
              max: player.duration.inSeconds > 0 ? player.duration.inSeconds.toDouble() : 300.0,
              onChangeStart: (value) {
                setState(() {
                  _isDragging = true;
                  _dragValue = value;
                });
              },
              onChanged: (value) {
                setState(() {
                  _dragValue = value;
                });
              },
              onChangeEnd: (value) {
                player.seekTo(Duration(seconds: value.toInt()));
                setState(() {
                  _isDragging = false;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(_isDragging ? Duration(seconds: _dragValue.toInt()) : player.position), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text('-${_formatDuration(player.duration - (_isDragging ? Duration(seconds: _dragValue.toInt()) : player.position))}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
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
            icon: Icon(Icons.shuffle, color: player.isShuffle ? AppColors.spotifyGreen : Colors.white, size: 28),
            onPressed: () => player.toggleShuffle(),
          ),
          IconButton(
            icon: const Icon(Icons.skip_previous, size: 48, color: Colors.white),
            onPressed: () => player.seekTo(Duration.zero),
          ),
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
          IconButton(
            icon: const Icon(Icons.skip_next, size: 48, color: Colors.white),
            onPressed: () => player.playNextInQueue(),
          ),
          IconButton(
            icon: Icon(Icons.repeat, color: player.isLooping ? AppColors.spotifyGreen : Colors.white, size: 28),
            onPressed: () => player.toggleLoop(),
          ),
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
              Navigator.push(context, MaterialPageRoute(builder: (context) => const QueueScreen()));
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Lyrics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
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
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                  child: const Icon(Icons.keyboard_arrow_up, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Consumer<PlayerProvider>(
            builder: (context, player, child) {
              if (player.isFetchingLyrics) {
                return const Text("Loading lyrics...", style: TextStyle(color: Colors.white54, fontSize: 20));
              }

              final lyrics = player.currentLyrics;
              if (lyrics.isEmpty) {
                return const Text("Lyrics not available for this track", style: TextStyle(color: Colors.white54, fontSize: 20));
              }
              
              // Find current line
              int currentIndex = -1;
              for (int i = 0; i < lyrics.length; i++) {
                if (player.position >= lyrics[i]['time']) {
                  currentIndex = i;
                } else {
                  break;
                }
              }
              
              if (currentIndex == -1) currentIndex = 0;
              final currentLyric = lyrics[currentIndex];
              final displayLine = currentLyric['text'];
              
              double progress = 0.0;
              if (currentIndex < lyrics.length - 1) {
                final nextTime = lyrics[currentIndex + 1]['time'] as Duration;
                final currentTime = currentLyric['time'] as Duration;
                final lineDuration = nextTime.inMilliseconds - currentTime.inMilliseconds;
                if (lineDuration > 0) {
                  progress = (player.position.inMilliseconds - currentTime.inMilliseconds) / lineDuration;
                  progress = progress.clamp(0.0, 1.0);
                }
              } else {
                progress = 1.0;
              }
              
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: ShaderMask(
                  key: ValueKey(displayLine),
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      colors: [Colors.white, Colors.white.withOpacity(0.3)],
                      stops: [progress, progress],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ).createShader(bounds);
                  },
                  child: Text(
                    displayLine,
                    style: const TextStyle(
                      fontSize: 32, 
                      fontWeight: FontWeight.w900, 
                      color: Colors.white,
                      height: 1.3,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCreditsSection(Song song) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2E2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.group_outlined, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('Fans also like', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 24),
          FutureBuilder<List<Song>>(
            future: _relatedArtistsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.spotifyGreen));
              }
              final related = snapshot.data ?? [];
              if (related.isEmpty) {
                return const Text('No suggestions available', style: TextStyle(color: Colors.white70));
              }
              return Row(
                children: [
                  ...related.take(2).map((artist) => Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: _buildDNAArtist(artist.artist, 'Artist', artist.coverUrl),
                  )),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('Produced by ${song.artist}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
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

  Widget _buildAboutArtistSection(Song song) {
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
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: _getImageProvider('https://picsum.photos/600/350?${song.artistId}'),
                fit: BoxFit.cover,
                onError: (exception, stackTrace) => _getImageProvider(song.coverUrl),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About ${song.artist}', 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  'Discover more about ${song.artist} and their musical journey. Tap to see full biography, top tracks, and upcoming releases.',
                  style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSongOptions(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF282828),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.playlist_add, color: Colors.white70),
              title: const Text('Add to Queue'),
              onTap: () {
                context.read<PlayerProvider>().addToQueue(song);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Added to Queue'), backgroundColor: AppColors.spotifyGreen),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.queue_music, color: Colors.white70),
              title: const Text('Play Next'),
              onTap: () {
                context.read<PlayerProvider>().playNext(song);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Will play next'), backgroundColor: AppColors.spotifyGreen),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_box_outlined, color: Colors.white70),
              title: const Text('Add to Playlist', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showPlaylistPicker(context, song);
              },
            ),
            Consumer<PlayerProvider>(
              builder: (context, player, child) {
                final isLiked = player.isLiked(song.id);
                return ListTile(
                  leading: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? AppColors.spotifyGreen : Colors.white70,
                  ),
                  title: Text(isLiked ? 'In Liked Songs' : 'Add to Liked Songs', style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    player.toggleLike(song);
                    Navigator.pop(context);
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.white70),
              title: const Text('Share', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  void _showPlaylistPicker(BuildContext context, Song song) async {
    final apiService = ApiService();
    final playlists = await apiService.getPlaylists();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF282828),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              const Text('Add to Playlist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.add, color: AppColors.spotifyGreen),
                title: const Text('New Playlist', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  _showCreatePlaylistDialog(context, song);
                },
              ),
              const Divider(color: Colors.white10),
              ...playlists.map((playlist) => ListTile(
                leading: const Icon(Icons.music_note, color: Colors.white70),
                title: Text(playlist.name, style: const TextStyle(color: Colors.white)),
                onTap: () async {
                  final success = await apiService.addTrackToPlaylist(playlist.id, song);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(success ? 'Added to ${playlist.name}' : 'Failed to add'), backgroundColor: success ? AppColors.spotifyGreen : Colors.red),
                    );
                  }
                },
              )).toList(),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, Song song) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePlaylistScreen(initialSong: song),
      ),
    ).then((created) {
      if (created == true && context.mounted) {
        _showPlaylistPicker(context, song);
      }
    });
  }
}
