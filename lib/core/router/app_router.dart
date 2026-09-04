import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/community/chat_screen.dart';
import '../../features/ai/ai_assistant_tab.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/companies/add_company_screen.dart';
import '../../features/companies/companies_screen.dart';
import '../../features/companies/company_detail_screen.dart';
import '../../features/documents/upload_document_screen.dart';
import '../../features/documents/document_type_screen.dart';
import '../../features/documents/document_preview_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/jobswitch/jobswitch_screen.dart';
import '../../features/applock/app_lock_screen.dart';
import '../../features/applock/unlock_screen.dart';
import '../../features/profile/profile_edit_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/todo/goals_screen.dart';
import '../../features/todo/todos_screen.dart';
import '../../shared/widgets/main_shell.dart';
import '../storage/secure_storage.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final secureStorage = ref.read(secureStorageProvider);
  return AppRouter(secureStorage).router;
});

class AppRouter {
  final SecureStorage _secureStorage;

  AppRouter(this._secureStorage);

  late final GoRouter router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: _AuthNotifier(_secureStorage),
    redirect: (context, state) async {
      final isLoggedIn = await _secureStorage.getToken() != null;
      final isOnboardingSeen = await _secureStorage.hasSeenOnboarding();
      final hasPin = await _secureStorage.hasPin();
      final path = state.uri.path;

      if (path == '/splash') return null;
      if (path == '/lock') return null;
      if (!isOnboardingSeen) {
        if (path != '/onboarding') return '/onboarding';
        return null;
      }
      if (!isLoggedIn && path != '/auth') return '/auth';
      if (isLoggedIn && path == '/auth') {
        if (hasPin) return '/lock';
        return '/';
      }
      if (isLoggedIn && hasPin && path != '/lock' && path != '/app-lock' && !path.startsWith('/lock')) {
        return '/lock';
      }
      if (isLoggedIn && !hasPin && path == '/lock') return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => OnboardingScreen()),
      GoRoute(path: '/auth', builder: (_, __) => AuthScreen()),
      GoRoute(path: '/lock', builder: (_, __) => const UnlockScreen()),
      GoRoute(
        path: '/',
        builder: (_, __) => MainShell(),
        routes: [
          GoRoute(
            path: 'companies',
            builder: (_, __) => const CompaniesScreen(),
          ),
          GoRoute(
            path: 'companies/add',
            builder: (_, __) => AddCompanyScreen(),
          ),
          GoRoute(
            path: 'companies/:id',
            builder: (_, state) => CompanyDetailScreen(
              companyId: state.pathParameters['id']!,
            ),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (_, state) => AddCompanyScreen(
                  companyId: state.pathParameters['id'],
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'documents/upload',
            builder: (_, __) => UploadDocumentScreen(),
          ),
          GoRoute(
            path: 'documents/types',
            builder: (_, __) => DocumentTypeScreen(),
          ),
          GoRoute(
            path: 'documents/preview/:id',
            builder: (_, state) => DocumentPreviewScreen(
              documentId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(path: 'search', builder: (_, __) => SearchScreen()),
          GoRoute(
            path: 'job-switch-pack',
            builder: (_, __) => JobSwitchScreen(),
          ),
          GoRoute(path: 'app-lock', builder: (_, __) => AppLockScreen()),
          GoRoute(
            path: 'profile/edit',
            builder: (_, __) => const ProfileEditScreen(),
          ),
          GoRoute(
            path: 'todos',
            builder: (_, __) => const TodosScreen(),
          ),
          GoRoute(
            path: 'goals',
            builder: (_, __) => const GoalsScreen(),
          ),
          GoRoute(
            path: 'profile',
            builder: (_, __) => const ProfileScreen(),
          ),
          GoRoute(
            path: 'chat/:id',
            builder: (_, state) => ChatScreen(
              conversationId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: 'ai',
            builder: (_, __) => Scaffold(
              appBar: AppBar(
                title: const Text('AI Assistant'),
                centerTitle: false,
              ),
              body: const AIAssistantTab(),
            ),
          ),
        ],
      ),
    ],
  );
}

class _AuthNotifier extends ChangeNotifier {
  final SecureStorage _secureStorage;
  _AuthNotifier(this._secureStorage);
}
