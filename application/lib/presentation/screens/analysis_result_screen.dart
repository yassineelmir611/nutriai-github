import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/nutrition_utils.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/food_analysis_result.dart';
import '../../data/models/meal_entry.dart';
import '../../providers/meals_provider.dart';

class AnalysisResultArgs {
  final String imagePath;
  final FoodAnalysisResult per100gResult;

  const AnalysisResultArgs({
    required this.imagePath,
    required this.per100gResult,
  });
}

class AnalysisResultScreen extends ConsumerStatefulWidget {
  const AnalysisResultScreen({super.key, required this.args});

  final AnalysisResultArgs args;

  @override
  ConsumerState<AnalysisResultScreen> createState() =>
      _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends ConsumerState<AnalysisResultScreen> {
  final _gramsController = TextEditingController(text: '100');
  double _grams = 100;
  late FoodAnalysisResult _selectedResult;

  @override
  void initState() {
    super.initState();
    _selectedResult = widget.args.per100gResult;
  }

  @override
  void dispose() {
    _gramsController.dispose();
    super.dispose();
  }

  Future<void> _addMeal() async {
    final consumed = NutritionUtils.scaleResult(_selectedResult, _grams);

    final meal = MealEntry.fromAnalysis(
      id: const Uuid().v4(),
      dateTime: DateTime.now(),
      imagePath: widget.args.imagePath,
      foodName: _selectedResult.name,
      grams: _grams,
      consumedValues: consumed,
    );

    await ref.read(mealsProvider.notifier).addMeal(meal);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Meal added to today successfully.')),
    );
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final result = _selectedResult;
    final consumed = NutritionUtils.scaleResult(result, _grams);

    return Scaffold(
      appBar: AppBar(title: const Text('Analysis Result')),
      body: Container(
        decoration: AppTheme.pageDecoration,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Hero(
              tag: widget.args.imagePath,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  File(widget.args.imagePath),
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              result.name,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Values shown below are for ${_grams.toStringAsFixed(0)} g consumed',
            ),
            if (result.confidence > 0 || result.topPredictions.isNotEmpty) ...[
              const SizedBox(height: 12),
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Model insight',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Recognition confidence: ${(result.confidence * 100).toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Source: ${_sourceLabel(result.source)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    if (result.rawLabel != null &&
                        result.rawLabel!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Model label: ${result.rawLabel}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                    if (result.topPredictions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Not the right dish? Tap another prediction below.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: result.topPredictions
                            .map((candidate) =>
                                _predictionChip(context, candidate, result))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            CustomCard(
              child: Column(
                children: [
                  _metric(
                    'Calories',
                    '${consumed.calories.toStringAsFixed(0)} kcal',
                    AppTheme.caloriesColor,
                  ),
                  _metric(
                    'Protein',
                    '${consumed.protein.toStringAsFixed(1)} g',
                    AppTheme.proteinColor,
                  ),
                  _metric(
                    'Fat',
                    '${consumed.fat.toStringAsFixed(1)} g',
                    AppTheme.fatColor,
                  ),
                  _metric(
                    'Carbs',
                    '${consumed.carbs.toStringAsFixed(1)} g',
                    AppTheme.accentOlive,
                  ),
                  _metric(
                    'Fiber',
                    '${consumed.fiber.toStringAsFixed(1)} g',
                    AppTheme.accentSage,
                  ),
                  _metric(
                    'Sugar',
                    '${consumed.sugar.toStringAsFixed(1)} g',
                    AppTheme.fatColor,
                  ),
                  _metric(
                    'Sodium',
                    '${consumed.sodium.toStringAsFixed(1)} mg',
                    AppTheme.proteinColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _gramsController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'How many grams did you eat?',
              ),
              onChanged: (value) {
                final grams = double.tryParse(value);
                if (grams == null || grams <= 0) return;
                setState(() => _grams = grams);
              },
            ),
            const SizedBox(height: 12),
            Slider(
              min: 10,
              max: 600,
              value: _grams.clamp(10, 600),
              onChanged: (value) {
                setState(() {
                  _grams = value;
                  _gramsController.text = value.toStringAsFixed(0);
                });
              },
            ),
            const SizedBox(height: 10),
            PrimaryButton(label: 'Add to my day', onPressed: _addMeal),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  String _sourceLabel(String source) {
    switch (source) {
      case 'efficientnet_b2':
        return 'EfficientNet-B2';
      case 'heuristic_fallback':
        return 'Fallback heuristic';
      default:
        return source;
    }
  }

  Widget _predictionChip(
    BuildContext context,
    FoodPredictionCandidate candidate,
    FoodAnalysisResult result,
  ) {
    final isSelected = result.rawLabel == candidate.label;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        setState(() {
          _selectedResult = FoodAnalysisResult.fromCandidate(
            candidate,
            topPredictions: widget.args.per100gResult.topPredictions,
          );
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    candidate.displayName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${(candidate.confidence * 100).toStringAsFixed(1)}%  •  ${candidate.calories.toStringAsFixed(0)} kcal',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
