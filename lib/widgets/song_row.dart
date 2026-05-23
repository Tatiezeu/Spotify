import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../models/song.dart';
import '../utils/image_helper.dart';

class SongRow extends StatelessWidget {
  final Song song;
  final VoidCallback? onTap;
  final VoidCallback? onLikeTap;
  final VoidCallback? onMenuTap;
  final bool showAlbumArt;
  final bool showTrackNumber;
  final int? trackNumber;

  const SongRow({
    super.key,
    required this.song,
    this.onTap,
    this.onLikeTap,
    this.onMenuTap,
    this.showAlbumArt = true,
    this.showTrackNumber = false,
    this.trackNumber,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            if (showTrackNumber && trackNumber != null)
              SizedBox(
                width: 24,
                child: Text(
                  trackNumber.toString(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            if (showTrackNumber && trackNumber != null)
              const SizedBox(width: 16),
            if (showAlbumArt)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: ImageHelper.imageWidget(
                  song.coverUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 48,
                      height: 48,
                      color: AppColors.panelBackground,
                      child: const Icon(
                        Icons.music_note,
                        color: AppColors.secondaryText,
                      ),
                    );
                  },
                ),
              ),
            if (showAlbumArt) const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          song.title,
                          style: AppTextStyles.bodyLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (song.isExplicit) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryText,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Text(
                            'E',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.artist,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.secondaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!showTrackNumber)
              IconButton(
                icon: Icon(
                  song.isLiked ? Icons.favorite : Icons.favorite_border,
                  color: song.isLiked
                      ? AppColors.spotifyGreen
                      : AppColors.secondaryText,
                  size: 20,
                ),
                onPressed: onLikeTap,
              ),
            if (showTrackNumber)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  song.durationString,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(
                Icons.more_vert,
                color: AppColors.secondaryText,
                size: 20,
              ),
              onPressed: onMenuTap,
            ),
          ],
        ),
      ),
    );
  }
}
