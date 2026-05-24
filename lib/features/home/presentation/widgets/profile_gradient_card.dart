import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uangapp/core/theme/app_palette.dart';
import 'package:uangapp/features/auth/bloc/auth_bloc.dart';
import 'package:uangapp/features/transactions/bloc/transaction_bloc.dart';
import 'package:uangapp/models/user_profile.dart';
import 'package:uangapp/services/profile_service.dart';

class ProfileGradientCard extends StatefulWidget {
  const ProfileGradientCard({super.key});

  @override
  State<ProfileGradientCard> createState() => _ProfileGradientCardState();
}

class _ProfileGradientCardState extends State<ProfileGradientCard> {
  UserProfile? _profile;
  ProfileService? _profileService;

  @override
  void initState() {
    super.initState();
    _profileService = context.read<ProfileService>();
    _profileService!.addListener(_onProfileChanged);
    _load();
  }

  @override
  void dispose() {
    _profileService?.removeListener(_onProfileChanged);
    super.dispose();
  }

  void _onProfileChanged() => _load();

  Future<void> _load() async {
    final p = await context.read<ProfileService>().loadProfile();
    if (mounted) setState(() => _profile = p);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final authEmail = context.watch<AuthBloc>().state.userEmail ?? '';
    final name = (_profile != null && _profile!.fullName.isNotEmpty)
        ? _profile!.fullName
        : (authEmail.isNotEmpty ? authEmail.split('@').first : 'Pengguna');
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final isOnline = context.watch<TransactionBloc>().state.isOnline;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [palette.forest, palette.sage],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: palette.forest.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.95),
            child: Text(
              initial,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: palette.forest,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, $name 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (authEmail.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    authEmail,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isOnline
                              ? Colors.lightGreenAccent
                              : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isOnline ? 'Online' : 'Offline',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            child: const Icon(Icons.person_outline, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
