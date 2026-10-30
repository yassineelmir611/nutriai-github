import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/body_metrics_utils.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../providers/core_providers.dart';
import '../../providers/profile_provider.dart';
import '../../providers/steps_provider.dart';
import '../../providers/theme_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _fatController = TextEditingController();
  final _stepsController = TextEditingController();

  String? _imagePath;
  bool _isSaving = false;
  bool _didLoadInitialData = false;

  @override
  void initState() {
    super.initState();
    _heightController.addListener(_refresh);
    _weightController.addListener(_refresh);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _stepsController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    setState(() => _imagePath = picked.path);
  }

  void _recalculateGoals() {
    final weight = double.tryParse(_weightController.text.trim());
    final height = double.tryParse(_heightController.text.trim());
    if (weight == null || height == null) return;

    final calc = ref.read(nutritionCalculatorProvider);
    _caloriesController.text = calc
        .calculateDailyCalories(weight: weight, height: height)
        .toStringAsFixed(0);
    _proteinController.text =
        calc.calculateDailyProtein(weight: weight).toStringAsFixed(1);
    _fatController.text =
        calc.calculateDailyFat(weight: weight).toStringAsFixed(1);
    _refresh();
  }

  Future<void> _save() async {
    final profile = ref.read(profileProvider).value;
    if (profile == null) return;

    final height = double.tryParse(_heightController.text.trim());
    final weight = double.tryParse(_weightController.text.trim());
    final calories = double.tryParse(_caloriesController.text.trim());
    final protein = double.tryParse(_proteinController.text.trim());
    final fat = double.tryParse(_fatController.text.trim());
    final stepsGoal = int.tryParse(_stepsController.text.trim());

    if (height == null ||
        weight == null ||
        calories == null ||
        protein == null ||
        fat == null ||
        stepsGoal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please complete all numeric fields with valid values.')),
      );
      return;
    }

    if (height <= 0 || weight <= 0 || stepsGoal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Height, weight and steps goal must be greater than 0.')),
      );
      return;
    }

    final updated = profile.copyWith(
      name: _nameController.text.trim().isEmpty
          ? profile.name
          : _nameController.text.trim(),
      height: height,
      weight: weight,
      profileImagePath: _imagePath ?? profile.profileImagePath,
      dailyCaloriesGoal: calories,
      dailyProteinGoal: protein,
      dailyFatGoal: fat,
      dailyStepsGoal: stepsGoal,
    );

    setState(() => _isSaving = true);
    await ref.read(profileProvider.notifier).updateProfile(updated);
    ref.read(stepsProvider.notifier).syncGoalFromProfile();
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')));
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).value;
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    if (profile == null) {
      return const Scaffold(body: Center(child: Text('Profile not found.')));
    }

    if (!_didLoadInitialData) {
      _nameController.text = profile.name;
      _heightController.text = profile.height.toStringAsFixed(1);
      _weightController.text = profile.weight.toStringAsFixed(1);
      _caloriesController.text = profile.dailyCaloriesGoal.toStringAsFixed(0);
      _proteinController.text = profile.dailyProteinGoal.toStringAsFixed(1);
      _fatController.text = profile.dailyFatGoal.toStringAsFixed(1);
      _stepsController.text = profile.dailyStepsGoal.toString();
      _imagePath = profile.profileImagePath;
      _didLoadInitialData = true;
    }

    final weight =
        double.tryParse(_weightController.text.trim()) ?? profile.weight;
    final height =
        double.tryParse(_heightController.text.trim()) ?? profile.height;
    final bmi =
        BodyMetricsUtils.calculateBmi(weightKg: weight, heightCm: height);
    final bmiLabel = BodyMetricsUtils.bmiCategory(bmi);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Container(
        decoration: AppTheme.pageDecoration,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            CustomCard(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                      backgroundImage: _imagePath != null
                          ? FileImage(File(_imagePath!))
                          : null,
                      child: _imagePath == null
                          ? const Icon(Icons.person, size: 42)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                      onPressed: _pickImage, child: const Text('Change photo')),
                  const SizedBox(height: 8),
                  CustomTextField(
                      controller: _nameController,
                      label: 'Name',
                      prefixIcon: Icons.person_outline),
                ],
              ),
            ),
            const SizedBox(height: 12),
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Body Metrics',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _heightController,
                          label: 'Height (cm)',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          prefixIcon: Icons.height,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CustomTextField(
                          controller: _weightController,
                          label: 'Weight (kg)',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          prefixIcon: Icons.monitor_weight_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.accentSage.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.health_and_safety_outlined,
                            color: AppTheme.accentSage),
                        const SizedBox(width: 10),
                        Text(
                          'BMI: ${bmi.toStringAsFixed(1)} ($bmiLabel)',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daily Goals',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  CustomTextField(
                    controller: _caloriesController,
                    label: 'Daily Calories Goal',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    prefixIcon: Icons.local_fire_department_outlined,
                  ),
                  const SizedBox(height: 10),
                  CustomTextField(
                    controller: _proteinController,
                    label: 'Daily Protein Goal (g)',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    prefixIcon: Icons.fitness_center,
                  ),
                  const SizedBox(height: 10),
                  CustomTextField(
                    controller: _fatController,
                    label: 'Daily Fat Goal (g)',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    prefixIcon: Icons.water_drop_outlined,
                  ),
                  const SizedBox(height: 10),
                  CustomTextField(
                    controller: _stepsController,
                    label: 'Daily Steps Goal',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.directions_walk_rounded,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _recalculateGoals,
                      icon: const Icon(Icons.auto_awesome_outlined),
                      label:
                          const Text('Recalculate from current body metrics'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Appearance',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    value: isDarkMode,
                    contentPadding: EdgeInsets.zero,
                    secondary: Icon(
                      isDarkMode
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                    ),
                    title: const Text('Dark mode'),
                    subtitle: Text(isDarkMode
                        ? 'Enabled for a low-light interface'
                        : 'Use the bright interface style'),
                    onChanged: (value) {
                      ref.read(themeModeProvider.notifier).setDarkMode(value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
                label: 'Save changes', isLoading: _isSaving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
