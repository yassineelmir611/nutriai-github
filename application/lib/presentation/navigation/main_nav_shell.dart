import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainNavShell extends StatelessWidget {
  const MainNavShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  bool _isSelected(String routePrefix) => location.startsWith(routePrefix);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedDashboard = _isSelected('/dashboard');
    final selectedAnalyze = _isSelected('/analyze');
    final selectedGallery = _isSelected('/gallery');
    final selectedChat = _isSelected('/chat');
    final selectedProfile = _isSelected('/profile');

    return Scaffold(
      body: child,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 76,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.58),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.08),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.grid_view_rounded,
                selected: selectedDashboard,
                onTap: () => context.go('/dashboard'),
              ),
              _NavItem(
                icon: Icons.photo_library_rounded,
                selected: selectedGallery,
                onTap: () => context.go('/gallery'),
              ),
              _CenterActionButton(
                selected: selectedAnalyze,
                onTap: () => context.go('/analyze'),
              ),
              _NavItem(
                icon: Icons.chat_bubble_outline_rounded,
                selected: selectedChat,
                onTap: () => context.go('/chat'),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                selected: selectedProfile,
                onTap: () => context.go('/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
          size: 24,
        ),
      ),
    );
  }
}

class _CenterActionButton extends StatelessWidget {
  const _CenterActionButton({
    required this.selected,
    required this.onTap,
  });

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.primary,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: selected ? 0.30 : 0.18),
                blurRadius: selected ? 20 : 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}
