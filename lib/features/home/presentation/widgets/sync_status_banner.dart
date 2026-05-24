import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uangapp/core/theme/app_palette.dart';

class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({
    super.key,
    required this.isOnline,
    required this.pendingSyncCount,
    this.lastSyncAt,
    this.infoMessage,
    this.conflictsResolved = 0,
  });

  final bool isOnline;
  final int pendingSyncCount;
  final DateTime? lastSyncAt;
  final String? infoMessage;
  final int conflictsResolved;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    if (!isOnline) {
      return _Banner(
        color: Colors.orange.shade50,
        icon: Icons.cloud_off,
        iconColor: Colors.orange.shade800,
        text: 'Offline — perubahan disimpan di perangkat',
      );
    }

    if (infoMessage != null && infoMessage!.isNotEmpty) {
      return _Banner(
        color: palette.mintLight,
        icon: Icons.info_outline,
        iconColor: palette.forest,
        text: infoMessage!,
      );
    }

    if (pendingSyncCount > 0) {
      return _Banner(
        color: Colors.orange.shade50,
        icon: Icons.sync,
        iconColor: Colors.orange.shade800,
        text: '$pendingSyncCount perubahan menunggu sinkron ke Google Sheet',
      );
    }

    if (conflictsResolved > 0) {
      return _Banner(
        color: palette.mintLight,
        icon: Icons.merge_type,
        iconColor: palette.forest,
        text:
            'Sinkron terakhir: $conflictsResolved perbedaan digabung (versi terbaru)',
      );
    }

    if (lastSyncAt != null) {
      final label = DateFormat('d MMM, HH:mm', 'id_ID').format(lastSyncAt!);
      return _Banner(
        color: palette.mintLight.withValues(alpha: 0.5),
        icon: Icons.cloud_done_outlined,
        iconColor: palette.sage,
        text: 'Sinkron terakhir: $label',
      );
    }

    return const SizedBox.shrink();
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  final Color color;
  final IconData icon;
  final Color iconColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
