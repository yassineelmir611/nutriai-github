import 'package:flutter/material.dart';

import '../utils/date_utils.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.content,
    required this.role,
    required this.time,
  });

  final String content;
  final String role;
  final DateTime time;

  @override
  Widget build(BuildContext context) {
    final isUser = role == 'user';
    final bg = isUser
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.surface;
    final fg = isUser ? Colors.white : Theme.of(context).colorScheme.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 290),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isUser ? 20 : 8),
              bottomRight: Radius.circular(isUser ? 8 : 20),
            ),
            border: isUser
                ? null
                : Border.all(color: Theme.of(context).colorScheme.outline),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(content, style: TextStyle(color: fg, height: 1.35)),
              const SizedBox(height: 4),
              Text(
                AppDateUtils.formatTimeLabel(time),
                style:
                    TextStyle(color: fg.withValues(alpha: 0.68), fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
