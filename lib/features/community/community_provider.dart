import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../auth/auth_provider.dart';
import 'models/conversation_model.dart';
import 'models/friend_model.dart';
import 'models/friend_request_model.dart';
import 'models/message_model.dart';

class CommunityState {
  final bool isLoading;
  final String? error;
  final List<FriendModel> friends;
  final List<FriendRequestModel> incomingRequests;
  final List<FriendRequestModel> outgoingRequests;
  final List<Map<String, dynamic>> allUsers;
  final List<ConversationModel> conversations;
  final List<MessageModel> messages;
  final String? activeConversationId;
  final Map<String, List<Map<String, dynamic>>> userCompanies;

  CommunityState({
    this.isLoading = false,
    this.error,
    this.friends = const [],
    this.incomingRequests = const [],
    this.outgoingRequests = const [],
    this.allUsers = const [],
    this.conversations = const [],
    this.messages = const [],
    this.activeConversationId,
    this.userCompanies = const {},
  });

  CommunityState copyWith({
    bool? isLoading,
    String? error,
    List<FriendModel>? friends,
    List<FriendRequestModel>? incomingRequests,
    List<FriendRequestModel>? outgoingRequests,
    List<Map<String, dynamic>>? allUsers,
    List<ConversationModel>? conversations,
    List<MessageModel>? messages,
    String? activeConversationId,
    Map<String, List<Map<String, dynamic>>>? userCompanies,
  }) {
    return CommunityState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      friends: friends ?? this.friends,
      incomingRequests: incomingRequests ?? this.incomingRequests,
      outgoingRequests: outgoingRequests ?? this.outgoingRequests,
      allUsers: allUsers ?? this.allUsers,
      conversations: conversations ?? this.conversations,
      messages: messages ?? this.messages,
      activeConversationId: activeConversationId ?? this.activeConversationId,
      userCompanies: userCompanies ?? this.userCompanies,
    );
  }

  List<FriendModel> get onlineFriends =>
      friends.where((f) => f.online).toList();
}

class CommunityNotifier extends StateNotifier<CommunityState> {
  final ApiClient _apiClient;
  Timer? _messageTimer;

  CommunityNotifier(this._apiClient) : super(CommunityState());

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }

  Future<void> loadCommunity() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await Future.wait([
        loadFriends(),
        loadAllUsers(),
        loadIncomingRequests(),
        loadOutgoingRequests(),
        loadConversations(),
      ]);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadFriends() async {
    try {
      final res = await _apiClient.get(ApiEndpoints.communityFriends);
      final raw = res.data;
      final list = raw != null
          ? (raw as List).map((j) => FriendModel.fromJson(j)).toList()
          : <FriendModel>[];
      state = state.copyWith(friends: list);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadAllUsers() async {
    try {
      final res = await _apiClient.get(ApiEndpoints.communityUsers);
      final raw = res.data;
      final list = raw != null
          ? List<Map<String, dynamic>>.from(raw)
          : <Map<String, dynamic>>[];
      state = state.copyWith(allUsers: list);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadIncomingRequests() async {
    try {
      final res = await _apiClient.get(ApiEndpoints.friendRequestsIncoming);
      final raw = res.data;
      final list = raw != null
          ? (raw as List).map((j) => FriendRequestModel.fromJson(j)).toList()
          : <FriendRequestModel>[];
      state = state.copyWith(incomingRequests: list);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadOutgoingRequests() async {
    try {
      final res = await _apiClient.get(ApiEndpoints.friendRequestsOutgoing);
      final raw = res.data;
      final list = raw != null
          ? (raw as List).map((j) => FriendRequestModel.fromJson(j)).toList()
          : <FriendRequestModel>[];
      state = state.copyWith(outgoingRequests: list);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadConversations() async {
    try {
      final res = await _apiClient.get(ApiEndpoints.conversations);
      final raw = res.data;
      final list = raw != null
          ? (raw as List).map((j) => ConversationModel.fromJson(j)).toList()
          : <ConversationModel>[];
      state = state.copyWith(conversations: list);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> sendFriendRequest(String receiverId) async {
    try {
      await _apiClient.post(
        ApiEndpoints.friendRequests,
        data: {'receiverId': receiverId},
      );
      await Future.wait([loadOutgoingRequests(), loadAllUsers()]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> acceptRequest(String requestId) async {
    try {
      await _apiClient.put('${ApiEndpoints.friendRequests}/$requestId/accept');
      await Future.wait([
        loadIncomingRequests(),
        loadFriends(),
        loadAllUsers(),
      ]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> rejectRequest(String requestId) async {
    try {
      await _apiClient.put('${ApiEndpoints.friendRequests}/$requestId/reject');
      await loadIncomingRequests();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<String?> getOrCreateConversation(String otherUserId) async {
    try {
      final res = await _apiClient.post(
        ApiEndpoints.conversations,
        data: {'otherUserId': otherUserId},
      );
      final convId = res.data['id'] as String;
      state = state.copyWith(activeConversationId: convId);
      return convId;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<void> loadMessages(String conversationId) async {
    try {
      final res = await _apiClient.get(
        '${ApiEndpoints.conversations}/$conversationId/messages',
      );
      final raw = res.data;
      final list = raw != null
          ? (raw as List).map((j) => MessageModel.fromJson(j)).toList()
          : <MessageModel>[];
      state = state.copyWith(
          messages: list, activeConversationId: conversationId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void startMessagePolling(String conversationId) {
    _messageTimer?.cancel();
    loadMessages(conversationId);
    _messageTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      loadMessages(conversationId);
    });
  }

  void stopMessagePolling() {
    _messageTimer?.cancel();
    _messageTimer = null;
  }

  Future<void> sendMessage(String conversationId, String content) async {
    if (content.trim().isEmpty) return;
    try {
      await _apiClient.post(
        '${ApiEndpoints.conversations}/$conversationId/messages',
        data: {'content': content, 'type': 'TEXT'},
      );
      await loadMessages(conversationId);
      await loadConversations();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<List<Map<String, dynamic>>> loadUserCompanies(String userId) async {
    final cached = state.userCompanies[userId];
    if (cached != null) return cached;
    try {
      final res = await _apiClient.get('${ApiEndpoints.communityUserCompanies}$userId/companies');
      final raw = res.data;
      final list = raw != null
          ? List<Map<String, dynamic>>.from(raw)
          : <Map<String, dynamic>>[];
      state = state.copyWith(
        userCompanies: {...state.userCompanies, userId: list},
      );
      return list;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }
}

final communityProvider =
    StateNotifierProvider<CommunityNotifier, CommunityState>((ref) {
  ref.watch(authProvider.select((s) => s.user?.id));
  final notifier = CommunityNotifier(ref.read(apiClientProvider));
  Future.microtask(() => notifier.loadCommunity());
  return notifier;
});
