import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kReleaseMode;

class ApiEndpoints {
  ApiEndpoints._();

  // Allow override via --dart-define=API_BASE_URL=https://...
  static const String _envUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_envUrl.isNotEmpty) return _envUrl;
    // Release APK/AAB (and web release) → Render backend
    if (kReleaseMode) {
      return 'https://office-buddy-backend.onrender.com/api/v1';
    }
    // Debug / Profile → local dev
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080/api/v1';
    }
    return 'http://localhost:8080/api/v1';
  }

  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh';
  static const String verifyEmail = '/auth/verify-email';
  static const String resendVerification = '/auth/resend-verification';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String userProfile = '/users/me';
  static const String changePassword = '/users/me/password';

  static const String companies = '/companies';
  static const String companyDetails = '/companies/';

  static const String documents = '/documents';
  static const String documentUpload = '/documents/upload';
  static const String documentPresignedUrl = '/documents/presigned-url/';
  static const String documentSearch = '/documents/search';

  static const String timeline = '/timeline';
  static const String timelineEvents = '/timeline/events';

  static const String jobSwitchGenerate = '/job-switch/generate';
  static const String jobSwitchStatus = '/job-switch/status/';
  static const String jobSwitchDownload = '/job-switch/download/';
  static const String jobSwitchPackDownloadDetails = '/job-switch/pack-download-details';
  static const String jobSwitchPackDownloadDetailsAll = '/job-switch/pack-download-details/all';

  static const String dashboardStats = '/dashboard/stats';

  static const String todos = '/todos';
  static const String goals = '/goals';
  static const String goalsDashboard = '/goals/dashboard';
  static const String aiChat = '/ai/chat';

  static const String userSearch = '/users/search';
  static const String friendRequests = '/community/requests';
  static const String friendRequestsIncoming = '/community/requests/incoming';
  static const String friendRequestsOutgoing = '/community/requests/outgoing';
  static const String conversations = '/community/conversations';
  static const String communityOnline = '/community/online';
  static const String communityHeartbeat = '/community/heartbeat';
  static const String communityFriends = '/community/friends';
  static const String communityUsers = '/community/users';
  static const String communityUserCompanies = '/community/users/';
}
