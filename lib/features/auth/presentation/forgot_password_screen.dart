import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/theme/app_theme.dart';
import '../data/auth_repository.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _step = 0; // 0=phone, 1=otp, 2=new password
  bool _loading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .forgotPasswordWhatsApp(_phoneCtrl.text.trim());
      setState(() => _step = 1);
    } catch (e) {
      _showError(e.toString().contains('404')
          ? 'No account found with this phone number.'
          : e.toString().contains('inactive')
              ? 'Your account is inactive. Contact your gym.'
              : 'Failed to send OTP via WhatsApp. Try again.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpCtrl.text.trim().length < 6) {
      _showError('Enter the 6-digit code sent to your WhatsApp');
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).verifyResetOtp(
            _phoneCtrl.text.trim(),
            _otpCtrl.text.trim(),
          );
      setState(() => _step = 2);
    } catch (e) {
      _showError('Invalid or expired code. Please try again.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      _showError('Passwords do not match.');
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).resetPassword(
            _phoneCtrl.text.trim(),
            _otpCtrl.text.trim(),
            _newPassCtrl.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/auth/login');
      }
    } catch (e) {
      _showError('Could not reset password. Please start over.');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => _step > 0
              ? setState(() => _step--)
              : context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StepIndicator(current: _step),
                const SizedBox(height: 32),

                // ── Step 0: Phone number ─────────────────────────────────
                if (_step == 0) ...[
                  Text('Forgot your password?',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your registered phone number and we\'ll send a reset code via WhatsApp.',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    autocorrect: false,
                    validator: Validators.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '9XXXXXXXXX',
                      prefixIcon:
                          Icon(Icons.phone_outlined, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading ? null : _sendOtp,
                    child: _loading
                        ? const _Spinner()
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.send, size: 18),
                              SizedBox(width: 8),
                              Text('Send Code via WhatsApp'),
                            ],
                          ),
                  ),
                ],

                // ── Step 1: OTP ──────────────────────────────────────────
                if (_step == 1) ...[
                  Text('Enter the code',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 14, height: 1.5),
                      children: [
                        const TextSpan(
                            text: 'A 6-digit code was sent to your WhatsApp '),
                        TextSpan(
                          text: _phoneCtrl.text,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  // WhatsApp badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFF25D366).withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            color: Color(0xFF25D366), size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Check your WhatsApp for the 6-digit code.',
                            style: TextStyle(
                                color: Color(0xFF25D366), fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _otpCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: const TextStyle(
                        fontSize: 22,
                        letterSpacing: 8,
                        fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      labelText: 'OTP Code',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading ? null : _verifyOtp,
                    child: _loading
                        ? const _Spinner()
                        : const Text('Verify Code'),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: _loading ? null : _sendOtp,
                      child: const Text(
                        'Resend Code',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ],

                // ── Step 2: New password ─────────────────────────────────
                if (_step == 2) ...[
                  Text('Set new password',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose a strong password with at least 8 characters.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _newPassCtrl,
                    obscureText: _obscureNew,
                    validator: Validators.password,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock_outline,
                          color: AppColors.textSecondary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNew
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () =>
                            setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPassCtrl,
                    obscureText: _obscureConfirm,
                    validator: (v) =>
                        v != _newPassCtrl.text ? 'Passwords do not match' : null,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock_outline,
                          color: AppColors.textSecondary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading ? null : _resetPassword,
                    child: _loading
                        ? const _Spinner()
                        : const Text('Reset Password'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int current;
  const _StepIndicator({required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final done = i < current;
        final active = i == current;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
            decoration: BoxDecoration(
              color: done
                  ? AppColors.primary
                  : active
                      ? AppColors.primary.withOpacity(0.6)
                      : AppColors.cardBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(
          strokeWidth: 2, color: AppColors.darkBg),
    );
  }
}
