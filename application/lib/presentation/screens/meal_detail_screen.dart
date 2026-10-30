import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../providers/meals_provider.dart';

class MealDetailScreen extends ConsumerStatefulWidget {
  const MealDetailScreen({super.key, required this.mealId});

  final String mealId;

  @override
  ConsumerState<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends ConsumerState<MealDetailScreen> {
  final _gramsController = TextEditingController();

  @override
  void dispose() {
    _gramsController.dispose();
    super.dispose();
  }

  Future<void> _saveEdit() async {
    final meal = ref.read(selectedMealProvider(widget.mealId));
    if (meal == null) return;

    final newGrams = double.tryParse(_gramsController.text.trim());
    if (newGrams == null || newGrams <= 0) return;

    final ratio = newGrams / meal.gramsConsumed;
    final updated = meal.copyWith(
      gramsConsumed: newGrams,
      calories: meal.calories * ratio,
      protein: meal.protein * ratio,
      fat: meal.fat * ratio,
      carbs: meal.carbs * ratio,
      fiber: meal.fiber * ratio,
      sugar: meal.sugar * ratio,
      sodium: meal.sodium * ratio,
      vitamins: meal.vitamins.scale(ratio),
    );

    await ref.read(mealsProvider.notifier).updateMeal(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Meal updated')));
    setState(() {});
  }

  Future<void> _deleteMeal() async {
    await ref.read(mealsProvider.notifier).deleteMeal(widget.mealId);
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final meal = ref.watch(selectedMealProvider(widget.mealId));

    if (meal == null) {
      return const Scaffold(body: Center(child: Text('Meal not found')));
    }

    if (_gramsController.text.isEmpty) {
      _gramsController.text = meal.gramsConsumed.toStringAsFixed(0);
    }

    return Scaffold(
      appBar: AppBar(title: Text(meal.foodName)),
      body: Container(
        decoration: AppTheme.pageDecoration,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (meal.imagePath != null)
              Hero(
                tag: meal.imagePath!,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(File(meal.imagePath!),
                      height: 220, fit: BoxFit.cover),
                ),
              ),
            const SizedBox(height: 12),
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Consumed at ${AppDateUtils.formatFull(meal.dateTime)}'),
                  const SizedBox(height: 12),
                  _line('Calories', '${meal.calories.toStringAsFixed(0)} kcal'),
                  _line('Protein', '${meal.protein.toStringAsFixed(1)} g'),
                  _line('Fat', '${meal.fat.toStringAsFixed(1)} g'),
                  _line('Carbs', '${meal.carbs.toStringAsFixed(1)} g'),
                  _line('Fiber', '${meal.fiber.toStringAsFixed(1)} g'),
                  _line('Sugar', '${meal.sugar.toStringAsFixed(1)} g'),
                  _line('Sodium', '${meal.sodium.toStringAsFixed(1)} mg'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _gramsController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(labelText: 'Edit grams consumed'),
            ),
            const SizedBox(height: 10),
            PrimaryButton(label: 'Save meal update', onPressed: _saveEdit),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _deleteMeal,
              icon: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              label: Text(
                'Delete meal',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600))
        ],
      ),
    );
  }
}
