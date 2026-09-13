import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import 'models/group_model.dart';

class GroupState {
  final bool isLoading;
  final String? error;
  final List<GroupModel> allGroups;
  final List<GroupModel> myGroups;
  final List<GroupModel> myRequests;
  final List<GroupMemberModel> members;
  final List<GroupMessageModel> messages;
  final String? selectedGroupId;

  GroupState({
    this.isLoading = false,
    this.error,
    this.allGroups = const [],
    this.myGroups = const [],
    this.myRequests = const [],
    this.members = const [],
    this.messages = const [],
    this.selectedGroupId,
  });

  GroupState copyWith({
    bool? isLoading,
    String? error,
    List<GroupModel>? allGroups,
    List<GroupModel>? myGroups,
    List<GroupModel>? myRequests,
    List<GroupMemberModel>? members,
    List<GroupMessageModel>? messages,
    String? selectedGroupId,
  }) => GroupState(
    isLoading: isLoading ?? this.isLoading,
    error: error ?? this.error,
    allGroups: allGroups ?? this.allGroups,
    myGroups: myGroups ?? this.myGroups,
    myRequests: myRequests ?? this.myRequests,
    members: members ?? this.members,
    messages: messages ?? this.messages,
    selectedGroupId: selectedGroupId ?? this.selectedGroupId,
  );
}

class GroupNotifier extends StateNotifier<GroupState> {
  final ApiClient _apiClient;
  GroupNotifier(this._apiClient) : super(GroupState());

  Future<void> loadGroups() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final allRes = await _apiClient.get(ApiEndpoints.groups);
      final allList = (allRes.data as List?)?.map((j) => GroupModel.fromJson(j)).toList() ?? [];
      final myRes = await _apiClient.get('/groups/my');
      final myList = (myRes.data as List?)?.map((j) => GroupModel.fromJson(j)).toList() ?? [];
      final reqRes = await _apiClient.get('/groups/my/requests');
      final reqList = (reqRes.data as List?)?.map((j) => GroupModel.fromJson(j)).toList() ?? [];
      state = state.copyWith(allGroups: allList, myGroups: myList, myRequests: reqList, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> requestJoin(String groupId) async {
    try {
      await _apiClient.post('/groups/$groupId/request', data: {});
      await loadGroups();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadMembers(String groupId) async {
    try {
      final res = await _apiClient.get('/admin/groups/$groupId/members');
      final list = (res.data as List?)?.map((j) => GroupMemberModel.fromJson(j)).toList() ?? [];
      state = state.copyWith(members: list);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadMessages(String groupId) async {
    state = state.copyWith(selectedGroupId: groupId);
    try {
      final res = await _apiClient.get('/groups/$groupId/messages');
      final list = (res.data as List?)?.map((j) => GroupMessageModel.fromJson(j)).toList() ?? [];
      state = state.copyWith(messages: list);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> sendMessage(String groupId, String content) async {
    try {
      await _apiClient.post('/groups/$groupId/messages', data: {'content': content});
      await loadMessages(groupId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final groupProvider = StateNotifierProvider<GroupNotifier, GroupState>((ref) {
  return GroupNotifier(ref.read(apiClientProvider));
});
