import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/sportify_button.dart';
import '../../services/api_service.dart';
import '../../models/song.dart';

class CreatePlaylistScreen extends StatefulWidget {
  final Song? initialSong;
  const CreatePlaylistScreen({super.key, this.initialSong});

  @override
  State<CreatePlaylistScreen> createState() => _CreatePlaylistScreenState();
}

class _CreatePlaylistScreenState extends State<CreatePlaylistScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleCreate() async {
    if (_nameController.text.isEmpty) return;

    setState(() => _isLoading = true);
    final success = await ApiService().createPlaylist(_nameController.text);
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        if (widget.initialSong != null) {
          final playlists = await ApiService().getPlaylists();
          final newPlaylist = playlists.firstWhere((p) => p.name == _nameController.text);
          await ApiService().addTrackToPlaylist(newPlaylist.id, widget.initialSong!);
        }
        if (mounted) Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create playlist'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        title: const Text('Give your playlist a name'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              textAlign: TextAlign.center,
              style: AppTextStyles.displayMedium,
              decoration: InputDecoration(
                hintText: 'My Playlist #1',
                hintStyle: AppTextStyles.displayMedium.copyWith(color: Colors.white24),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              onSubmitted: (_) => _handleCreate(),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SpotifyButton(
                  text: 'Cancel',
                  onPressed: () => Navigator.pop(context),
                  isPrimary: false,
                  isFullWidth: false,
                ),
                const SizedBox(width: 16),
                _isLoading 
                  ? const CircularProgressIndicator(color: AppColors.spotifyGreen)
                  : SpotifyButton(
                      text: 'Create',
                      onPressed: _handleCreate,
                      isPrimary: true,
                      isFullWidth: false,
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
