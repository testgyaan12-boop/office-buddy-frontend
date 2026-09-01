import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../auth/auth_provider.dart';
import 'models/timeline_event.dart';

class TimelineState {
  final bool isLoading;
  final String? error;
  final List<TimelineEvent> events;

  const TimelineState({
    this.isLoading = false,
    this.error,
    this.events = const [],
  });

  TimelineState copyWith({
    bool? isLoading,
    String? error,
    List<TimelineEvent>? events,
  }) {
    return TimelineState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      events: events ?? this.events,
    );
  }
}

class TimelineNotifier extends StateNotifier<TimelineState> {
  final ApiClient _apiClient;

  TimelineNotifier(this._apiClient) : super(const TimelineState());

  Future<void> loadTimeline({String? companyId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final params = companyId != null ? <String, dynamic>{'companyId': companyId} : null;
      final response = await _apiClient.get(
        ApiEndpoints.timeline,
        queryParameters: params,
      );
      final events = (response.data as List)
          .map((e) => TimelineEvent.fromJson(e as Map<String, dynamic>))
          .toList();
      state = TimelineState(events: events);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load timeline',
      );
    }
  }

  Future<void> addEvent(TimelineEvent event) async {
    try {
      await _apiClient.post(
        ApiEndpoints.timelineEvents,
        data: {
          'title': event.title,
          'description': event.description,
          'eventType': event.type,
          'companyName': event.companyName,
          'eventDate': event.eventDate.toIso8601String(),
        },
      );
      await loadTimeline();
    } catch (e) {
      state = state.copyWith(error: 'Failed to add event');
    }
  }
}

final timelineProvider =
    StateNotifierProvider<TimelineNotifier, TimelineState>((ref) {
  ref.watch(authProvider.select((s) => s.user?.id));
  final notifier = TimelineNotifier(ref.read(apiClientProvider));
  Future.microtask(() => notifier.loadTimeline());
  return notifier;
});
