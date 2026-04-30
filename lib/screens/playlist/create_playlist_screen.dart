import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/sportify_button.dart';

class CreatePlaylistScreen extends StatefulWidget {
  const CreatePlaylistScreen({super.key});

  @override
  State<CreatePlaylistScreen> createState() => _CreatePlaylistScreenState();
}

class _CreatePlaylistScreenState extends State<CreatePlaylistScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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
                SpotifyButton(
                  text: 'Create',
                  onPressed: () {
                    // Logic to create playlist
                    Navigator.pop(context);
                  },
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
