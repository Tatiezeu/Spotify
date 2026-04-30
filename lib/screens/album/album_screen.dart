import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/song_row.dart';
import '../../models/song.dart';

class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  bool _isSaved = false;

  final List<Song> _tracks = List.generate(
    12,
    (index) => Song(
      id: 'track_$index',
      title: 'Track ${index + 1}',
      artist: 'Artist Name',
      artistId: 'artist_1',
      albumId: 'album_1',
      albumName: 'Album Title',
      coverUrl: 'https://picsum.photos/200',
      duration: Duration(minutes: 3, seconds: 15 + index),
      isExplicit: index % 3 == 0,
    ),
  );

  String get _totalDuration {
    final total = _tracks.fold<Duration>(
      Duration.zero,
      (sum, track) => sum + track.duration,
    );
    return '${total.inMinutes}min';
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
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.blue.withOpacity(0.6),
                      AppColors.primaryBackground,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          'https://picsum.photos/400',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppColors.cardBackground,
                              child: const Icon(
                                Icons.album,
                                size: 80,
                                color: AppColors.secondaryText,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          Text(
                            'Album Title',
                            style: AppTextStyles.headingLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: AppColors.cardBackground,
                                child: const Icon(
                                  Icons.person,
                                  size: 16,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Artist Name',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.secondaryText,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '2023 • ${_tracks.length} songs • $_totalDuration',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isSaved ? Icons.favorite : Icons.favorite_border,
                          color: _isSaved
                              ? AppColors.spotifyGreen
                              : AppColors.primaryText,
                        ),
                        onPressed: () {
                          setState(() {
                            _isSaved = !_isSaved;
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.download,
                          color: AppColors.secondaryText.withOpacity(0.3),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Upgrade to Premium to download'),
                              backgroundColor: AppColors.panelBackground,
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {},
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.spotifyGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(500),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.shuffle),
                            const SizedBox(width: 8),
                            Text(
                              'Shuffle Play',
                              style: AppTextStyles.labelMedium.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _tracks.length,
                  itemBuilder: (context, index) {
                    return SongRow(
                      song: _tracks[index],
                      showAlbumArt: false,
                      showTrackNumber: true,
                      trackNumber: index + 1,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Playing in shuffle mode (Free tier)',
                            ),
                            backgroundColor: AppColors.panelBackground,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    );
                  },
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
