import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _audioQuality = 'Automatic';
  bool _normalizeVolume = true;
  double _crossfade = 0;
  bool _gaplessPlayback = true;
  bool _showUnplayedInQueue = false;
  bool _autoplay = true;
  bool _newMusicAlerts = true;
  bool _playlistUpdates = true;
  bool _friendActivity = false;
  bool _podcastAlerts = true;
  bool _spotifyNews = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSection(
            'Playback',
            [
              _buildDropdownSetting(
                'Audio Quality',
                _audioQuality,
                ['Automatic', 'Low', 'Normal', 'High'],
                (value) {
                  setState(() {
                    _audioQuality = value!;
                  });
                },
              ),
              _buildLockedSetting(
                'Download audio quality',
                'Premium only',
              ),
              _buildSwitchSetting(
                'Normalize volume',
                'Set the same volume level for all songs',
                _normalizeVolume,
                (value) {
                  setState(() {
                    _normalizeVolume = value;
                  });
                },
              ),
              _buildSliderSetting(
                'Crossfade',
                'Allows you to crossfade between songs',
                _crossfade,
                0,
                12,
                (value) {
                  setState(() {
                    _crossfade = value;
                  });
                },
              ),
              _buildSwitchSetting(
                'Gapless playback',
                'Allows gapless playback',
                _gaplessPlayback,
                (value) {
                  setState(() {
                    _gaplessPlayback = value;
                  });
                },
              ),
              _buildSwitchSetting(
                'Show unplayed songs in queue',
                '',
                _showUnplayedInQueue,
                (value) {
                  setState(() {
                    _showUnplayedInQueue = value;
                  });
                },
              ),
              _buildSwitchSetting(
                'Autoplay',
                "Enjoy nonstop music. When your audio ends, we'll play you something similar",
                _autoplay,
                (value) {
                  setState(() {
                    _autoplay = value;
                  });
                },
              ),
            ],
          ),
          const Divider(color: AppColors.panelBackground, height: 32),
          _buildSection(
            'Notifications',
            [
              _buildSwitchSetting(
                'New music alerts',
                'Get notified when artists you follow release new music',
                _newMusicAlerts,
                (value) {
                  setState(() {
                    _newMusicAlerts = value;
                  });
                },
              ),
              _buildSwitchSetting(
                'Playlist updates',
                '',
                _playlistUpdates,
                (value) {
                  setState(() {
                    _playlistUpdates = value;
                  });
                },
              ),
              _buildSwitchSetting(
                'Friend activity',
                '',
                _friendActivity,
                (value) {
                  setState(() {
                    _friendActivity = value;
                  });
                },
              ),
              _buildSwitchSetting(
                'Podcast new episodes',
                '',
                _podcastAlerts,
                (value) {
                  setState(() {
                    _podcastAlerts = value;
                  });
                },
              ),
              _buildSwitchSetting(
                'Spotify news and offers',
                '',
                _spotifyNews,
                (value) {
                  setState(() {
                    _spotifyNews = value;
                  });
                },
              ),
            ],
          ),
          const Divider(color: AppColors.panelBackground, height: 32),
          Padding(
            padding: const EdgeInsets.all(24),
            child: TextButton(
              onPressed: () {
                _showLogoutDialog();
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.destructive,
              ),
              child: Text(
                'Log Out',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.destructive,
                ),
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: AppTextStyles.headingMedium,
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildSwitchSetting(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      title: Text(
        title,
        style: AppTextStyles.bodyLarge,
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.secondaryText,
              ),
            )
          : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.spotifyGreen,
      ),
    );
  }

  Widget _buildDropdownSetting(
    String title,
    String value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return ListTile(
      title: Text(
        title,
        style: AppTextStyles.bodyLarge,
      ),
      trailing: DropdownButton<String>(
        value: value,
        dropdownColor: AppColors.panelBackground,
        style: AppTextStyles.bodyMedium,
        underline: Container(),
        items: options
            .map((option) => DropdownMenuItem(
                  value: option,
                  child: Text(option),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSliderSetting(
    String title,
    String subtitle,
    double value,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Column(
      children: [
        ListTile(
          title: Text(
            title,
            style: AppTextStyles.bodyLarge,
          ),
          subtitle: Text(
            subtitle,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${min.toInt()}s',
                style: AppTextStyles.bodySmall,
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.spotifyGreen,
                    inactiveTrackColor: AppColors.secondaryText,
                    thumbColor: AppColors.primaryText,
                  ),
                  child: Slider(
                    value: value,
                    min: min,
                    max: max,
                    onChanged: onChanged,
                  ),
                ),
              ),
              Text(
                '${max.toInt()}s',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLockedSetting(String title, String subtitle) {
    return ListTile(
      title: Text(
        title,
        style: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.secondaryText.withOpacity(0.5),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.secondaryText.withOpacity(0.5),
        ),
      ),
      trailing: Icon(
        Icons.lock,
        color: AppColors.secondaryText.withOpacity(0.5),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.panelBackground,
        title: Text(
          'Are you sure you want to log out?',
          style: AppTextStyles.headingMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.primaryText,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              await ApiService().logout();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/welcome',
                  (route) => false,
                );
              }
            },
            child: Text(
              'Log out',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.destructive,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
