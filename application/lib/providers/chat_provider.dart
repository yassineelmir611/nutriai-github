import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/models/chat_message.dart';
import 'core_providers.dart';
import 'meals_provider.dart';
import 'profile_provider.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  const ChatState({required this.messages, this.isLoading = false, this.error});

  ChatState copyWith(
      {List<ChatMessage>? messages, bool? isLoading, String? error}) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(this._ref) : super(const ChatState(messages: [])) {
    loadChat();
  }

  final Ref _ref;

  void loadChat() {
    final messages = _ref.read(localRepositoryProvider).getChatMessages();
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    state = state.copyWith(messages: messages);
  }

  Future<void> resetChat() async {
    await _ref.read(localRepositoryProvider).clearChatMessages();
    state = const ChatState(messages: [], isLoading: false, error: null);
  }

  Future<void> sendMessage(String content) async {
    final profile = _ref.read(profileProvider).value;
    if (profile == null || content.trim().isEmpty) return;

    final userMessage = ChatMessage(
      id: const Uuid().v4(),
      role: 'user',
      content: content.trim(),
      timestamp: DateTime.now(),
    );

    final nextMessages = [...state.messages, userMessage];
    state =
        state.copyWith(messages: nextMessages, isLoading: true, error: null);
    await _ref.read(localRepositoryProvider).saveChatMessages(nextMessages);

    try {
      final today = _ref.read(dailyTotalsProvider);
      final foods = _ref
          .read(todayMealsProvider)
          .map((meal) => meal.foodName.trim())
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();
      final mealSummaries = _ref.read(todayMealsProvider).map((meal) {
        return '${meal.foodName} (${meal.gramsConsumed.toStringAsFixed(0)} g, '
            '${meal.calories.toStringAsFixed(0)} kcal, '
            '${meal.protein.toStringAsFixed(1)} g protein, '
            '${meal.fat.toStringAsFixed(1)} g fat)';
      }).toList();
      final answer = await _ref.read(chatbotServiceProvider).sendMessage(
            profile: profile,
            history: state.messages,
            newMessage: content,
            today: today,
            foods: foods,
            mealSummaries: mealSummaries,
          );

      final aiMessage = ChatMessage(
        id: const Uuid().v4(),
        role: 'ai',
        content: answer,
        timestamp: DateTime.now(),
      );

      final updated = [...nextMessages, aiMessage];
      state = state.copyWith(messages: updated, isLoading: false, error: null);
      await _ref.read(localRepositoryProvider).saveChatMessages(updated);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final chatProvider =
    StateNotifierProvider<ChatNotifier, ChatState>((ref) => ChatNotifier(ref));
