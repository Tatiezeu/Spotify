import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import 'home/home_screen.dart';
import 'search/search_screen.dart';
import 'library/library_screen.dart';
import 'stats/listening_stats_screen.dart';
import 'settings/settings_screen.dart';
import 'player/now_playing_screen.dart';
import '../widgets/create_menu_bottom_sheet.dart';
import '../widgets/profile_avatar.dart';
import '../services/api_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const LibraryScreen(),
    const SizedBox.shrink(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.primaryBackground,
      drawer: _buildSidebar(context),
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
          // Hidden YouTube Player (Alive globally)
          Positioned(
            left: 0, top: 0,
            child: SizedBox(
              width: 1, height: 1,
              child: YoutubePlayer(
                controller: context.read<PlayerProvider>().controller,
              ),
            ),
          ),
          _buildFloatingMiniPlayer(context),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildFloatingMiniPlayer(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, child) {
        final song = player.currentSong;
        if (song == null) return const SizedBox.shrink();

        return Positioned(
          left: 8,
          right: 8,
          bottom: 0,
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => NowPlayingScreen(song: song),
                ),
              );
            },
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFF2E4D4D), 
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(song.coverUrl, width: 44, height: 44, fit: BoxFit.cover),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text(song.artist, style: const TextStyle(color: Colors.white70, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          if (player.isLoading)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                            ),
                          IconButton(
                            icon: Icon(player.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 30),
                            onPressed: () {
                              if (player.isPlaying) {
                                player.pause();
                              } else {
                                player.resume();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Thin Progress Bar
                  if (player.duration.inSeconds > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: player.position.inSeconds / player.duration.inSeconds,
                          backgroundColor: Colors.white10,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 2,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: BottomNavigationBar(
        backgroundColor: AppColors.primaryBackground,
        selectedItemColor: AppColors.primaryText,
        unselectedItemColor: AppColors.secondaryText,
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        onTap: (index) {
          if (index == 3) {
            CreateMenuBottomSheet.show(context);
            return;
          }
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.library_music), label: 'Your Library'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Create'),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF121212),
      child: Column(
        children: [
          const SizedBox(height: 60),
          ListTile(
            leading: const ProfileAvatar(radius: 20, showBadge: false),
            title: Text(ApiService().firstname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            subtitle: const Text('View Profile', style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
          ),
          const Divider(color: Colors.white10),
          _buildSidebarItem(Icons.bolt, 'What\'s new'),
          _buildSidebarItem(Icons.history, 'Listening history'),
          _buildSidebarItem(Icons.bar_chart, 'Listening stats', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ListeningStatsScreen()))),
          _buildSidebarItem(Icons.settings, 'Settings and privacy', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()))),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 28),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
      onTap: onTap ?? () {},
    );
  }
}
