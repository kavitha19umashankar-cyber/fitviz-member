import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../flavors/flavor_config.dart';
import '../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';
import '../../../core/providers/session_provider.dart';
import '../../../shared/fitviz_v2/theme/fitviz_v2_colors.dart';
import '../../../shared/fitviz_v2/theme/fitviz_v2_typography.dart';
import '../../../shared/fitviz_v2/icons/fitviz_v2_icon.dart';
import '../../../shared/fitviz_v2/icons/fitviz_v2_icons.dart';
import '../../../shared/fitviz_v2/widgets/v2_underline_field.dart';
import '../../../shared/fitviz_v2/widgets/v2_pill_button.dart';

/// FitViz v2 Login — angled gradient hero panel overlapped by a rounded
/// sheet; bottom action is a labeled row + circular arrow button, not a
/// full-width pill. Preserves the biometric-unlock flow from the legacy
/// screen (not depicted in the mockup, but a real active feature).
class LoginScreenV2 extends ConsumerStatefulWidget {
  const LoginScreenV2({super.key});

  @override
  ConsumerState<LoginScreenV2> createState() => _LoginScreenV2State();
}

class _LoginScreenV2State extends ConsumerState<LoginScreenV2> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;

  @override
  void initState() {
    super.initState();
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
    await ref.read(authProvider.notifier).login(_phoneCtrl.text.trim(), _passCtrl.text);
  }

  Future<void> _triggerBiometric() async {
    await ref.read(authProvider.notifier).loginWithBiometric();
  }

  Future<void> _callSupport(String phone) async {
    await launchUrl(Uri(scheme: 'tel', path: phone));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final biometricPending = ref.watch(biometricPendingProvider);

    ref.listen(authProvider, (_, next) {
      next.maybeWhen(
        error: (message) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: FitVizV2Colors.danger),
        ),
        orElse: () {},
      );
    });

    final isLoading = authState.maybeWhen(loading: () => true, orElse: () => false);
    final config = FlavorConfig.instance;

    return Scaffold(
      backgroundColor: FitVizV2Colors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Hero panel ──────────────────────────────────────────────
            Container(
              height: 224,
              width: double.infinity,
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment(0.6, 0.9),
                  colors: [Color(0xFF1B2410), FitVizV2Colors.bg],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -70,
                    right: -60,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [Color(0x4DC9FF4D), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(26, 54, 26, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(config.appName, style: FitVizV2Text.display(size: 30, color: FitVizV2Colors.accent)),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 220,
                          child: Text(
                            config.appTagline,
                            style: FitVizV2Text.body(size: 13, color: FitVizV2Colors.inkDim),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ── Overlapping sheet ───────────────────────────────────────
            Expanded(
              child: Transform.translate(
                offset: const Offset(0, -26),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                  decoration: const BoxDecoration(
                    color: FitVizV2Colors.surface,
                    border: Border(top: BorderSide(color: FitVizV2Colors.border)),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (biometricPending) ...[
                            _BiometricBlock(loading: isLoading, onTap: isLoading ? null : _triggerBiometric),
                            const SizedBox(height: 24),
                            Row(children: [
                              const Expanded(child: Divider(color: FitVizV2Colors.border)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text('or sign in with password',
                                    style: FitVizV2Text.caption(letterSpacing: 0)),
                              ),
                              const Expanded(child: Divider(color: FitVizV2Colors.border)),
                            ]),
                            const SizedBox(height: 20),
                          ] else ...[
                            Text('Sign in to your account', style: FitVizV2Text.h1()),
                            const SizedBox(height: 4),
                            Text('Enter your phone number and password to continue.',
                                style: FitVizV2Text.body(size: 13, color: FitVizV2Colors.inkDim)),
                            const SizedBox(height: 18),
                          ],
                          V2UnderlineField(
                            controller: _phoneCtrl,
                            placeholder: 'Phone number',
                            leadingIcon: FitVizV2Icon.phone,
                            keyboardType: TextInputType.phone,
                            validator: Validators.phone,
                          ),
                          const SizedBox(height: 4),
                          V2UnderlineField(
                            controller: _passCtrl,
                            placeholder: 'Password',
                            leadingIcon: FitVizV2Icon.lock,
                            obscureText: _obscurePass,
                            validator: Validators.password,
                            onFieldSubmitted: (_) => _submit(),
                            trailing: GestureDetector(
                              onTap: () => setState(() => _obscurePass = !_obscurePass),
                              child: FitVizV2IconView(FitVizV2Icon.eye, size: 18, color: FitVizV2Colors.inkDim),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () => context.push('/auth/forgot-password'),
                              child: Text('Forgot password?',
                                  style: FitVizV2Text.body(
                                      size: 12, weight: FontWeight.w600, color: FitVizV2Colors.accent)),
                            ),
                          ),
                          const SizedBox(height: 36),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Ready to train?',
                                        style: FitVizV2Text.body(size: 14, weight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text('Pick up your streak right where you left it.',
                                        style: FitVizV2Text.body(size: 11, color: FitVizV2Colors.inkDim)),
                                  ],
                                ),
                              ),
                              V2CircularActionButton(
                                onTap: isLoading ? null : _submit,
                                icon: isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2, color: FitVizV2Colors.accentInk),
                                      )
                                    : FitVizV2IconView(FitVizV2Icon.chevron,
                                        size: 20, color: FitVizV2Colors.accentInk),
                              ),
                            ],
                          ),
                          if (config.contactPhone != null) ...[
                            const SizedBox(height: 20),
                            Center(
                              child: GestureDetector(
                                onTap: () => _callSupport(config.contactPhone!),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FitVizV2IconView(FitVizV2Icon.phone, size: 14, color: FitVizV2Colors.inkDim),
                                    const SizedBox(width: 6),
                                    Text('Need help? Call ${config.contactPhone}',
                                        style: FitVizV2Text.body(size: 12, color: FitVizV2Colors.inkDim)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BiometricBlock extends StatelessWidget {
  final bool loading;
  final VoidCallback? onTap;
  const _BiometricBlock({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text('Welcome back!', style: FitVizV2Text.h1()),
          const SizedBox(height: 8),
          Text('Use biometric to unlock the app',
              style: FitVizV2Text.body(size: 14, color: FitVizV2Colors.inkDim)),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0x1FC9FF4D),
                border: Border.all(color: FitVizV2Colors.accent, width: 2),
              ),
              child: loading
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(strokeWidth: 2, color: FitVizV2Colors.accent),
                    )
                  : Center(child: FitVizV2IconView(FitVizV2Icon.finger, size: 34, color: FitVizV2Colors.accent)),
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onTap,
            child: Text('Tap to authenticate',
                style: FitVizV2Text.body(size: 13, weight: FontWeight.w600, color: FitVizV2Colors.accent)),
          ),
        ],
      ),
    );
  }
}
