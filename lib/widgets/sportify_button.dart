import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';

class SpotifyButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final Widget? icon;
  final bool isFullWidth;

  const SpotifyButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isPrimary = true,
    this.icon,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: 48,
      child: isPrimary
          ? ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.spotifyGreen,
                foregroundColor: AppColors.primaryText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(500),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 32),
              ),
              child: icon != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        icon!,
                        const SizedBox(width: 12),
                        Text(
                          text,
                          style: AppTextStyles.labelLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      text,
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryText,
                side: const BorderSide(color: AppColors.primaryText, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(500),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 32),
              ),
              child: icon != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        icon!,
                        const SizedBox(width: 12),
                        Text(
                          text,
                          style: AppTextStyles.labelLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      text,
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
    );
  }
}
