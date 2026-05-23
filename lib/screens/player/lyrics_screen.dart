import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:palette_generator/palette_generator.dart';
import '../../services/api_service.dart';
import '../../providers/player_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/song.dart';
import '../../utils/image_helper.dart';

class LyricsScreen extends StatefulWidget {
  final String songTitle;
  final String artistName;

  const LyricsScreen({super.key, required this.songTitle, required this.artistName});

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _parsedLyrics = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  
  // Animation Controller for the floating blurred background shapes
  late AnimationController _bgAnimationController;
  
  // Layout and State Management
  bool _isFullscreen = false;
  bool _userScrolling = false;
  Timer? _scrollTimer;
  int _lastScrollIndex = -1;
  
  // Dynamic Color Theme (extracted from cover image)
  String? _lastSongId;
  Color _primaryBgColor = const Color(0xFF630D0D); // Spotify's standard dark red fallback
  Color _secondaryBgColor = const Color(0xFF1B0505);
  Color _highlightColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _fetchLyrics();
    
    // Background dynamic animation (15-second loop) to make the blurred shapes float organically
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _bgAnimationController.dispose();
    _scrollTimer?.cancel();
    super.dispose();
  }

  // Fetch parsed lyrics from LRCLIB
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

  // Dynamic Theme Extraction: Extracts a beautiful palette from the track's artwork
  Future<void> _extractColors(String coverUrl, String songId) async {
    if (_lastSongId == songId) return;
    _lastSongId = songId;

    try {
      final imageProvider = ImageHelper.getImageProvider(coverUrl);
      if (imageProvider == null) {
        // Fallback if no valid cover is provided
        if (mounted) {
          setState(() {
            _primaryBgColor = const Color(0xFF536D6D);
            _secondaryBgColor = const Color(0xFF1B2E2E);
            _highlightColor = Colors.white;
          });
        }
        return;
      }

      // Generate the color palette using PaletteGenerator
      final palette = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 8,
      );

      if (mounted && _lastSongId == songId) {
        setState(() {
          final dominant = palette.dominantColor?.color;
          final darkMuted = palette.darkMutedColor?.color;
          final darkVibrant = palette.darkVibrantColor?.color;
          final lightVibrant = palette.lightVibrantColor?.color;

          // Blending and darkening logic to create an elegant dark gradient theme
          Color primary = darkMuted ?? darkVibrant ?? dominant ?? const Color(0xFF630D0D);
          if (primary.computeLuminance() > 0.3) {
            // Apply blend to ensure the text has optimal AAA contrast
            primary = Color.alphaBlend(Colors.black.withOpacity(0.55), primary);
          }
          _primaryBgColor = primary;

          _secondaryBgColor = Color.alphaBlend(
            Colors.black.withOpacity(0.85),
            dominant ?? const Color(0xFF1B0505),
          );

          // Select dynamic text highlight color
          _highlightColor = lightVibrant ?? Colors.white;
          if (_highlightColor.computeLuminance() < 0.4) {
            _highlightColor = Colors.white;
          }
        });
      }
    } catch (e) {
      debugPrint('Error extracting colors: $e');
      if (mounted && _lastSongId == songId) {
        setState(() {
          _primaryBgColor = const Color(0xFF630D0D);
          _secondaryBgColor = const Color(0xFF1B0505);
          _highlightColor = Colors.white;
        });
      }
    }
  }

  // Smooth centering autoscroll mechanism
  void _scrollToCurrentIndex(int currentIndex, double cardHeight) {
    if (_userScrolling) return; // User is manually scrolling; lock auto-scroll
    if (currentIndex == -1 || !_scrollController.hasClients) return;

    // Center the current line exactly in the middle of the viewport
    const double itemHeight = 64.0; // Precise approximate item height including spacing
    final double targetOffset = (currentIndex * itemHeight) - (cardHeight / 2) + (itemHeight / 2);
    
    final double maxScroll = _scrollController.position.maxScrollExtent;
    final double clampedOffset = targetOffset.clamp(0.0, maxScroll);

    _scrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic, // Spotify-like smooth easing curve
    );
  }

  // Manual scroll listener: pauses auto-scrolling temporarily if the user interacts
  void _onUserScroll() {
    if (!_userScrolling) {
      setState(() {
        _userScrolling = true;
      });
    }
    _scrollTimer?.cancel();
    // After 5 seconds of manual scroll inactivity, auto-scroll will resume seamlessly
    _scrollTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _userScrolling = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Consumer<PlayerProvider>(
        builder: (context, player, child) {
          final currentPosition = player.position;
          final song = player.currentSong;

          if (song != null && song.id != _lastSongId) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _extractColors(song.coverUrl, song.id);
            });
          }

          if (_isLoading) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          if (_parsedLyrics.isEmpty) {
            return Container(
              color: _secondaryBgColor,
              alignment: Alignment.center,
              child: const Text('Lyrics not available for this track.', style: TextStyle(color: Colors.white70, fontSize: 18)),
            );
          }

          // Calculate current active lyric index based on player position.
          // We support two modes:
          // 1. Synced Lyrics: where lyrics have timestamps from the LRC.
          // 2. Unsynced/Plain Lyrics: where we distribute lines evenly across the track duration as a beautiful fallback.
          int currentIndex = -1;
          final isSynced = _parsedLyrics.any((line) => line['time'] != Duration.zero);

          if (isSynced) {
            for (int i = 0; i < _parsedLyrics.length; i++) {
              if (currentPosition >= _parsedLyrics[i]['time']) {
                currentIndex = i;
              } else {
                break;
              }
            }
          } else {
            // Proportional distribution for plain text lyrics:
            // This distributes the lines evenly across the total length of the song,
            // so the lyrics auto-scroll seamlessly as the track plays.
            final totalDuration = player.duration;
            if (totalDuration > Duration.zero && _parsedLyrics.isNotEmpty) {
              final msPerLine = totalDuration.inMilliseconds / _parsedLyrics.length;
              currentIndex = (currentPosition.inMilliseconds / msPerLine).floor().clamp(0, _parsedLyrics.length - 1);
            }
          }

          // Define card heights dynamically
          final double cardHeight = _isFullscreen ? (screenHeight * 0.88) : (screenHeight * 0.60);

          // Trigger smooth auto-scroll when active index advances
          if (currentIndex != -1 && currentIndex != _lastScrollIndex) {
            _lastScrollIndex = currentIndex;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToCurrentIndex(currentIndex, cardHeight);
            });
          }

          return Stack(
            children: [
              // 1. Dynamic Blurred Background Gradient with floating translucent blobs
              _buildAnimatedBackground(),

              // 2. Main Page Layout (Responsive positioning for Card vs Fullscreen)
              SafeArea(
                child: Stack(
                  children: [
                    // A. Top Header Info (Fades out when in fullscreen)
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _isFullscreen ? 0.0 : 1.0,
                      child: IgnorePointer(
                        ignoring: _isFullscreen,
                        child: _buildTopHeader(song),
                      ),
                    ),

                    // B. Dynamic Lyrics Card (using AnimatedPositioned for flawless layout transition)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOutCubic,
                      top: _isFullscreen ? 48 : (screenHeight * 0.28),
                      bottom: _isFullscreen ? 16 : 16,
                      left: _isFullscreen ? 12 : 20,
                      right: _isFullscreen ? 12 : 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            // Header bar inside the card (contains expand/collapse)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                                      color: Colors.white70,
                                      size: 28,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isFullscreen = !_isFullscreen;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),

                            // Lyric Lines Scrolling Viewport
                            Positioned.fill(
                              top: 48,
                              bottom: _isFullscreen ? 16 : 96, // extra padding for playback controls in Card View
                              child: NotificationListener<ScrollNotification>(
                                onNotification: (ScrollNotification notification) {
                                  if (notification is UserScrollNotification) {
                                    if (notification.direction != ScrollDirection.idle) {
                                      _onUserScroll();
                                    }
                                  }
                                  return false;
                                },
                                child: ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                                  itemCount: _parsedLyrics.length,
                                  itemBuilder: (context, index) {
                                    final isCurrent = index == currentIndex;
                                    
                                    // Premium active-line styling
                                    final double fontSize = isCurrent ? 28 : 22;
                                    final FontWeight fontWeight = isCurrent ? FontWeight.w900 : FontWeight.bold;
                                    
                                    // Faded/dimmed coloring
                                    Color textColor = Colors.white.withOpacity(0.35);
                                    if (isCurrent) {
                                      textColor = _highlightColor;
                                    }

                                    return InkWell(
                                      onTap: () {
                                        // Tap-to-seek logic:
                                        // - For synced lyrics, we seek to the lyric timestamp directly.
                                        // - For plain lyrics, we compute the proportional track seek point based on index.
                                        if (isSynced) {
                                          final targetTime = _parsedLyrics[index]['time'] as Duration;
                                          player.seekTo(targetTime);
                                        } else {
                                          final totalDuration = player.duration;
                                          if (totalDuration > Duration.zero) {
                                            final msPerLine = totalDuration.inMilliseconds / _parsedLyrics.length;
                                            final targetMs = (index * msPerLine).toInt();
                                            player.seekTo(Duration(milliseconds: targetMs));
                                          }
                                        }
                                        setState(() {
                                          _userScrolling = false;
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        child: AnimatedDefaultTextStyle(
                                          duration: const Duration(milliseconds: 300),
                                          style: TextStyle(
                                            fontSize: fontSize,
                                            fontWeight: fontWeight,
                                            height: 1.4,
                                            color: textColor,
                                          ),
                                          textAlign: TextAlign.center,
                                          child: Text(_parsedLyrics[index]['text']),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            // Floating manual scroll lock override / Sync button
                            _buildSyncButton(currentIndex, cardHeight),

                            // C. Playback Controls (Displayed at the bottom inside Card View)
                            if (!_isFullscreen)
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: _buildCardPlaybackPanel(player),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // D. Screen-level Close Button (Always floating at top left)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Beautiful organic drifting background blobs heavily blurred
  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _bgAnimationController,
      builder: (context, child) {
        final double t = _bgAnimationController.value * 2 * 3.14159;
        final double xOffset1 = 50 * sin(t);
        final double yOffset1 = 40 * cos(t);
        final double xOffset2 = 40 * cos(t + 2.0);
        final double yOffset2 = 50 * sin(t + 1.0);

        return Stack(
          children: [
            // Solid dynamic background gradient based on extracted cover theme
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_primaryBgColor, _secondaryBgColor],
                ),
              ),
            ),
            // Drifting highlight blob
            Positioned(
              top: MediaQuery.of(context).size.height * 0.15 + yOffset1,
              left: MediaQuery.of(context).size.width * 0.1 + xOffset1,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _highlightColor.withOpacity(0.07),
                ),
              ),
            ),
            // Drifting primary color contrast blob
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.2 + yOffset2,
              right: MediaQuery.of(context).size.width * 0.1 + xOffset2,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primaryBgColor.withOpacity(0.25),
                ),
              ),
            ),
            // High-fidelity multi-stage Backdrop blur overlay
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 75.0, sigmaY: 75.0),
                child: Container(color: Colors.transparent),
              ),
            ),
            // Dark vignette overlay to guarantee premium readability
            Container(
              color: Colors.black.withOpacity(0.2),
            ),
          ],
        );
      },
    );
  }

  // Top header displaying beautiful album art, track title, and artist context
  Widget _buildTopHeader(Song? song) {
    if (song == null) return const SizedBox.shrink();
    
    ImageProvider imageProvider = ImageHelper.getImageProvider(song.coverUrl) 
        ?? const NetworkImage('https://via.placeholder.com/150');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 12, left: 24, right: 24),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            song.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            song.artist,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Floating manual-scroll sync indicator/action
  Widget _buildSyncButton(int currentIndex, double cardHeight) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      bottom: _userScrolling ? (_isFullscreen ? 32 : 112) : -60,
      left: 0,
      right: 0,
      child: Center(
        child: InkWell(
          onTap: () {
            setState(() {
              _userScrolling = false;
            });
            _scrollToCurrentIndex(currentIndex, cardHeight);
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_arrow, color: _primaryBgColor, size: 16),
                const SizedBox(width: 6),
                Text(
                  'SYNC LYRICS',
                  style: TextStyle(
                    color: _primaryBgColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Playback Control Panel rendered inside default Card mode
  Widget _buildCardPlaybackPanel(PlayerProvider player) {
    final song = player.currentSong;
    if (song == null) return const SizedBox.shrink();

    String formatDuration(Duration d) {
      String twoDigits(int n) => n.toString().padLeft(2, "0");
      return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
    }

    final double sliderVal = player.position.inSeconds.toDouble().clamp(0, player.duration.inSeconds > 0 ? player.duration.inSeconds.toDouble() : 300.0);
    final double sliderMax = player.duration.inSeconds > 0 ? player.duration.inSeconds.toDouble() : 300.0;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
          ),
          padding: const EdgeInsets.only(top: 8, bottom: 12, left: 16, right: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sleek mini timeline slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white.withOpacity(0.15),
                  thumbColor: Colors.white,
                  overlayShape: SliderComponentShape.noOverlay,
                ),
                child: Slider(
                  value: sliderVal,
                  max: sliderMax,
                  onChanged: (val) {
                    player.seekTo(Duration(seconds: val.toInt()));
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(formatDuration(player.position), style: const TextStyle(color: Colors.white54, fontSize: 10)),
                    Text('-${formatDuration(player.duration - player.position)}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                  ],
                ),
              ),
              // Playback Action buttons (Prev, Play, Next)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous, color: Colors.white70, size: 24),
                    onPressed: () => player.seekTo(Duration.zero),
                  ),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: () {
                      if (player.isPlaying) {
                        player.pause();
                      } else {
                        player.resume();
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: player.isLoading
                          ? const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)))
                          : Icon(player.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.black, size: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.skip_next, color: Colors.white70, size: 24),
                    onPressed: () => player.playNextInQueue(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
