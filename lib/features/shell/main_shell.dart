import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uangapp/core/theme/app_palette.dart';
import 'package:uangapp/core/utils/expense_summary.dart';
import 'package:uangapp/core/utils/open_google_sheet.dart';
import 'package:uangapp/core/widgets/app_logo.dart';
import 'package:uangapp/core/widgets/double_back_to_exit.dart';
import 'package:uangapp/features/auth/bloc/auth_bloc.dart';
import 'package:uangapp/features/home/presentation/beranda_tab.dart';
import 'package:uangapp/features/insights/presentation/insights_screen.dart';
import 'package:uangapp/features/notifications/presentation/notifications_summary_sheet.dart';
import 'package:uangapp/features/profile/presentation/profile_tab.dart';
import 'package:uangapp/features/transactions/bloc/transaction_bloc.dart';
import 'package:uangapp/models/transaction.dart';
import 'package:uangapp/features/transactions/presentation/add_transaction_sheet.dart';
import 'package:uangapp/features/transactions/presentation/transactions_tab.dart';
import 'package:uangapp/services/google_auth_service.dart';
import 'package:uangapp/services/notification_service.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _index = 0;
  bool _notificationsReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupNotifications();
      _autoSync();
      context.read<GoogleAuthService>().warmUp();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _autoSync();
    }
  }

  void _autoSync() {
    if (!mounted) return;
    // Hanya muat cache — tanpa dialog Google saat buka / kembali ke app.
    context.read<TransactionBloc>().add(
          const TransactionsLoadRequested(silent: true),
        );
  }

  Future<void> _setupNotifications() async {
    if (_notificationsReady) return;
    try {
      await NotificationService.instance.initialize();
      await NotificationService.instance.requestPermission();
    } catch (_) {
      return;
    }
    if (!mounted) return;
    setState(() => _notificationsReady = true);
    _syncNotifications(context.read<TransactionBloc>().state.transactions);
  }

  void _syncNotifications(List<Transaction> transactions) {
    if (!_notificationsReady) return;
    NotificationService.instance.updateFromTransactions(transactions);
  }

  void _openAddTransaction() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<TransactionBloc>(),
        child: const AddTransactionSheet(),
      ),
    );
  }

  void _goToTransactions() => setState(() => _index = 1);

  void _openNotificationsSummary(List<Transaction> transactions) {
    final summary = computeExpenseSummary(transactions);
    showNotificationsSummarySheet(context, summary);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return BlocListener<TransactionBloc, TransactionState>(
      listenWhen: (prev, curr) => prev.transactions != curr.transactions,
      listener: (context, state) => _syncNotifications(state.transactions),
      child: DoubleBackToExit(
        isHome: _index == 0,
        onBackToHome: () => setState(() => _index = 0),
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const AppLogo(size: 30),
            centerTitle: true,
            actions: [
              BlocBuilder<TransactionBloc, TransactionState>(
                builder: (context, state) {
                  return IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    tooltip: 'Ringkasan pengeluaran',
                    onPressed: () =>
                        _openNotificationsSummary(state.transactions),
                  );
                },
              ),
              PopupMenuButton<String>(
                tooltip: 'Menu lainnya',
                onSelected: (value) {
                  switch (value) {
                    case 'sync':
                      context.read<TransactionBloc>().add(
                            const TransactionsLoadRequested(
                              syncWithGoogle: true,
                            ),
                          );
                      break;
                    case 'sheet':
                      openGoogleSpreadsheet(context);
                      break;
                    case 'logout':
                      context
                          .read<AuthBloc>()
                          .add(const AuthSignOutRequested());
                      break;
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'sync',
                    child: ListTile(
                      leading: Icon(Icons.sync),
                      title: Text('Sinkronkan data'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'sheet',
                    child: ListTile(
                      leading: Icon(Icons.table_chart_outlined),
                      title: Text('Buka Google Sheet'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'logout',
                    child: ListTile(
                      leading: Icon(Icons.logout, color: Color(0xFFC62828)),
                      title: Text(
                        'Keluar akun',
                        style: TextStyle(color: Color(0xFFC62828)),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: IndexedStack(
            index: _index,
            children: [
              BerandaTab(
                onSeeAllTransactions: _goToTransactions,
                onOpenAccountTab: () => setState(() => _index = 3),
              ),
              const TransactionsTab(),
              const InsightsScreen(embedded: true),
              const ProfileTab(),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _openAddTransaction,
            tooltip: 'Tambah transaksi',
            elevation: 6,
            highlightElevation: 8,
            shape: const CircleBorder(),
            child: const Icon(Icons.add_rounded, size: 30),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: SafeArea(
            top: false,
            child: BottomAppBar(
              color: Colors.white,
              elevation: 12,
              shadowColor: Colors.black26,
              shape: const CircularNotchedRectangle(),
              notchMargin: 8,
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Beranda',
                  selected: _index == 0,
                  onTap: () => setState(() => _index = 0),
                  palette: palette,
                ),
                _NavItem(
                  icon: Icons.receipt_long_rounded,
                  label: 'Transaksi',
                  selected: _index == 1,
                  onTap: () => setState(() => _index = 1),
                  palette: palette,
                ),
                const SizedBox(width: 48),
                _NavItem(
                  icon: Icons.assessment_rounded,
                  label: 'Laporan',
                  selected: _index == 2,
                  onTap: () => setState(() => _index = 2),
                  palette: palette,
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Akun',
                  selected: _index == 3,
                  onTap: () => setState(() => _index = 3),
                  palette: palette,
                ),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.palette,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final color = selected ? palette.forest : palette.sage;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
