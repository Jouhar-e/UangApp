import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:uangapp/services/theme_service.dart';
import 'package:uangapp/features/auth/bloc/auth_bloc.dart';
import 'package:uangapp/features/auth/presentation/login_screen.dart';
import 'package:uangapp/features/insights/bloc/insights_bloc.dart';
import 'package:uangapp/features/transactions/bloc/transaction_bloc.dart';
import 'package:uangapp/core/widgets/splash_screen.dart';
import 'package:uangapp/features/shell/main_shell.dart';
import 'package:uangapp/services/cache_service.dart';
import 'package:uangapp/services/connectivity_service.dart';
import 'package:uangapp/services/ai_service.dart';
import 'package:uangapp/services/google_auth_service.dart';
import 'package:uangapp/services/google_sheets_service.dart';
import 'package:uangapp/services/profile_service.dart';
import 'package:uangapp/services/sync_queue_service.dart';

const _kSplashMinDuration = Duration(milliseconds: 2500);

class UangApp extends StatefulWidget {
  const UangApp({
    super.key,
    required this.aiService,
    required this.authService,
    required this.themeService,
  });

  final AiService aiService;
  final GoogleAuthService authService;
  final ThemeService themeService;

  @override
  State<UangApp> createState() => _UangAppState();
}

class _UangAppState extends State<UangApp> {
  late final GoogleAuthService _authService;
  late final AuthenticatedApiRunner _apiRunner;
  late final GoogleSheetsService _sheetsService;
  late final CacheService _cacheService;
  late final SyncQueueService _syncQueueService;
  late final ConnectivityService _connectivityService;
  late final AiService _aiService;
  late final ProfileService _profileService;
  late final ThemeService _themeService;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService;
    _apiRunner = AuthenticatedApiRunner(_authService);
    _sheetsService = GoogleSheetsService(_apiRunner);
    _cacheService = CacheService();
    _syncQueueService = SyncQueueService();
    _connectivityService = ConnectivityService();
    _aiService = widget.aiService;
    _profileService = ProfileService();
    _themeService = widget.themeService;
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _authService),
        RepositoryProvider.value(value: _sheetsService),
        RepositoryProvider.value(value: _cacheService),
        RepositoryProvider.value(value: _syncQueueService),
        RepositoryProvider.value(value: _connectivityService),
        RepositoryProvider.value(value: _aiService),
      ],
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: _profileService),
          ChangeNotifierProvider.value(value: _themeService),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => AuthBloc(_authService)..add(const AuthStarted()),
            ),
            BlocProvider(
              create: (_) => TransactionBloc(
                sheetsService: _sheetsService,
                cacheService: _cacheService,
                syncQueueService: _syncQueueService,
                connectivityService: _connectivityService,
                aiService: _aiService,
              ),
            ),
            BlocProvider(
              create: (_) => InsightsBloc(
                aiService: _aiService,
                sheetsService: _sheetsService,
                cacheService: _cacheService,
              ),
            ),
          ],
          child: ListenableBuilder(
            listenable: _themeService,
            builder: (context, _) {
              return MaterialApp(
                title: 'UangApp',
                theme: _themeService.themeData,
                home: const _RootRouter(),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RootRouter extends StatefulWidget {
  const _RootRouter();

  @override
  State<_RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<_RootRouter> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _listenConnectivity();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
      _holdSplash();
    });
  }

  Future<void> _holdSplash() async {
    await Future<void>.delayed(_kSplashMinDuration);
    if (!mounted) return;
    setState(() => _showSplash = false);
  }

  void _listenConnectivity() {
    final connectivity = context.read<ConnectivityService>();
    connectivity.onConnectivityChanged.listen((online) {
      if (!mounted) return;
      context
          .read<TransactionBloc>()
          .add(TransactionsConnectivityChanged(online));
    });
  }

  bool _shouldShowSplash(AuthState state) =>
      _showSplash ||
      state.status == AuthStatus.unknown ||
      state.status == AuthStatus.loading;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (p, c) => p.status != c.status,
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          final tx = context.read<TransactionBloc>();
          if (tx.state.transactions.isEmpty) {
            tx.add(const TransactionsLoadRequested(silent: true));
          }
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (_shouldShowSplash(state)) {
            return const SplashScreen();
          }

          switch (state.status) {
            case AuthStatus.authenticated:
              return const MainShell();
            case AuthStatus.unauthenticated:
            case AuthStatus.failure:
              return const LoginScreen();
            case AuthStatus.unknown:
            case AuthStatus.loading:
              return const SplashScreen();
          }
        },
      ),
    );
  }
}
