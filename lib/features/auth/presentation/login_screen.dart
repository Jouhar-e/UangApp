import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uangapp/core/theme/app_palette.dart';
import 'package:uangapp/core/utils/app_messenger.dart';
import 'package:uangapp/core/widgets/app_brand_icon.dart';
import 'package:uangapp/core/widgets/double_back_to_exit.dart';
import 'package:uangapp/features/auth/bloc/auth_bloc.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DoubleBackToExit(
      isHome: true,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: BlocConsumer<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state.status == AuthStatus.failure &&
                    state.errorMessage != null) {
                  showAppSnackBar(context, state.errorMessage!);
                }
              },
              builder: (context, state) {
                final loading = state.status == AuthStatus.loading;
                final palette = context.palette;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: AppBrandIcon(size: 96)),
                    const SizedBox(height: 24),
                    Text(
                      'UangApp',
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: palette.charcoal,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pelacak keuangan real-time dengan Google Sheets',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: palette.sage,
                          ),
                    ),
                    const SizedBox(height: 48),
                    FilledButton.icon(
                      onPressed: loading
                          ? null
                          : () => context
                              .read<AuthBloc>()
                              .add(const AuthSignInRequested()),
                      icon: loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login),
                      label:
                          Text(loading ? 'Memuat...' : 'Masuk dengan Google'),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Memerlukan akses Google Sheets & Drive untuk menyimpan transaksi Anda.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: palette.sage,
                          ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
