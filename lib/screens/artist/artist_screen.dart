import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/song_row.dart';
import '../../widgets/carousel_section.dart';
import '../../widgets/media_card.dart';
import '../../models/song.dart';
import '../../providers/player_provider.dart';
import 'package:provider/provider.dart';
import '../player/now_playing_screen.dart';
import '../../services/api_service.dart';

class ArtistScreen extends StatefulWidget {
  final String? artistId;
  final String? artistName;

  const ArtistScreen({super.key, this.artistId, this.artistName});

  @override
  State<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen> {
  bool _isFollowing = false;
  bool _showAllPopular = false;
  bool _isLoading = true;
  List<Song> _popularSongs = [];

  @override
  void initState() {
    super.initState();
    _fetchArtistData();
  }

  Future<void> _fetchArtistData() async {
    if (widget.artistName == null) return;
    setState(() => _isLoading = true);
    try {
      final songs = await ApiService().searchSpotify(widget.artistName!, type: 'track');
      if (mounted) {
        setState(() {
          _popularSongs = songs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: AppColors.primaryBackground,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.purple.withOpacity(0.6),
                          AppColors.primaryBackground,
                        ],
                      ),
                    ),
                    child: Image.network(
                      'https://picsum.photos/400/400',
                      fit: BoxFit.cover,
                      color: Colors.black.withOpacity(0.3),
                      colorBlendMode: BlendMode.darken,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.cardBackground,
                        );
                      },
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.artistName ?? 'Artist Name',
                          style: AppTextStyles.displayLarge.copyWith(
                            fontSize: 48,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '5.2M monthly listeners',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _isFollowing = !_isFollowing;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _isFollowing
                              ? AppColors.primaryText
                              : AppColors.primaryText,
                          side: BorderSide(
                            color: _isFollowing
                                ? AppColors.primaryText
                                : AppColors.secondaryText,
                          ),
                          backgroundColor: _isFollowing
                              ? Colors.transparent
                              : Colors.transparent,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isFollowing)
                              const Icon(
                                Icons.check,
                                size: 16,
                              ),
                            if (_isFollowing) const SizedBox(width: 4),
                            Text(_isFollowing ? 'Following' : 'Follow'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.spotifyGreen,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Shuffle Play'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Popular',
                    style: AppTextStyles.headingMedium,
                  ),
                ),
                const SizedBox(height: 8),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator(color: AppColors.spotifyGreen))
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _showAllPopular ? _popularSongs.length : (_popularSongs.length > 5 ? 5 : _popularSongs.length),
                    itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            child: Text(
                              '${index + 1}',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.secondaryText,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SongRow(
                              song: _popularSongs[index],
                              showAlbumArt: true,
                              onTap: () {
                                context.read<PlayerProvider>().playSong(_popularSongs[index]);
                                Navigator.push(context, MaterialPageRoute(builder: (context) => NowPlayingScreen(song: _popularSongs[index])));
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                if (!_showAllPopular)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showAllPopular = true;
                      });
                    },
                    child: const Text('See more'),
                  ),
                const SizedBox(height: 32),
                CarouselSection(
                  title: 'Popular Releases',
                  children: List.generate(
                    5,
                    (index) => MediaCard(
                      imageUrl: 'https://picsum.photos/200?random=${index + 50}',
                      title: 'Album ${index + 1}',
                      subtitle: '2023',
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                CarouselSection(
                  title: 'Fans Also Like',
                  children: List.generate(
                    5,
                    (index) => MediaCard(
                      imageUrl: 'https://picsum.photos/200?random=${index + 60}',
                      title: 'Similar Artist ${index + 1}',
                      subtitle: '${(index + 1) * 1.2}M monthly listeners',
                      isCircular: true,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.panelBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About',
                          style: AppTextStyles.headingMedium,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Artist biography goes here. This is a detailed description of the artist\'s career, achievements, and musical style...',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.secondaryText,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Read more'),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '5.2M monthly listeners',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                        Text(
                          '#4 in the world',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 180),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
