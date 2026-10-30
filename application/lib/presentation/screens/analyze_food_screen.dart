import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/secondary_button.dart';
import '../../providers/analysis_provider.dart';
import 'analysis_result_screen.dart';

class AnalyzeFoodScreen extends ConsumerStatefulWidget {
  const AnalyzeFoodScreen({super.key});

  @override
  ConsumerState<AnalyzeFoodScreen> createState() => _AnalyzeFoodScreenState();
}

class _AnalyzeFoodScreenState extends ConsumerState<AnalyzeFoodScreen> {
  final _picker = ImagePicker();

  Future<void> _pick(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;
    ref.read(analysisProvider.notifier).setImage(File(file.path));
  }

  Future<void> _analyze() async {
    await ref.read(analysisProvider.notifier).analyze();
    final state = ref.read(analysisProvider);
    if (!mounted) return;
    if (state.per100gResult != null && state.imageFile != null) {
      context.push(
        '/analysis-result',
        extra: AnalysisResultArgs(
          imagePath: state.imageFile!.path,
          per100gResult: state.per100gResult!,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analysisProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Analyze Food')),
      body: Stack(
        children: [
          Container(
            decoration: AppTheme.pageDecoration,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              children: [
                CustomCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.mutedSurface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'Capture your meal or choose from gallery',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          color:
                              Theme.of(context).colorScheme.secondaryContainer,
                          height: 320,
                          width: double.infinity,
                          child: state.imageFile == null
                              ? const Center(
                                  child: Icon(
                                    Icons.camera_alt_outlined,
                                    size: 60,
                                  ),
                                )
                              : Image.file(state.imageFile!, fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: SecondaryButton(
                              label: 'Camera',
                              icon: Icons.camera_alt_outlined,
                              onPressed: () => _pick(ImageSource.camera),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SecondaryButton(
                              label: 'Gallery',
                              icon: Icons.photo_library_outlined,
                              onPressed: () => _pick(ImageSource.gallery),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Analyze my food',
                  icon: Icons.auto_awesome,
                  isLoading: state.isLoading,
                  onPressed: state.imageFile == null ? null : _analyze,
                ),
                if (state.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    state.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (state.isLoading)
            Container(
              color:
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.72),
              child: const LoadingIndicator(message: 'Analyzing your food...'),
            ),
        ],
      ),
    );
  }
}
