import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:uangapp/core/utils/expense_summary.dart';
import 'package:uangapp/models/transaction.dart';
import 'package:uangapp/services/budget_service.dart';
import 'package:uangapp/services/notification_settings_service.dart';

/// Notifikasi harian ringkasan pengeluaran (waktu bisa diatur di Profil).
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _dailyNotificationId = 1001;
  static const _channelId = 'uangapp_daily_summary';
  static const _channelName = 'Ringkasan harian';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final _settingsService = NotificationSettingsService();
  final _budgetService = BudgetService();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (e) {
      debugPrint('NotificationService timezone fallback: $e');
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      ),
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Pengingat pengeluaran harian dan anggaran',
      importance: Importance.defaultImportance,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  Future<bool> requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  Future<void> updateFromTransactions(List<Transaction> transactions) async {
    if (!_initialized) await initialize();

    final settings = await _settingsService.load();
    if (!settings.enabled) {
      await _plugin.cancel(id: _dailyNotificationId);
      return;
    }

    final summary = computeExpenseSummary(transactions);
    final budget = await _budgetService.loadMonthlyBudget();
    await _scheduleDaily(
      summary,
      settings: settings,
      transactions: transactions,
      monthlyBudget: budget,
    );
  }

  Future<void> reschedule() async {
    if (!_initialized) await initialize();
    await _plugin.cancel(id: _dailyNotificationId);
  }

  String _buildBody(
    ExpenseSummary summary,
    List<Transaction> transactions,
    double? monthlyBudget,
  ) {
    final buffer = StringBuffer(summary.notificationBody);
    if (monthlyBudget != null && monthlyBudget > 0) {
      final spent = _budgetService.monthExpense(transactions, DateTime.now());
      final currency =
          NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
      buffer.writeln();
      buffer.write(
        'Anggaran: ${currency.format(spent)} / ${currency.format(monthlyBudget)}',
      );
      if (spent > monthlyBudget) {
        buffer.write(' (melebihi ${currency.format(spent - monthlyBudget)})');
      }
    }
    return buffer.toString();
  }

  Future<void> _scheduleDaily(
    ExpenseSummary summary, {
    required NotificationSettings settings,
    required List<Transaction> transactions,
    double? monthlyBudget,
  }) async {
    await _plugin.cancel(id: _dailyNotificationId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      settings.hour,
      settings.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final body = _buildBody(summary, transactions, monthlyBudget);
    final title = monthlyBudget != null &&
            _budgetService.monthExpense(transactions, DateTime.now()) >
                monthlyBudget
        ? '⚠️ Anggaran terlampaui — ${summary.notificationTitle}'
        : summary.notificationTitle;

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Pengingat pengeluaran harian dan anggaran',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      styleInformation: BigTextStyleInformation(body),
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id: _dailyNotificationId,
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: title,
      body: body,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> showSummaryNow(ExpenseSummary summary) async {
    if (!_initialized) await initialize();

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Ringkasan pengeluaran',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      styleInformation: BigTextStyleInformation(summary.notificationBody),
    );

    await _plugin.show(
      id: 1002,
      title: summary.notificationTitle,
      body: summary.notificationBody,
      notificationDetails: NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}
