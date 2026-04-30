import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class RecentlyPlayedScreen extends StatelessWidget {
  const RecentlyPlayedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Recently Played', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: 20,
        itemBuilder: (context, index) {
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network('https://picsum.photos/100?r=$index', width: 56, height: 56, fit: BoxFit.cover),
            ),
            title: Text('Recent Item ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Playlist • BRIEL'),
            trailing: const Icon(Icons.more_vert, color: AppColors.secondaryText),
          );
        },
      ),
    );
  }
}
