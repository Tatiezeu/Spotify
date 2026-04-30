import 'package:flutter/material.dart';
import '../core/constants/app_text_styles.dart';

class CarouselSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const CarouselSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: AppTextStyles.headingMedium,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 240,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: children,
          ),
        ),
      ],
    );
  }
}
