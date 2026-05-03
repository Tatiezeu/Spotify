import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../services/api_service.dart';

class ProfileAvatar extends StatefulWidget {
  final double radius;
  final bool showBadge;

  const ProfileAvatar({
    super.key,
    this.radius = 18,
    this.showBadge = true,
  });

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  late StreamSubscription _sub;

  @override
  void initState() {
    super.initState();
    _sub = ApiService().onProfileChanged.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = ApiService().profileImagePath;
    
    Widget imageWidget;
    if (imagePath != null && imagePath.isNotEmpty) {
      if (kIsWeb || imagePath.startsWith('http') || imagePath.startsWith('blob')) {
        imageWidget = Image.network(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      } else {
        imageWidget = Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      }
    } else {
      imageWidget = _buildPlaceholder();
    }

    return Container(
      width: widget.radius * 2,
      height: widget.radius * 2,
      decoration: const BoxDecoration(
        color: AppColors.panelBackground,
        shape: BoxShape.circle,
      ),
      child: Stack(
        children: [
          ClipOval(
            child: SizedBox.expand(child: imageWidget),
          ),
          if (widget.showBadge)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: widget.radius * 0.55,
                height: widget.radius * 0.55,
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryBackground, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(Icons.person, color: Colors.white, size: widget.radius * 1.2),
    );
  }
}
