import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../auth/auth_provider.dart';
import '../storage/storage_quota_provider.dart';
import 'models/document_model.dart';

class DocumentsState {
  final bool isLoading;
  final String? error;
  final List<DocumentModel> documents;
  final String? deletingId;

  const DocumentsState({
    this.isLoading = false,
    this.error,
    this.documents = const [],
    this.deletingId,
  });

  DocumentsState copyWith({
    bool? isLoading,
    String? error,
    List<DocumentModel>? documents,
    String? deletingId,
  }) {
    return DocumentsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      documents: documents ?? this.documents,
      deletingId: deletingId,
    );
  }
}

class DocumentsNotifier extends StateNotifier<DocumentsState> {
  final ApiClient _apiClient;
  final Ref _ref;

  DocumentsNotifier(this._apiClient, this._ref) : super(const DocumentsState());

  void _refreshQuota() {
    try {
      _ref.read(storageQuotaProvider.notifier).load();
    } catch (_) {}
  }

  Future<void> loadDocuments({String? companyId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final queryParams = <String, dynamic>{};
      if (companyId != null) queryParams['companyId'] = companyId;
      final response = await _apiClient.get(
        ApiEndpoints.documents,
        queryParameters: queryParams,
      );
      final documents = parseDocumentList(response.data);
      state = DocumentsState(documents: documents);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load documents',
      );
    }
  }

  Future<bool> uploadDocument(DocumentUploadRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiClient.uploadFile(
        ApiEndpoints.documentUpload,
        fileBytes: request.fileBytes,
        fileName: request.fileName,
        fileField: 'file',
        extraData: request.toFormFields(),
      );
      await loadDocuments(companyId: request.companyId);
      _refreshQuota();
      return true;
    } catch (e) {
      var msg = 'Failed to upload document';
      if (e is DioException && e.response?.data is Map) {
        msg = (e.response!.data as Map)['error'] as String? ?? msg;
      } else if (e is DioException) {
        msg = e.message ?? msg;
      }
      state = state.copyWith(
        isLoading: false,
        error: msg,
      );
      return false;
    }
  }

  Future<void> deleteDocument(String id) async {
    state = state.copyWith(deletingId: id);
    try {
      await _apiClient.delete('${ApiEndpoints.documents}/$id');
      state = state.copyWith(
        documents: state.documents.where((d) => d.id != id).toList(),
        deletingId: null,
      );
      _refreshQuota();
    } catch (e) {
      state = state.copyWith(deletingId: null, error: 'Failed to delete document');
    }
  }
}

final documentsProvider =
    StateNotifierProvider<DocumentsNotifier, DocumentsState>((ref) {
  ref.watch(authProvider.select((s) => s.user?.id));
  return DocumentsNotifier(ref.read(apiClientProvider), ref);
});
