import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/body_metrics_utils.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../providers/core_providers.dart';
import '../../providers/profile_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _heightController = TextEditingController(text: '170');
  final _weightController = TextEditingController(text: '70');
  final _caloriesController = TextEditingController();
  final _stepsController =
      TextEditingController(text: '${AppConstants.dailyStepsGoal}');
  bool _isSaving = false;

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
    _stepsController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final height = double.tryParse(_heightController.text.trim());
    final weight = double.tryParse(_weightController.text.trim());
    final desiredCalories = double.tryParse(_caloriesController.text.trim());
    final desiredSteps = int.tryParse(_stepsController.text.trim());

    if (name.isEmpty || height == null || weight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please fill your name, height and weight correctly.')),
      );
      return;
    }

    if (desiredSteps != null && desiredSteps <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Steps goal should be greater than 0.')),
      );
      return;
    }

    final calc = ref.read(nutritionCalculatorProvider);
    final calories = desiredCalories ??
        calc.calculateDailyCalories(weight: weight, height: height);
    final protein = calc.calculateDailyProtein(weight: weight);
    final fat = calc.calculateDailyFat(weight: weight);

    setState(() => _isSaving = true);
    await ref.read(profileProvider.notifier).createProfile(
          name: name,
          height: height,
          weight: weight,
          dailyCaloriesGoal: calories,
          dailyProteinGoal: protein,
          dailyFatGoal: fat,
          dailyStepsGoal: desiredSteps ?? AppConstants.dailyStepsGoal,
        );
    if (!mounted) return;
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final weight = double.tryParse(_weightController.text.trim()) ?? 0;
    final height = double.tryParse(_heightController.text.trim()) ?? 0;
    final calc = ref.read(nutritionCalculatorProvider);
    final estimatedCalories =
        calc.calculateDailyCalories(weight: weight, height: height);
    final estimatedProtein = calc.calculateDailyProtein(weight: weight);
    final estimatedFat = calc.calculateDailyFat(weight: weight);
    final bmi =
        BodyMetricsUtils.calculateBmi(weightKg: weight, heightCm: height);
    final bmiCategory = BodyMetricsUtils.bmiCategory(bmi);

    return Scaffold(
      body: Container(
        decoration: AppTheme.pageDecoration,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.10),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: Theme.of(context).brightness == Brightness.dark
                            ? 0.20
                            : 0.04,
                      ),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to NutriAI',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Create your profile and get smart daily targets in seconds.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppTheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CustomCard(
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _nameController,
                      label: 'Name',
                      hint: 'Your name',
                      prefixIcon: Icons.person_outline,
                    ),
                    const SizedBox(height: 12),
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
                    CustomTextField(
                      controller: _caloriesController,
                      label: 'Desired Calories (optional)',
                      hint: 'Leave empty for automatic',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: Icons.local_fire_department_outlined,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _stepsController,
                      label: 'Daily Steps Goal',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.directions_walk_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your smart estimation',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _SmallMetricCard(
                          title: 'BMI',
                          value: bmi <= 0 ? '--' : bmi.toStringAsFixed(1),
                          subtitle: bmiCategory,
                          color: AppTheme.accentSage,
                        ),
                        const SizedBox(width: 8),
                        _SmallMetricCard(
                          title: 'Calories',
                          value: estimatedCalories.toStringAsFixed(0),
                          subtitle: 'kcal/day',
                          color: AppTheme.caloriesColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _SmallMetricCard(
                          title: 'Protein',
                          value: estimatedProtein.toStringAsFixed(0),
                          subtitle: 'g/day',
                          color: AppTheme.proteinColor,
                        ),
                        const SizedBox(width: 8),
                        _SmallMetricCard(
                          title: 'Fat',
                          value: estimatedFat.toStringAsFixed(0),
                          subtitle: 'g/day',
                          color: AppTheme.fatColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                  label: 'Create my profile',
                  isLoading: _isSaving,
                  onPressed: _saveProfile),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallMetricCard extends StatelessWidget {
  const _SmallMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
