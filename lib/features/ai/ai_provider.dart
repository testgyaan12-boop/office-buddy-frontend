import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';

class ChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AIState {
  final List<ChatMessage> messages;
  final bool isLoading;

  const AIState({
    this.messages = const [],
    this.isLoading = false,
  });

  AIState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
  }) {
    return AIState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AINotifier extends StateNotifier<AIState> {
  final ApiClient _apiClient;

  AINotifier(this._apiClient) : super(AIState(messages: [
    ChatMessage(role: 'assistant', content: 'Hi! I\'m your OfficeBuddy AI assistant. Ask me anything about your documents, career advice, or office management!'),
  ]));

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    state = state.copyWith(
      messages: [...state.messages, ChatMessage(role: 'user', content: text.trim())],
      isLoading: true,
    );

    try {
      final response = await _apiClient.post(
        ApiEndpoints.aiChat,
        data: {'message': text.trim()},
      );
      final reply = response.data['response'] as String? ?? 'No response';
      state = state.copyWith(
        messages: [...state.messages, ChatMessage(role: 'assistant', content: reply)],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        messages: [...state.messages, ChatMessage(role: 'assistant', content: 'Sorry, connection failed. Please try again.')],
        isLoading: false,
      );
    }
  }

  void clearChat() {
    state = AIState(messages: [
      ChatMessage(role: 'assistant', content: 'Hi! I\'m your OfficeBuddy AI assistant. Ask me anything about your documents, career advice, or office management!'),
    ]);
  }
}

final aiProvider = StateNotifierProvider<AINotifier, AIState>((ref) {
  return AINotifier(ref.read(apiClientProvider));
});
