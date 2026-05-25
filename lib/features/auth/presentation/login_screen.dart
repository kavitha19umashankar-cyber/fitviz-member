import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../flavors/flavor_config.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/providers/session_provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;

  @override
  void initState() {
    super.initState();
    // Auto-trigger biometric prompt if a session is pending biometric unlock.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(biometricPendingProvider)) {
        _triggerBiometric();
      }
    });
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authProvider.notifier)
        .login(_phoneCtrl.text.trim(), _passCtrl.text);
  }

  Future<void> _triggerBiometric() async {
    await ref.read(authProvider.notifier).loginWithBiometric();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final biometricPending = ref.watch(biometricPendingProvider);

    ref.listen(authProvider, (_, next) {
      next.maybeWhen(
        error: (message) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.error),
        ),
        orElse: () {},
      );
    });

    final isLoading =
        authState.maybeWhen(loading: () => true, orElse: () => false);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                // Logo / brand
                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        FlavorConfig.instance.logoAssetPath,
                        height: 180,
                        width: 180,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        FlavorConfig.instance.appName,
                        style: Theme.of(context).textTheme.headlineLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),

                // ── Biometric unlock section ────────────────────────────────
                if (biometricPending) ...[
                  Center(
                    child: Column(
                      children: [
                        Text('Welcome back!',
                            style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 8),
                        Text(
                          'Use biometric to unlock the app',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 14),
                        ),
                        const SizedBox(height: 32),
                        GestureDetector(
                          onTap: isLoading ? null : _triggerBiometric,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.primary, width: 2),
                            ),
                            child: isLoading
                                ? const Padding(
                                    padding: EdgeInsets.all(24),
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : Icon(Icons.fingerprint,
                                    size: 44, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: isLoading ? null : _triggerBiometric,
                          child: const Text('Tap to authenticate'),
                        ),
                        const SizedBox(height: 32),
                        const Row(children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('or sign in with password',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12)),
                          ),
                          Expanded(child: Divider()),
                        ]),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ] else ...[
                  Text('Welcome',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text('Sign in to continue your fitness journey',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 36),
                ],

                // ── Password login form ─────────────────────────────────────
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  validator: Validators.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined,
                        color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: Validators.password,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: AppColors.textSecondary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/auth/forgot-password'),
                    child: Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.darkBg,
                          ),
                        )
                      : const Text('Sign In'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
