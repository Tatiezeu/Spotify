import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../playlist/playlist_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  final List<String> _searchFilters = ['All', 'Music', 'Podcasts & Shows', 'Artists', 'Playlists', 'Albums'];
  String _activeFilter = 'All';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: AppColors.primaryBackground,
              floating: true,
              leading: Builder(
                builder: (context) => Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: GestureDetector(
                    onTap: () => Scaffold.of(context).openDrawer(),
                    child: Stack(
                      children: [
                        const CircleAvatar(
                          backgroundColor: AppColors.panelBackground,
                          child: Icon(Icons.person, color: Colors.white, size: 18),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primaryBackground, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              title: const Text(
                'Search',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () => _showShareMenu(context),
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt_outlined),
                  onPressed: () {},
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildSearchBar(),
                    if (_isSearching) ...[
                      const SizedBox(height: 16),
                      _buildSearchFilters(),
                      const SizedBox(height: 24),
                      _buildSearchResults(),
                    ] else ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Discover something new',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildDiscoverSection(),
                      const SizedBox(height: 32),
                      const Text(
                        'Browse all',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildBrowseGrid(),
                    ],
                    const SizedBox(height: 180),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShareMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.panelBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Share via', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.message, color: Colors.green),
                title: const Text('WhatsApp'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.blue),
                title: const Text('Other Apps'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.print, color: Colors.white),
                title: const Text('Print'),
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _searchFilters.map((filter) {
          final isSelected = _activeFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => _activeFilter = filter),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.spotifyGreen : AppColors.panelBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Top result', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.panelBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network('https://picsum.photos/100', width: 80, height: 80, fit: BoxFit.cover),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('One Of The Girls', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Song • The Weeknd, JENNIE', style: TextStyle(color: AppColors.secondaryText, fontSize: 14)),
                  ],
                ),
              ),
              const Icon(Icons.play_circle_fill, color: AppColors.spotifyGreen, size: 48),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text('Songs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...List.generate(5, (index) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Image.network('https://picsum.photos/100?s=$index', width: 48, height: 48, fit: BoxFit.cover),
          title: Text('Search Result Song ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Artist Name'),
          trailing: const Icon(Icons.more_horiz, color: AppColors.secondaryText),
          onTap: () {},
        )),
      ],
    );
  }
  
  Widget _buildSearchBar() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _searchController,
        cursorColor: Colors.black,
        onChanged: (value) {
          setState(() {
            _isSearching = value.isNotEmpty;
          });
        },
        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(Icons.search, color: Colors.black, size: 28),
          hintText: 'What do you want to listen to?',
          hintStyle: TextStyle(color: Colors.black.withOpacity(0.7), fontWeight: FontWeight.w500, fontSize: 15),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          suffixIcon: _isSearching ? IconButton(
            icon: const Icon(Icons.close, color: Colors.black, size: 24),
            onPressed: () {
              _searchController.clear();
              setState(() {
                _isSearching = false;
              });
            },
          ) : null,
        ),
      ),
    );
  }

  Widget _buildDiscoverSection() {
    return SizedBox(
      height: 220,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildDiscoverCard('#pop urbaine', 'https://picsum.photos/400/600?random=1'),
          _buildDiscoverCard('#coupé décalé', 'https://picsum.photos/400/600?random=2'),
          _buildDiscoverCard('#clean girl', 'https://picsum.photos/400/600?random=3'),
        ],
      ),
    );
  }

  Widget _buildDiscoverCard(String tag, String imageUrl) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DiscoveryDetailScreen(tag: tag, imageUrl: imageUrl),
          ),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.3),
              BlendMode.darken,
            ),
          ),
        ),
        child: Stack(
          children: [
            const Center(
              child: Icon(Icons.play_arrow_outlined, color: Colors.white, size: 40),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              child: Text(
                tag,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowseGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildCategoryCard('Podcasts', const Color(0xFF27856A), 'https://picsum.photos/100?1'),
        _buildCategoryCard('Live Events', const Color(0xFF8471F2), 'https://picsum.photos/100?2'),
        _buildCategoryCard('Made For You', const Color(0xFF1E3264), 'https://picsum.photos/100?3'),
        _buildCategoryCard('New Releases', const Color(0xFFE8115B), 'https://picsum.photos/100?4'),
        _buildCategoryCard('Hindi', const Color(0xFFE13300), 'https://picsum.photos/100?5'),
        _buildCategoryCard('Punjabi', const Color(0xFFB02897), 'https://picsum.photos/100?6'),
        _buildCategoryCard('Tamil', const Color(0xFFA56752), 'https://picsum.photos/100?7'),
        _buildCategoryCard('Telugu', const Color(0xFFD84000), 'https://picsum.photos/100?8'),
        _buildCategoryCard('Charts', const Color(0xFF8D67AB), 'https://picsum.photos/100?9'),
        _buildCategoryCard('Pop', const Color(0xFF148A08), 'https://picsum.photos/100?10'),
      ],
    );
  }

  Widget _buildCategoryCard(String title, Color color, String imageUrl) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryDetailScreen(title: title, color: color),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              top: 12,
              left: 12,
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
            Positioned(
              bottom: -10,
              right: -15,
              child: Transform.rotate(
                angle: 0.5,
                child: Container(
                  width: 70,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                      ),
                    ],
                    image: DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DiscoveryDetailScreen extends StatelessWidget {
  final String tag;
  final String imageUrl;

  const DiscoveryDetailScreen({super.key, required this.tag, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: 5,
        itemBuilder: (context, index) {
          final bgColor = index % 2 == 0 ? const Color(0xFF630D0D) : const Color(0xFF2E6B91);
          final artistName = index % 2 == 0 ? 'Dadju, Tayc' : 'Franglish';
          final songTitle = index % 2 == 0 ? 'Épouse-moi' : 'Bêtise';
          final albumArt = index % 2 == 0 ? 'https://picsum.photos/400?random=reel1' : 'https://picsum.photos/400?random=reel2';
          
          return Container(
            color: bgColor,
            child: Stack(
              children: [
                SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
                            Text(tag, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const Icon(Icons.volume_up_outlined, color: Colors.white),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildProgressBar(),
                      const Spacer(),
                      _buildReelCenter(albumArt),
                      const Spacer(),
                      _buildReelFooter(context, artistName, songTitle, albumArt),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(5, (index) => Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: index == 0 ? Colors.white : Colors.white24,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        )),
      ),
    );
  }

  Widget _buildReelCenter(String imageUrl) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildVisualizerBar(20),
              const SizedBox(width: 4),
              _buildVisualizerBar(40),
              const SizedBox(width: 4),
              _buildVisualizerBar(30),
              const SizedBox(width: 150), // Gap for image
              _buildVisualizerBar(30),
              const SizedBox(width: 4),
              _buildVisualizerBar(40),
              const SizedBox(width: 4),
              _buildVisualizerBar(20),
            ],
          ),
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 40, spreadRadius: 10),
              ],
            ),
            child: Image.network(imageUrl, fit: BoxFit.cover),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualizerBar(double height) {
    return Container(
      width: 4,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white38,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildReelFooter(BuildContext context, String artist, String song, String imageUrl) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 16, backgroundImage: NetworkImage('https://picsum.photos/100?avatar')),
              const SizedBox(width: 8),
              Text(artist, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white70),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Follow', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              const Icon(Icons.ios_share, color: Colors.white),
            ],
          ),
          const SizedBox(height: 12),
          const Text('#french r&b  #love  #french music', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(imageUrl, width: 48, height: 48, fit: BoxFit.cover),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(song, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(artist, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Added to Your Library'), backgroundColor: AppColors.spotifyGreen),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryDetailScreen extends StatelessWidget {
  final String title;
  final Color color;

  const CategoryDetailScreen({super.key, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color, AppColors.primaryBackground],
                ),
              ),
              child: Center(
                child: Text(title, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900)),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.0,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlaylistScreen(title: 'Playlist ${index + 1}'),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.panelBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Image.network('https://picsum.photos/200?random=$index', fit: BoxFit.cover, width: double.infinity)),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text('Playlist ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
