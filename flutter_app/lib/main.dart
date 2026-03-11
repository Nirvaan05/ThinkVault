import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import 'core/api_client.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/home/dashboard_screen.dart';
import 'features/notes/notes_provider.dart';
import 'features/notes/notes_list_screen.dart';
import 'features/notes/note_detail_screen.dart';
import 'features/notes/note_editor_screen.dart';
import 'features/notes/attachments_provider.dart';
import 'features/notes/sync_service.dart';
import 'features/organization/categories_screen.dart';
import 'features/organization/tags_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/help/help_screen.dart';
import 'features/admin/admin_dashboard_screen.dart';
import 'features/admin/admin_config_screen.dart';
import 'features/feedback/feedback_screen.dart';
import 'features/feedback/admin_feedback_screen.dart';

void main() {
  final apiClient = ApiClient();
  final notesProvider = NotesProvider(apiClient);
  final syncService = SyncService(apiClient, notesProvider);

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: apiClient),
        ChangeNotifierProvider(create: (_) => AuthProvider(apiClient)),
        ChangeNotifierProvider.value(value: notesProvider),
        ChangeNotifierProvider(create: (_) => AttachmentsProvider(apiClient)),
        Provider.value(value: syncService),
      ],
      child: ThinkVaultApp(syncService: syncService),
    ),
  );
}

class ThinkVaultApp extends StatefulWidget {
  final SyncService syncService;
  const ThinkVaultApp({super.key, required this.syncService});

  @override
  State<ThinkVaultApp> createState() => _ThinkVaultAppState();
}

class _ThinkVaultAppState extends State<ThinkVaultApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.syncService.syncDelta();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ThinkVault',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        // Dashboard is the new authenticated landing page
        '/home': (context) => const DashboardScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        // Notes
        '/notes': (context) => const NotesListScreen(),
        '/notes/editor': (context) => const NoteEditorScreen(),
        '/notes/detail': (context) => const NoteDetailScreen(),
        // Organization
        '/categories': (context) => const CategoriesScreen(),
        '/tags': (context) => const TagsScreen(),
        // Settings & Help
        '/settings': (context) => const SettingsScreen(),
        '/help': (context) => const HelpScreen(),
        // Feedback
        '/feedback': (context) => const FeedbackScreen(),
        // Logout
        '/logout': (context) {
          context.read<AuthProvider>().logout().then((_) {
            Navigator.of(context).pushReplacementNamed('/login');
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        },
        // Admin routes (admin role only — enforced by backend + UI guard)
        '/admin': (context) => const AdminDashboardScreen(),
        '/admin/config': (context) => const AdminConfigScreen(),
        '/admin/feedback': (context) => const AdminFeedbackScreen(),
      },
    );
  }
}
