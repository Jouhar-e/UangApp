import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uangapp/core/theme/app_palette.dart';
import 'package:uangapp/core/utils/app_messenger.dart';
import 'package:uangapp/features/auth/bloc/auth_bloc.dart';
import 'package:uangapp/models/user_profile.dart';
import 'package:uangapp/core/utils/open_google_sheet.dart';
import 'package:uangapp/core/utils/amount_parser.dart';
import 'package:uangapp/services/budget_service.dart';
import 'package:uangapp/services/notification_settings_service.dart';
import 'package:uangapp/services/notification_service.dart';
import 'package:uangapp/services/profile_service.dart';
import 'package:uangapp/services/theme_service.dart';
import 'package:uangapp/features/transactions/bloc/transaction_bloc.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _jobCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _budgetCtrl;
  bool _loading = true;
  bool _saving = false;
  bool _notificationsEnabled = true;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 20, minute: 0);
  final _budgetService = BudgetService();
  final _notificationSettingsService = NotificationSettingsService();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _jobCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
    _budgetCtrl = TextEditingController();
    _nameCtrl.addListener(_onNameChanged);
    WidgetsBinding.instance.addObserver(this);
    _loadProfile();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameCtrl.removeListener(_onNameChanged);
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _jobCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reloadNotificationSettings();
    }
  }

  Future<void> _reloadNotificationSettings() async {
    final notif = await _notificationSettingsService.load();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = notif.enabled;
      _notificationTime = TimeOfDay(hour: notif.hour, minute: notif.minute);
    });
  }

  Future<void> _loadProfile() async {
    final profileService = context.read<ProfileService>();
    var profile = await profileService.loadProfile();

    if (!mounted) return;
    final googleEmail = context.read<AuthBloc>().state.userEmail ?? '';
    if (googleEmail.isNotEmpty) {
      profile = profile.copyWith(email: googleEmail);
    }
    _nameCtrl.text = profile.fullName;
    _emailCtrl.text = profile.email;
    _phoneCtrl.text = profile.phone;
    _jobCtrl.text = profile.occupation;
    _addressCtrl.text = profile.address;
    _notesCtrl.text = profile.notes;

    final budget = await _budgetService.loadMonthlyBudget();
    if (budget != null && budget > 0) {
      _budgetCtrl.text = budget.toStringAsFixed(0);
    }

    final notif = await _notificationSettingsService.load();
    _notificationsEnabled = notif.enabled;
    _notificationTime = TimeOfDay(hour: notif.hour, minute: notif.minute);

    setState(() => _loading = false);
  }

  Future<void> _pickNotificationTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
      helpText: 'Waktu notifikasi harian',
    );
    if (picked != null) {
      setState(() => _notificationTime = picked);
      await _persistNotificationSettings();
    }
  }

  NotificationSettings get _notificationSettings => NotificationSettings(
        enabled: _notificationsEnabled,
        hour: _notificationTime.hour,
        minute: _notificationTime.minute,
      );

  Future<void> _persistNotificationSettings() async {
    await _notificationSettingsService.save(_notificationSettings);
    if (!mounted) return;
    final txs = context.read<TransactionBloc>().state.transactions;
    await NotificationService.instance.updateFromTransactions(txs);
  }

  Future<void> _saveBudgetAndNotifications() async {
    final budgetRaw = _budgetCtrl.text.trim();
    if (budgetRaw.isEmpty) {
      await _budgetService.saveMonthlyBudget(null);
    } else {
      final amount = parseManualAmountInput(budgetRaw);
      if (amount == null || amount <= 0) {
        showAppSnackBar(context, 'Anggaran tidak valid');
        return;
      }
      await _budgetService.saveMonthlyBudget(amount);
    }

    await _notificationSettingsService.save(_notificationSettings);

    if (!mounted) return;
    final txs = context.read<TransactionBloc>().state.transactions;
    await NotificationService.instance.updateFromTransactions(txs);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final googleEmail = context.read<AuthBloc>().state.userEmail ?? '';
    final profile = UserProfile(
      fullName: _nameCtrl.text.trim(),
      email: googleEmail.isNotEmpty ? googleEmail : _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      occupation: _jobCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
    );

    await context.read<ProfileService>().saveProfile(profile);
    await _saveBudgetAndNotifications();
    if (!mounted) return;
    setState(() => _saving = false);
    showAppSnackBar(context, 'Pengaturan tersimpan');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final palette = context.palette;
    final themeService = context.read<ThemeService>();
    final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;

    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 96 + keyboardBottom),
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: palette.forestContainer,
            child: Text(
              _nameCtrl.text.isNotEmpty
                  ? _nameCtrl.text[0].toUpperCase()
                  : '?',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: palette.forest,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Akun Saya',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Email mengikuti akun Google dan tidak dapat diubah.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          Text(
            'Tema aplikasi',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ThemeOption(
                  label: 'Hijau',
                  palette: AppPalette.green,
                  selected: themeService.variant == AppThemeVariant.green,
                  onTap: () =>
                      themeService.setVariant(AppThemeVariant.green),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ThemeOption(
                  label: 'Pink',
                  palette: AppPalette.pink,
                  selected: themeService.variant == AppThemeVariant.pink,
                  onTap: () => themeService.setVariant(AppThemeVariant.pink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Keuangan & notifikasi',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _budgetCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Anggaran pengeluaran / bulan (IDR)',
              hintText: 'Contoh: 5000000',
              prefixIcon: Icon(Icons.savings_outlined),
              helperText: 'Kosongkan jika tidak memakai anggaran',
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Notifikasi harian'),
            subtitle: Text(
              _notificationsEnabled
                  ? 'Aktif pukul ${_notificationTime.format(context)}'
                  : 'Nonaktif',
            ),
            value: _notificationsEnabled,
            onChanged: (v) async {
              setState(() => _notificationsEnabled = v);
              await _persistNotificationSettings();
            },
          ),
          if (_notificationsEnabled)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: const Text('Waktu notifikasi'),
              subtitle: Text(_notificationTime.format(context)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickNotificationTime,
            ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nama lengkap',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailCtrl,
            readOnly: true,
            enableInteractiveSelection: true,
            decoration: const InputDecoration(
              labelText: 'Email (akun Google)',
              prefixIcon: Icon(Icons.email_outlined),
              helperText: 'Tidak dapat diubah',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'No. telepon',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _jobCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Pekerjaan / profesi',
              prefixIcon: Icon(Icons.work_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _addressCtrl,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Alamat',
              prefixIcon: Icon(Icons.home_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Catatan (opsional)',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => openGoogleSpreadsheet(context),
            icon: const Icon(Icons.table_chart_outlined),
            label: const Text('Buka Google Sheet'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(_saving ? 'Menyimpan...' : 'Simpan profil'),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              context.read<AuthBloc>().add(const AuthSignOutRequested());
            },
            icon: const Icon(Icons.logout, color: Color(0xFFC62828)),
            label: const Text(
              'Keluar akun',
              style: TextStyle(color: Color(0xFFC62828)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final AppPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? palette.mintLight : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? palette.forest : palette.sage,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: palette.mintLight,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Container(height: 10, color: palette.sage),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Container(height: 10, color: palette.forest),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: palette.charcoal,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: palette.charcoal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
