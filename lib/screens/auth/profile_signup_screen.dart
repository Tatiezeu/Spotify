import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../widgets/sportify_button.dart';

class ProfileSignupScreen extends StatefulWidget {
  const ProfileSignupScreen({super.key});

  @override
  State<ProfileSignupScreen> createState() => _ProfileSignupScreenState();
}

class _ProfileSignupScreenState extends State<ProfileSignupScreen> {
  final _nameController = TextEditingController();
  String? _selectedGender;
  int? _selectedDay;
  int? _selectedMonth;
  int? _selectedYear;

  bool get _isFormValid {
    return _nameController.text.isNotEmpty &&
        _selectedDay != null &&
        _selectedMonth != null &&
        _selectedYear != null &&
        _selectedGender != null;
  }

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "What's your name?",
                style: AppTextStyles.headingLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                style: AppTextStyles.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Enter your name',
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 32),
              Text(
                'Date of birth',
                style: AppTextStyles.headingLarge,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedDay,
                      decoration: InputDecoration(
                        hintText: 'Day',
                        filled: true,
                        fillColor: AppColors.cardBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      dropdownColor: AppColors.panelBackground,
                      style: AppTextStyles.bodyLarge,
                      items: List.generate(31, (index) => index + 1)
                          .map((day) => DropdownMenuItem(
                                value: day,
                                child: Text(day.toString()),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDay = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedMonth,
                      decoration: InputDecoration(
                        hintText: 'Month',
                        filled: true,
                        fillColor: AppColors.cardBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      dropdownColor: AppColors.panelBackground,
                      style: AppTextStyles.bodyLarge,
                      items: List.generate(12, (index) => index + 1)
                          .map((month) => DropdownMenuItem(
                                value: month,
                                child: Text(month.toString()),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedMonth = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedYear,
                      decoration: InputDecoration(
                        hintText: 'Year',
                        filled: true,
                        fillColor: AppColors.cardBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      dropdownColor: AppColors.panelBackground,
                      style: AppTextStyles.bodyLarge,
                      items: List.generate(100, (index) => 2024 - index)
                          .map((year) => DropdownMenuItem(
                                value: year,
                                child: Text(year.toString()),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedYear = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                "What's your gender?",
                style: AppTextStyles.headingLarge,
              ),
              const SizedBox(height: 16),
              _buildGenderOption('Man'),
              _buildGenderOption('Woman'),
              _buildGenderOption('Non-binary'),
              _buildGenderOption('Something else'),
              _buildGenderOption('Prefer not to say'),
              const SizedBox(height: 32),
              SpotifyButton(
                text: 'Sign Up',
                onPressed: _isFormValid
                    ? () {
                        Navigator.of(context).pushNamed('/home');
                      }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderOption(String gender) {
    final isSelected = _selectedGender == gender;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = gender;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? AppColors.spotifyGreen : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.spotifyGreen
                      : AppColors.secondaryText,
                  width: 2,
                ),
                color: isSelected
                    ? AppColors.spotifyGreen
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.circle,
                      size: 12,
                      color: AppColors.primaryText,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              gender,
              style: AppTextStyles.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
