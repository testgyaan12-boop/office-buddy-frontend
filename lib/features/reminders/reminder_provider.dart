import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import 'models/reminder_model.dart';
import 'services/notification_service.dart';

class ReminderState {
  final List<ReminderModel> reminders;
  final bool isLoading;
  final String? error;

  const ReminderState({this.reminders = const [], this.isLoading = false, this.error});

  ReminderState copyWith({List<ReminderModel>? reminders, bool? isLoading, String? error}) =>
      ReminderState(reminders: reminders ?? this.reminders, isLoading: isLoading ?? this.isLoading, error: error);
}

class ReminderNotifier extends StateNotifier<ReminderState> {
  final ApiClient _apiClient;
  final NotificationService _notifications = NotificationService();
  static const _deviceKey = 'reminder_device_id';

  ReminderNotifier(this._apiClient) : super(const ReminderState()) {
    load();
  }

  Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_deviceKey);
    if (id == null) {
      id = 'dev_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch % 100000}';
      await prefs.setString(_deviceKey, id);
    }
    return id;
  }

  Future<void> load({String? category}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _apiClient.get(ApiEndpoints.reminders, queryParameters: category != null ? {'category': category} : null);
      final list = (res.data as List).map((e) => ReminderModel.fromJson(e as Map<String, dynamic>)).toList();
      list.sort((a, b) => a.remindAt.compareTo(b.remindAt));
      state = state.copyWith(reminders: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadAll() => load();

  Future<void> _schedule(ReminderModel r) async {
    final id = r.id.hashCode & 0x7fffffff;
    await _notifications.scheduleReminder(
      id: id,
      title: r.title,
      body: '${r.typeLabel} • ${r.notifyBeforeLabel} • ${r.description ?? ''} ${r.jd != null ? "JD: ${r.jd}" : ""}'.trim(),
      scheduledDate: r.notifyAt,
    );
    // log history
    try {
      final deviceId = await _getDeviceId();
      await _apiClient.post('${ApiEndpoints.reminders}/${r.id}/history', data: {'deviceId': deviceId, 'status': 'SCHEDULED'});
    } catch (_) {}
  }

  Future<void> addReminder(ReminderModel reminder, {Uint8List? fileBytes, String? fileName}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final deviceId = await _getDeviceId();
      dynamic resData;
      if (fileBytes != null && fileName != null) {
        // multipart with file
        final res = await _apiClient.post(
          ApiEndpoints.reminders,
          data: FormData.fromMap({
            'title': reminder.title,
            'description': reminder.description,
            'jd': reminder.jd,
            'type': reminder.type,
            'category': reminder.category,
            'companyId': reminder.companyId,
            'remindAt': reminder.remindAt.toIso8601String(),
            'notifyBeforeMinutes': reminder.notifyBefore.inMinutes,
            'deviceId': deviceId,
            'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
          }),
        );
        resData = res.data;
      } else {
        final res = await _apiClient.post(ApiEndpoints.reminders, data: {
          'title': reminder.title,
          'description': reminder.description,
          'jd': reminder.jd,
          'type': reminder.type,
          'category': reminder.category,
          'companyId': reminder.companyId,
          'remindAt': reminder.remindAt.toIso8601String(),
          'notifyBeforeMinutes': reminder.notifyBefore.inMinutes,
          'deviceId': deviceId,
        });
        resData = res.data;
      }
      final created = ReminderModel.fromJson(resData as Map<String, dynamic>);
      // Fire-and-forget schedule/history so list refresh not blocked
      _schedule(created).catchError((_) {});
      await load();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateReminder(String id, ReminderModel updated, {Uint8List? fileBytes, String? fileName}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _notifications.cancel(id.hashCode & 0x7fffffff);
      ReminderModel toUpdate = updated;
      if (fileBytes != null && fileName != null) {
        final up = await _apiClient.uploadFile('${ApiEndpoints.reminders}/upload', fileBytes: fileBytes, fileName: fileName);
        final data = up.data as Map<String, dynamic>;
        toUpdate = updated.copyWith(fileKey: data['fileKey'] as String?, fileUrl: data['fileUrl'] as String?, fileName: fileName);
      }
      final res = await _apiClient.put('${ApiEndpoints.reminders}/$id', data: {
        'title': toUpdate.title,
        'description': toUpdate.description,
        'jd': toUpdate.jd,
        'type': toUpdate.type,
        'category': toUpdate.category,
        'companyId': toUpdate.companyId,
        'fileKey': toUpdate.fileKey,
        'fileUrl': toUpdate.fileUrl,
        'fileName': toUpdate.fileName,
        'remindAt': toUpdate.remindAt.toIso8601String(),
        'notifyBeforeMinutes': toUpdate.notifyBefore.inMinutes,
      });
      final rem = ReminderModel.fromJson(res.data as Map<String, dynamic>);
      _schedule(rem).catchError((_) {});
      await load();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteReminder(String id) async {
    try {
      await _notifications.cancel(id.hashCode & 0x7fffffff);
      await _apiClient.delete('${ApiEndpoints.reminders}/$id');
      await load();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> logHistory(String reminderId, String deviceId, {String status = 'SENT'}) async {
    try {
      await _apiClient.post('${ApiEndpoints.reminders}/$reminderId/history', data: {'deviceId': deviceId, 'status': status});
    } catch (_) {}
  }
}

final reminderProvider = StateNotifierProvider<ReminderNotifier, ReminderState>((ref) {
  return ReminderNotifier(ref.read(apiClientProvider));
});
