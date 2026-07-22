import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/validators.dart';
import '../data/auth_repository.dart';
import '../../../shared/fitviz_v2/theme/fitviz_v2_colors.dart';
import '../../../shared/fitviz_v2/theme/fitviz_v2_typography.dart';
import '../../../shared/fitviz_v2/icons/fitviz_v2_icon.dart';
import '../../../shared/fitviz_v2/icons/fitviz_v2_icons.dart';
import '../../../shared/fitviz_v2/widgets/v2_underline_field.dart';
import '../../../shared/fitviz_v2/widgets/v2_pill_button.dart';
import '../../../shared/fitviz_v2/widgets/v2_step_indicator.dart';
import '../../../shared/fitviz_v2/widgets/v2_otp_cell_row.dart';
import '../../../shared/fitviz_v2/widgets/v2_inline_banner.dart';
import '../../../shared/fitviz_v2/widgets/v2_password_strength_meter.dart';

/// FitViz v2 password-reset flow — mirrors the legacy 3-step (_step 0/1/2)
/// pattern in one file: phone -> OTP -> new password, with a dot-and-line
/// stepper across all three.
class ForgotPasswordScreenV2 extends ConsumerStatefulWidget {
  const ForgotPasswordScreenV2({super.key});

  @override
  ConsumerState<ForgotPasswordScreenV2> createState() => _ForgotPasswordScreenV2State();
}

class _ForgotPasswordScreenV2State extends ConsumerState<ForgotPasswordScreenV2> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _step = 0;
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
      await ref.read(authRepositoryProvider).forgotPasswordWhatsApp(_phoneCtrl.text.trim());
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
      await ref.read(authRepositoryProvider).verifyResetOtp(_phoneCtrl.text.trim(), _otpCtrl.text.trim());
      setState(() => _step = 2);
    } catch (e) {
      _showError('Invalid or expired code. Please try again.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_newPassCtrl.text.length < 8) {
      _showError('Password must be at least 8 characters.');
      return;
    }
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      _showError('Passwords do not match.');
      return;
    }
    setState(() => _loading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .resetPassword(_phoneCtrl.text.trim(), _otpCtrl.text.trim(), _newPassCtrl.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset successfully!'), backgroundColor: FitVizV2Colors.success),
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
      SnackBar(content: Text(msg), backgroundColor: FitVizV2Colors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FitVizV2Colors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 26),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _step > 0 ? setState(() => _step--) : context.pop(),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: FitVizV2IconView(FitVizV2Icon.chevron, size: 18, color: FitVizV2Colors.ink),
                      ),
                    ),
                    Expanded(
                      child: Text('Reset Password',
                          textAlign: TextAlign.center, style: FitVizV2Text.body(size: 17, weight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 18),
                  ],
                ),
                const SizedBox(height: 8),
                V2StepIndicator(currentStep: _step),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_step == 0) _PhoneStep(icon: FitVizV2Icon.lock),
                        if (_step == 1) _OtpStep(phone: _phoneCtrl.text),
                        if (_step == 2) _PasswordStep(),
                        if (_step == 0) ...[
                  V2UnderlineField(
                    controller: _phoneCtrl,
                    placeholder: 'Phone number',
                    leadingIcon: FitVizV2Icon.phone,
                    keyboardType: TextInputType.phone,
                    validator: Validators.phone,
                  ),
                  const SizedBox(height: 24),
                  V2PillButton(
                    label: 'Send Code via WhatsApp',
                    loading: _loading,
                    onTap: _loading ? null : _sendOtp,
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: RichText(
                      text: TextSpan(
                        style: FitVizV2Text.body(size: 12, color: FitVizV2Colors.inkDim),
                        children: [
                          const TextSpan(text: 'Remembered it? '),
                          TextSpan(
                            text: 'Back to Sign In',
                            style: const TextStyle(color: FitVizV2Colors.accent, fontWeight: FontWeight.w600),
                            recognizer: (TapGestureRecognizer()..onTap = () => context.go('/auth/login')),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else if (_step == 1) ...[
                  V2InlineBanner(
                    text: 'Check your WhatsApp for the code',
                    icon: FitVizV2Icon.mail,
                    variant: V2BannerVariant.success,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 52,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        V2OtpCellRow(value: _otpCtrl.text),
                        Opacity(
                          opacity: 0,
                          child: TextField(
                            controller: _otpCtrl,
                            autofocus: true,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(counterText: '', border: InputBorder.none),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  V2PillButton(
                    label: 'Verify Code',
                    loading: _loading,
                    onTap: (_loading || _otpCtrl.text.trim().length < 6) ? null : _verifyOtp,
                    variant: _otpCtrl.text.trim().length < 6
                        ? V2PillButtonVariant.disabled
                        : V2PillButtonVariant.accent,
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: GestureDetector(
                      onTap: _loading ? null : _sendOtp,
                      child: Text('Resend Code', style: FitVizV2Text.body(size: 12, color: FitVizV2Colors.inkDim)),
                    ),
                  ),
                ] else ...[
                  V2UnderlineField(
                    controller: _newPassCtrl,
                    placeholder: 'New password',
                    leadingIcon: FitVizV2Icon.lock,
                    obscureText: _obscureNew,
                    validator: Validators.password,
                    trailing: GestureDetector(
                      onTap: () => setState(() => _obscureNew = !_obscureNew),
                      child: const FitVizV2IconView(FitVizV2Icon.eye, size: 18, color: FitVizV2Colors.inkDim),
                    ),
                  ),
                  const SizedBox(height: 4),
                  V2UnderlineField(
                    controller: _confirmPassCtrl,
                    placeholder: 'Confirm password',
                    leadingIcon: FitVizV2Icon.lock,
                    obscureText: _obscureConfirm,
                    trailing: GestureDetector(
                      onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      child: const FitVizV2IconView(FitVizV2Icon.eye, size: 18, color: FitVizV2Colors.inkDim),
                    ),
                  ),
                  const SizedBox(height: 12),
                  V2PasswordStrengthMeter(password: _newPassCtrl.text),
                  const SizedBox(height: 24),
                  V2PillButton(label: 'Reset Password', loading: _loading, onTap: _loading ? null : _resetPassword),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhoneStep extends StatelessWidget {
  final FitVizV2Icon icon;
  const _PhoneStep({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        _IconBadge(icon: icon),
        const SizedBox(height: 14),
        Text('Forgot your password?', textAlign: TextAlign.center, style: FitVizV2Text.h2()),
        const SizedBox(height: 6),
        Text(
          "Enter the phone number linked to your account and we'll send a reset code to your WhatsApp.",
          textAlign: TextAlign.center,
          style: FitVizV2Text.body(size: 13, color: FitVizV2Colors.inkDim),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _OtpStep extends StatelessWidget {
  final String phone;
  const _OtpStep({required this.phone});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        const _IconBadge(icon: FitVizV2Icon.mail),
        const SizedBox(height: 14),
        Text('Enter the code', textAlign: TextAlign.center, style: FitVizV2Text.h2()),
        const SizedBox(height: 6),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: FitVizV2Text.body(size: 13, color: FitVizV2Colors.inkDim),
            children: [
              const TextSpan(text: 'A 6-digit code was sent to your WhatsApp '),
              TextSpan(text: phone, style: const TextStyle(color: FitVizV2Colors.ink, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _PasswordStep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        const _IconBadge(icon: FitVizV2Icon.finger),
        const SizedBox(height: 14),
        Text('Set a new password', textAlign: TextAlign.center, style: FitVizV2Text.h2()),
        const SizedBox(height: 6),
        Text(
          'Choose a strong password with at least 8 characters.',
          textAlign: TextAlign.center,
          style: FitVizV2Text.body(size: 13, color: FitVizV2Colors.inkDim),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _IconBadge extends StatelessWidget {
  final FitVizV2Icon icon;
  const _IconBadge({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x1FC9FF4D)),
      child: Center(child: FitVizV2IconView(icon, size: 24, color: FitVizV2Colors.accent)),
    );
  }
}
