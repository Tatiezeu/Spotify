import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/sportify_button.dart';

class PasswordSignupScreen extends StatefulWidget {
  final String email;

  const PasswordSignupScreen({
    super.key,
    required this.email,
  });

  @override
  State<PasswordSignupScreen> createState() => _PasswordSignupScreenState();
}

class _PasswordSignupScreenState extends State<PasswordSignupScreen> {
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isValidPassword = false;
  String _passwordStrength = '';
  Color _strengthColor = AppColors.destructive;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
  }

  void _validatePassword() {
    final password = _passwordController.text;
    setState(() {
      _isValidPassword = password.length >= 8;

      if (password.isEmpty) {
        _passwordStrength = '';
      } else if (password.length < 6) {
        _passwordStrength = 'Weak';
        _strengthColor = AppColors.destructive;
      } else if (password.length < 10) {
        _passwordStrength = 'Medium';
        _strengthColor = Colors.orange;
      } else {
        _passwordStrength = 'Strong';
        _strengthColor = AppColors.spotifyGreen;
      }
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create a password',
                style: AppTextStyles.displayMedium,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _passwordController,
                style: AppTextStyles.bodyLarge,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  hintText: 'Enter password',
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: AppColors.secondaryText,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_passwordStrength.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: _strengthColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _passwordStrength,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: _strengthColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Text(
                'Minimum 8 characters required',
                style: AppTextStyles.bodySmall,
              ),
              const Spacer(),
              SpotifyButton(
                text: 'Next',
                onPressed: _isValidPassword
                    ? () {
                        Navigator.of(context).pushNamed('/signup/profile');
                      }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
