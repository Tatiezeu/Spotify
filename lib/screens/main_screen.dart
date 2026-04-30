import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import 'home/home_screen.dart';
import 'search/search_screen.dart';
import 'library/library_screen.dart';
import 'stats/listening_stats_screen.dart';
import 'settings/settings_screen.dart';
import 'player/queue_screen.dart';
import '../widgets/create_menu_bottom_sheet.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isPlaying = true;
  int _currentTrackIndex = 0;
  final List<Map<String, String>> _tracks = [
    {'title': 'STEALING YOUR LIFE – Stop Delaying Your Greatness', 'artist': 'Denzel Washington Motivational Speech', 'image': 'https://picsum.photos/200?track=1'},
    {'title': 'Bring It On', 'artist': 'P-Square, Dave Scott', 'image': 'https://picsum.photos/200?track=2'},
    {'title': 'Super-Héros', 'artist': 'Tayc', 'image': 'https://picsum.photos/200?track=3'},
    {'title': 'Naughty Girl', 'artist': 'SLOWBURN', 'image': 'https://picsum.photos/200?track=4'},
  ];
  final List<Map<String, String>> _queue = [];

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
          _buildFloatingMiniPlayer(context),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildFloatingMiniPlayer(BuildContext context) {
    final track = _tracks[_currentTrackIndex];
    return Positioned(
      left: 8,
      right: 8,
      bottom: 0,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pushNamed('/now-playing'),
        child: Container(
          height: 64,
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
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(track['image']!, width: 48, height: 48, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(track['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(track['artist']!, style: const TextStyle(color: Colors.white70, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.devices_other, color: Colors.white, size: 24),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 32),
                onPressed: () => setState(() => _isPlaying = !_isPlaying),
              ),
            ],
          ),
        ),
      ),
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
          const ListTile(
            leading: CircleAvatar(backgroundColor: AppColors.panelBackground, child: Icon(Icons.person, color: Colors.white)),
            title: Text('Briel vibe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            subtitle: Text('View Profile', style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
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
