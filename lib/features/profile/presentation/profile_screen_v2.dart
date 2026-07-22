import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../flavors/flavor_config.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/data/models/auth_model.dart';
import '../../../core/providers/session_provider.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/utils/biometric_service.dart';
import '../../../core/utils/validators.dart';
import '../../feedback/data/feedback_repository.dart';
import '../../../shared/fitviz_v2/theme/fitviz_v2_colors.dart';
import '../../../shared/fitviz_v2/theme/fitviz_v2_typography.dart';
import '../../../shared/fitviz_v2/theme/fitviz_v2_metrics.dart';
import '../../../shared/fitviz_v2/icons/fitviz_v2_icon.dart';
import '../../../shared/fitviz_v2/icons/fitviz_v2_icons.dart';
import '../../../shared/fitviz_v2/widgets/v2_list_row.dart';
import '../../../shared/fitviz_v2/widgets/v2_pill_button.dart';
import '../../../shared/fitviz_v2/widgets/v2_underline_field.dart';

final _profileProviderV2 = FutureProvider<UserModel>((ref) {
  ref.watch(sessionVersionProvider);
  return ref.read(authRepositoryProvider).getProfile();
});

final _referralCodeProviderV2 = FutureProvider<String?>((ref) {
  ref.watch(sessionVersionProvider);
  return ref.read(feedbackRepositoryProvider).getReferralCode();
});

final _appVersionProviderV2 = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return 'v${info.version}';
});

/// FitViz v2 Profile — cover-style header with avatar overlap and accent
/// glow; account/security fields as grouped list rows, not stacked boxed
/// fields. Note: the "Why K2 Fitness Studio" entry is intentionally
/// omitted here (pre-existing cross-brand leak fix) — that content only
/// belongs in K2's legacy profile screen.
class ProfileScreenV2 extends ConsumerWidget {
  const ProfileScreenV2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(_profileProviderV2);

    return Scaffold(
      backgroundColor: FitVizV2Colors.bg,
      body: SafeArea(
        bottom: false,
        child: profileAsync.when(
          data: (user) => _ProfileContentV2(user: user),
          loading: () => const Center(
              child: CircularProgressIndicator(color: FitVizV2Colors.accent)),
          error: (e, _) => Center(
            child: Text('Error loading profile: $e',
                style: FitVizV2Text.body(color: FitVizV2Colors.inkDim)),
          ),
        ),
      ),
    );
  }
}

class _ProfileContentV2 extends ConsumerStatefulWidget {
  final UserModel user;
  const _ProfileContentV2({required this.user});

  @override
  ConsumerState<_ProfileContentV2> createState() => _ProfileContentV2State();
}

class _ProfileContentV2State extends ConsumerState<_ProfileContentV2> {
  bool _biometricEnabled = false;
  static const _kBiometric = 'biometric_enabled';

  @override
  void initState() {
    super.initState();
    _loadBiometric();
  }

  Future<void> _loadBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _biometricEnabled = prefs.getBool(_kBiometric) ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return ListView(
      padding: const EdgeInsets.only(top: 4, bottom: 110),
      children: [
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(FitVizV2Radius.lg)),
            gradient: RadialGradient(
              center: const Alignment(-0.6, -1),
              radius: 1.3,
              colors: [const Color(0x47C9FF4D), FitVizV2Colors.surface.withOpacity(0)],
            ),
            color: FitVizV2Colors.surface,
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -46),
          child: Column(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: FitVizV2Colors.surface2,
                  border: Border.all(color: FitVizV2Colors.bg, width: 3),
                  image: user.fullProfilePhotoUrl != null
                      ? DecorationImage(image: NetworkImage(user.fullProfilePhotoUrl!), fit: BoxFit.cover)
                      : null,
                ),
                child: user.fullProfilePhotoUrl == null
                    ? Center(
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                          style: FitVizV2Text.display(size: 26, color: FitVizV2Colors.accent),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 10),
              Text(user.name, style: FitVizV2Text.h2()),
              if (user.email != null) ...[
                const SizedBox(height: 2),
                Text(user.email!, style: FitVizV2Text.body(size: 12, color: FitVizV2Colors.inkDim)),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -36),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _V2SectionHeader('Account'),
              _card([
                if (user.membershipId != null)
                  V2ListRow(icon: FitVizV2Icon.briefcase, label: 'Member ID', value: '#${user.membershipId}'),
                V2ListRow(icon: FitVizV2Icon.user, label: 'Full Name', value: user.name),
                if (user.email != null)
                  V2ListRow(icon: FitVizV2Icon.mail, label: 'Email', value: user.email!),
                if (user.phone != null)
                  V2ListRow(icon: FitVizV2Icon.phone, label: 'Phone', value: user.phone!, showDivider: false),
              ]),
              const SizedBox(height: 20),
              const _V2SectionHeader('Security'),
              _card([
                _V2ToggleRow(
                  icon: FitVizV2Icon.finger,
                  label: 'Biometric Unlock',
                  value: _biometricEnabled,
                  onChanged: (v) async {
                    if (v) {
                      final available = await BiometricService.isAvailable();
                      if (!available) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Biometric authentication is not available on this device.')),
                          );
                        }
                        return;
                      }
                      final confirmed = await BiometricService.authenticate(
                        reason: 'Confirm your identity to enable biometric unlock',
                      );
                      if (!confirmed) return;
                    }
                    await BiometricService.setEnabled(v);
                    if (mounted) setState(() => _biometricEnabled = v);
                  },
                ),
                V2ListRow(
                  icon: FitVizV2Icon.lock,
                  label: 'Security',
                  value: 'Change Password',
                  trailing: const FitVizV2IconView(FitVizV2Icon.chevron, size: 16, color: FitVizV2Colors.inkDim),
                  onTap: () => _showChangePassword(context),
                  showDivider: false,
                ),
              ]),
              const SizedBox(height: 20),
              const _V2SectionHeader('Referrals'),
              ref.watch(_referralCodeProviderV2).when(
                    data: (code) => _card([
                      code != null
                          ? _ReferralRow(code: code)
                          : V2ListRow(
                              icon: FitVizV2Icon.doc,
                              label: 'Referrals',
                              value: 'Share Referral Code',
                              trailing: const FitVizV2IconView(FitVizV2Icon.chevron,
                                  size: 16, color: FitVizV2Colors.inkDim),
                              onTap: () => _shareReferral(null),
                              showDivider: false,
                            ),
                    ]),
                    loading: () => const SizedBox(height: 60),
                    error: (_, __) => _card([
                      V2ListRow(
                        icon: FitVizV2Icon.doc,
                        label: 'Referrals',
                        value: 'Share Referral Code',
                        trailing:
                            const FitVizV2IconView(FitVizV2Icon.chevron, size: 16, color: FitVizV2Colors.inkDim),
                        onTap: () => _shareReferral(null),
                        showDivider: false,
                      ),
                    ]),
                  ),
              const SizedBox(height: 20),
              const _V2SectionHeader('Notifications'),
              _card([
                V2ListRow(
                  icon: FitVizV2Icon.bell,
                  label: 'Notifications',
                  value: 'Notification Settings',
                  trailing: const FitVizV2IconView(FitVizV2Icon.chevron, size: 16, color: FitVizV2Colors.inkDim),
                  onTap: () => _showNotificationSettings(context),
                  showDivider: false,
                ),
              ]),
              const SizedBox(height: 20),
              const _V2SectionHeader('Achievements'),
              _card([
                V2ListRow(
                  icon: FitVizV2Icon.chart,
                  label: 'Achievements',
                  value: 'My Badges & Achievements',
                  trailing: const FitVizV2IconView(FitVizV2Icon.chevron, size: 16, color: FitVizV2Colors.inkDim),
                  onTap: () => context.push('/achievements'),
                  showDivider: false,
                ),
              ]),
              const SizedBox(height: 20),
              const _V2SectionHeader('Feedback'),
              _card([
                V2ListRow(
                  icon: FitVizV2Icon.smile,
                  label: 'Feedback',
                  value: 'Rate Your Experience',
                  trailing: const FitVizV2IconView(FitVizV2Icon.chevron, size: 16, color: FitVizV2Colors.inkDim),
                  onTap: () => context.push('/feedback'),
                  showDivider: false,
                ),
              ]),
              const SizedBox(height: 20),
              const _V2SectionHeader('Subscription'),
              _card([
                V2ListRow(
                  icon: FitVizV2Icon.doc,
                  label: 'Subscription',
                  value: 'My Subscription & Plans',
                  trailing: const FitVizV2IconView(FitVizV2Icon.chevron, size: 16, color: FitVizV2Colors.inkDim),
                  onTap: () => context.go('/subscription'),
                  showDivider: false,
                ),
              ]),
              const SizedBox(height: 20),
              const _V2SectionHeader('About Us'),
              _card([
                V2ListRow(
                  icon: FitVizV2Icon.doc,
                  label: 'About',
                  value: 'Privacy Policy',
                  trailing: const FitVizV2IconView(FitVizV2Icon.chevron, size: 16, color: FitVizV2Colors.inkDim),
                  onTap: () => context.push('/about/privacy-policy'),
                  showDivider: false,
                ),
              ]),
              const SizedBox(height: 28),
              V2PillButton(
                label: 'Sign Out',
                variant: V2PillButtonVariant.outline,
                onTap: () => _confirmLogout(context),
                leading: const FitVizV2IconView(FitVizV2Icon.chevron, size: 14, color: FitVizV2Colors.danger),
              ),
              const SizedBox(height: 14),
              Center(
                child: ref.watch(_appVersionProviderV2).maybeWhen(
                      data: (v) => Text('${FlavorConfig.instance.appName} $v',
                          style: FitVizV2Text.body(size: 11, color: FitVizV2Colors.inkDim)),
                      orElse: () => const SizedBox.shrink(),
                    ),
              ),
            ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: FitVizV2Colors.surface,
        border: Border.all(color: FitVizV2Colors.border),
        borderRadius: BorderRadius.circular(FitVizV2Radius.md),
      ),
      child: Column(children: children),
    );
  }

  Future<void> _shareReferral(String? code) async {
    final text = code != null
        ? 'Join me on ${FlavorConfig.instance.appName}! Use my referral code $code to sign up.'
        : 'Join me on ${FlavorConfig.instance.appName} — the smart gym app!';
    await Share.share(text, subject: 'Join ${FlavorConfig.instance.appName}');
  }

  void _showNotificationSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FitVizV2Colors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(FitVizV2Radius.lg))),
      builder: (_) => const _NotificationSettingsSheetV2(),
    );
  }

  void _showChangePassword(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FitVizV2Colors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(FitVizV2Radius.lg))),
      builder: (_) => const _ChangePasswordSheetV2(),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FitVizV2Colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FitVizV2Radius.md)),
        title: Text('Sign Out', style: FitVizV2Text.h2()),
        content: Text('Are you sure you want to sign out of ${FlavorConfig.instance.appName}?',
            style: FitVizV2Text.body(size: 13, color: FitVizV2Colors.inkDim)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: FitVizV2Text.body(color: FitVizV2Colors.inkDim)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign Out',
                style: TextStyle(color: FitVizV2Colors.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) context.go('/auth/login');
    }
  }
}

class _V2SectionHeader extends StatelessWidget {
  final String title;
  const _V2SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title.toUpperCase(), style: FitVizV2Text.caption()),
    );
  }
}

class _ReferralRow extends StatelessWidget {
  final String code;
  const _ReferralRow({required this.code});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration:
                BoxDecoration(color: FitVizV2Colors.surface2, borderRadius: BorderRadius.circular(10)),
            child: const Center(
                child: FitVizV2IconView(FitVizV2Icon.doc, size: 16, color: FitVizV2Colors.accent)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your Referral Code', style: FitVizV2Text.caption()),
                const SizedBox(height: 2),
                Text(code,
                    style: FitVizV2Text.data(size: 16, color: FitVizV2Colors.accent)
                        .copyWith(letterSpacing: 1.5)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Referral code copied!'), duration: Duration(seconds: 2)),
              );
            },
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: FitVizV2IconView(FitVizV2Icon.doc, size: 16, color: FitVizV2Colors.inkDim),
            ),
          ),
          GestureDetector(
            onTap: () => Share.share(
              'Join me on ${FlavorConfig.instance.appName}! Use my referral code $code to sign up.',
              subject: 'Join ${FlavorConfig.instance.appName}',
            ),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: FitVizV2IconView(FitVizV2Icon.briefcase, size: 16, color: FitVizV2Colors.inkDim),
            ),
          ),
        ],
      ),
    );
  }
}

class _V2ToggleRow extends StatelessWidget {
  final FitVizV2Icon icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _V2ToggleRow({required this.icon, required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: FitVizV2Colors.border))),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration:
                BoxDecoration(color: FitVizV2Colors.surface2, borderRadius: BorderRadius.circular(10)),
            child: Center(child: FitVizV2IconView(icon, size: 16, color: FitVizV2Colors.accent)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: FitVizV2Text.body(size: 14, weight: FontWeight.w600))),
          _V2Toggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// Pill toggle switch matching the artifact's `.toggle` component.
class _V2Toggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _V2Toggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44,
        height: 26,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: value ? FitVizV2Colors.accent : FitVizV2Colors.surface2,
          border: value ? null : Border.all(color: FitVizV2Colors.border),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 150),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? FitVizV2Colors.accentInk : FitVizV2Colors.inkDim,
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationSettingsSheetV2 extends StatefulWidget {
  const _NotificationSettingsSheetV2();

  @override
  State<_NotificationSettingsSheetV2> createState() => _NotificationSettingsSheetV2State();
}

class _NotificationSettingsSheetV2State extends State<_NotificationSettingsSheetV2> {
  bool _pushEnabled = true;
  bool _workoutReminders = true;
  bool _subscriptionAlerts = true;
  bool _classReminders = true;
  bool _offersAnnouncements = true;
  bool _loading = true;
  String? _gymId;

  static const _kPush = 'notif_push';
  static const _kWorkout = 'notif_workout';
  static const _kSubscription = 'notif_subscription';
  static const _kClass = 'notif_class';
  static const _kAnnouncements = 'notif_announcements';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([SharedPreferences.getInstance(), SecureStorage.getGymId()]);
    final prefs = results[0] as SharedPreferences;
    final gymId = results[1] as String?;
    setState(() {
      _pushEnabled = prefs.getBool(_kPush) ?? true;
      _workoutReminders = prefs.getBool(_kWorkout) ?? true;
      _subscriptionAlerts = prefs.getBool(_kSubscription) ?? true;
      _classReminders = prefs.getBool(_kClass) ?? true;
      _offersAnnouncements = prefs.getBool(_kAnnouncements) ?? true;
      _gymId = gymId;
      _loading = false;
    });
  }

  Future<void> _save(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: FitVizV2Colors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Text('Notification Settings', style: FitVizV2Text.h2()),
          const SizedBox(height: 6),
          Text('Choose which notifications you receive from ${FlavorConfig.instance.appName}.',
              style: FitVizV2Text.body(size: 13, color: FitVizV2Colors.inkDim)),
          const SizedBox(height: 20),
          if (_loading)
            const Center(child: CircularProgressIndicator(color: FitVizV2Colors.accent))
          else ...[
            _V2ToggleRow(
              icon: FitVizV2Icon.bell,
              label: 'Push Notifications',
              value: _pushEnabled,
              onChanged: (v) {
                setState(() => _pushEnabled = v);
                _save(_kPush, v);
              },
            ),
            _V2ToggleRow(
              icon: FitVizV2Icon.dumbbell,
              label: 'Workout Reminders',
              value: _pushEnabled && _workoutReminders,
              onChanged: (v) {
                setState(() => _workoutReminders = v);
                _save(_kWorkout, v);
              },
            ),
            _V2ToggleRow(
              icon: FitVizV2Icon.doc,
              label: 'Subscription Alerts',
              value: _pushEnabled && _subscriptionAlerts,
              onChanged: (v) {
                setState(() => _subscriptionAlerts = v);
                _save(_kSubscription, v);
              },
            ),
            _V2ToggleRow(
              icon: FitVizV2Icon.calendar,
              label: 'Class Reminders',
              value: _pushEnabled && _classReminders,
              onChanged: (v) {
                setState(() => _classReminders = v);
                _save(_kClass, v);
              },
            ),
            _V2ToggleRow(
              icon: FitVizV2Icon.flame,
              label: 'Offers & Announcements',
              value: _pushEnabled && _offersAnnouncements,
              onChanged: (v) {
                setState(() => _offersAnnouncements = v);
                _save(_kAnnouncements, v);
                if (_gymId != null) NotificationService.toggleAnnouncementTopic(v, _gymId!);
              },
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FitVizV2Colors.surface2,
                borderRadius: BorderRadius.circular(FitVizV2Radius.sm),
              ),
              child: Row(
                children: [
                  const FitVizV2IconView(FitVizV2Icon.mail, size: 18, color: Color(0xFF25D366)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('WhatsApp Updates', style: FitVizV2Text.body(size: 13, weight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('Contact your gym admin to enable or disable WhatsApp notifications.',
                            style: FitVizV2Text.body(size: 11, color: FitVizV2Colors.inkDim)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChangePasswordSheetV2 extends ConsumerStatefulWidget {
  const _ChangePasswordSheetV2();

  @override
  ConsumerState<_ChangePasswordSheetV2> createState() => _ChangePasswordSheetV2State();
}

class _ChangePasswordSheetV2State extends ConsumerState<_ChangePasswordSheetV2> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).changePassword(_currentCtrl.text, _newCtrl.text);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully!'), backgroundColor: FitVizV2Colors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_friendlyError(e)), backgroundColor: FitVizV2Colors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(Object e) {
    if (e is DioException) {
      final serverMsg = e.response?.data?['message'] as String?;
      if (serverMsg != null && serverMsg.isNotEmpty) return serverMsg;
      final status = e.response?.statusCode;
      if (status == 400 || status == 401) return 'Current password is incorrect.';
      if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.unknown) {
        return 'No internet connection. Please check your network.';
      }
    }
    return 'Could not update password. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Change Password', style: FitVizV2Text.h2()),
            const SizedBox(height: 20),
            V2UnderlineField(
              controller: _currentCtrl,
              placeholder: 'Current Password',
              leadingIcon: FitVizV2Icon.lock,
              obscureText: _obscureCurrent,
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              trailing: GestureDetector(
                onTap: () => setState(() => _obscureCurrent = !_obscureCurrent),
                child: const FitVizV2IconView(FitVizV2Icon.eye, size: 18, color: FitVizV2Colors.inkDim),
              ),
            ),
            const SizedBox(height: 4),
            V2UnderlineField(
              controller: _newCtrl,
              placeholder: 'New Password',
              leadingIcon: FitVizV2Icon.lock,
              obscureText: _obscureNew,
              validator: Validators.password,
              trailing: GestureDetector(
                onTap: () => setState(() => _obscureNew = !_obscureNew),
                child: const FitVizV2IconView(FitVizV2Icon.eye, size: 18, color: FitVizV2Colors.inkDim),
              ),
            ),
            const SizedBox(height: 22),
            V2PillButton(label: 'Update Password', loading: _loading, onTap: _loading ? null : _submit),
          ],
        ),
      ),
    );
  }
}
