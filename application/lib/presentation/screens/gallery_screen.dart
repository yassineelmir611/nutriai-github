import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/date_utils.dart';
import '../../core/widgets/empty_state.dart';
import '../../providers/meals_provider.dart';

class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meals =
        ref.watch(mealsProvider).where((m) => m.imagePath != null).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Gallery')),
      body: meals.isEmpty
          ? const EmptyState(
              title: 'No photos yet',
              subtitle:
                  'Analyze a meal with camera or gallery to build your food gallery.',
              icon: Icons.photo_library_outlined,
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 120),
              itemCount: meals.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.83,
              ),
              itemBuilder: (context, index) {
                final meal = meals[index];
                return GestureDetector(
                  onTap: () => context.push('/meal/${meal.id}'),
                  child: Hero(
                    tag: meal.imagePath!,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(File(meal.imagePath!), fit: BoxFit.cover),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  const Color(0xFF1F2134)
                                      .withValues(alpha: 0.58),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 10,
                            top: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF1DA),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${meal.calories.toStringAsFixed(0)} kcal',
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFB56D28)),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 10,
                            right: 10,
                            bottom: 10,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  meal.foodName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      height: 1.15),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  AppDateUtils.formatFull(meal.dateTime),
                                  style: const TextStyle(
                                      color: Color(0xFFE4E8FF), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
