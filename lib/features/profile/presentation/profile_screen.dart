import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../flavors/flavor_config.dart';
import '../../../shared/theme/app_theme.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/data/models/auth_model.dart';
import '../../../core/providers/session_provider.dart';
import '../../feedback/data/feedback_repository.dart';

final _profileProvider = FutureProvider<UserModel>((ref) {
  ref.watch(sessionVersionProvider);
  return ref.read(authRepositoryProvider).getProfile();
});

final _referralCodeProvider = FutureProvider<String?>((ref) {
  ref.watch(sessionVersionProvider);
  return ref.read(feedbackRepositoryProvider).getReferralCode();
});


class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(_profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: profileAsync.when(
        data: (user) => _ProfileContent(user: user),
        loading: () =>
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error loading profile: $e')),
      ),
    );
  }
}

class _ProfileContent extends ConsumerStatefulWidget {
  final UserModel user;

  const _ProfileContent({required this.user});

  @override
  ConsumerState<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends ConsumerState<_ProfileContent> {
  bool _biometricEnabled = false;
  static const _kBiometric = 'biometric_enabled';

  @override
  void initState() {
    super.initState();
    _loadBiometric();
  }

  Future<void> _loadBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _biometricEnabled = prefs.getBool(_kBiometric) ?? false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Avatar + name
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.surface,
                backgroundImage: widget.user.profilePhoto != null
                    ? NetworkImage(widget.user.profilePhoto!)
                    : null,
                child: widget.user.profilePhoto == null
                    ? Text(
                        widget.user.name.isNotEmpty
                            ? widget.user.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                widget.user.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              if (widget.user.email != null)
                Text(
                  widget.user.email!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        // Info section
        _SectionHeader('Account'),
        if (widget.user.membershipId != null)
          _InfoTile(
              icon: Icons.badge_outlined,
              label: 'Member ID',
              value: '#${widget.user.membershipId}'),
        _InfoTile(icon: Icons.person_outline, label: 'Full Name', value: widget.user.name),
        if (widget.user.email != null)
          _InfoTile(icon: Icons.email_outlined, label: 'Email', value: widget.user.email!),
        if (widget.user.phone != null)
          _InfoTile(
              icon: Icons.phone_outlined, label: 'Phone', value: widget.user.phone!),
        const SizedBox(height: 20),
        // Security
        _SectionHeader('Security'),
        _ToggleTile(
          icon: Icons.fingerprint,
          label: 'Biometric Unlock',
          value: _biometricEnabled,
          onChanged: (v) async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool(_kBiometric, v);
            if (mounted) setState(() => _biometricEnabled = v);
          },
        ),
        _ActionTile(
          icon: Icons.lock_outline,
          label: 'Change Password',
          onTap: () => _showChangePassword(context),
        ),
        const SizedBox(height: 20),
        // Referral
        _SectionHeader('Referrals'),
        ref.watch(_referralCodeProvider).when(
          data: (code) => code != null
              ? _ReferralCodeTile(code: code)
              : _ActionTile(
                  icon: Icons.share_outlined,
                  label: 'Share Referral Code',
                  onTap: () => _shareReferral(null),
                ),
          loading: () => const SizedBox(height: 50),
          error: (_, __) => _ActionTile(
            icon: Icons.share_outlined,
            label: 'Share Referral Code',
            onTap: () => _shareReferral(null),
          ),
        ),
        const SizedBox(height: 20),
        // Notifications
        _SectionHeader('Notifications'),
        _ActionTile(
          icon: Icons.notifications_outlined,
          label: 'Notification Settings',
          onTap: () => _showNotificationSettings(context),
        ),
        const SizedBox(height: 20),
        // Feedback
        _SectionHeader('Feedback'),
        _ActionTile(
          icon: Icons.star_outline_rounded,
          label: 'Rate Your Experience',
          onTap: () => context.push('/feedback'),
        ),
        const SizedBox(height: 20),
        // Subscription
        _SectionHeader('Subscription'),
        _ActionTile(
          icon: Icons.card_membership_outlined,
          label: 'My Subscription & Plans',
          onTap: () => context.go('/subscription'),
        ),
        const SizedBox(height: 28),
        // Logout
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
          ),
          icon: const Icon(Icons.logout),
          label: const Text('Sign Out'),
          onPressed: () => _confirmLogout(context),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            '${FlavorConfig.instance.appName} v1.0.0',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
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
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _NotificationSettingsSheet(),
    );
  }

  void _showChangePassword(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _ChangePasswordSheet(),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Sign Out'),
        content:
            Text('Are you sure you want to sign out of ${FlavorConfig.instance.appName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign Out',
                style: TextStyle(color: AppColors.error)),
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

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 11)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile(
      {required this.icon,
      required this.label,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: AppColors.textPrimary, fontWeight: FontWeight.w500))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}

class _ReferralCodeTile extends StatelessWidget {
  final String code;
  const _ReferralCodeTile({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.card_giftcard_outlined,
              color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your Referral Code',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 11)),
                SizedBox(height: 2),
                Text(code,
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: 1.5)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.copy_outlined,
                color: AppColors.textSecondary, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Referral code copied!'),
                    duration: Duration(seconds: 2)),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.share_outlined,
                color: AppColors.textSecondary, size: 18),
            onPressed: () => Share.share(
              'Join me on ${FlavorConfig.instance.appName}! Use my referral code $code to sign up.',
              subject: 'Join ${FlavorConfig.instance.appName}',
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationSettingsSheet extends StatefulWidget {
  const _NotificationSettingsSheet();

  @override
  State<_NotificationSettingsSheet> createState() =>
      _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState
    extends State<_NotificationSettingsSheet> {
  bool _pushEnabled = true;
  bool _workoutReminders = true;
  bool _subscriptionAlerts = true;
  bool _classReminders = true;
  bool _loading = true;

  static const _kPush = 'notif_push';
  static const _kWorkout = 'notif_workout';
  static const _kSubscription = 'notif_subscription';
  static const _kClass = 'notif_class';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushEnabled = prefs.getBool(_kPush) ?? true;
      _workoutReminders = prefs.getBool(_kWorkout) ?? true;
      _subscriptionAlerts = prefs.getBool(_kSubscription) ?? true;
      _classReminders = prefs.getBool(_kClass) ?? true;
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
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('Notification Settings',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Choose which notifications you receive from ${FlavorConfig.instance.appName}.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          if (_loading)
            Center(
                child:
                    CircularProgressIndicator(color: AppColors.primary))
          else ...[
            // Master push toggle
            _NotifToggle(
              icon: Icons.notifications_active_outlined,
              label: 'Push Notifications',
              subtitle: 'Receive all app notifications',
              value: _pushEnabled,
              onChanged: (v) {
                setState(() => _pushEnabled = v);
                _save(_kPush, v);
              },
              highlight: true,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: AppColors.cardBorder),
            ),
            // Per-type toggles (grayed when push is off)
            _NotifToggle(
              icon: Icons.fitness_center_outlined,
              label: 'Workout Reminders',
              subtitle: 'Daily plan & workout alerts',
              value: _pushEnabled && _workoutReminders,
              enabled: _pushEnabled,
              onChanged: (v) {
                setState(() => _workoutReminders = v);
                _save(_kWorkout, v);
              },
            ),
            _NotifToggle(
              icon: Icons.card_membership_outlined,
              label: 'Subscription Alerts',
              subtitle: 'Expiry warnings & renewal reminders',
              value: _pushEnabled && _subscriptionAlerts,
              enabled: _pushEnabled,
              onChanged: (v) {
                setState(() => _subscriptionAlerts = v);
                _save(_kSubscription, v);
              },
            ),
            _NotifToggle(
              icon: Icons.event_outlined,
              label: 'Class Reminders',
              subtitle: 'Upcoming class bookings',
              value: _pushEnabled && _classReminders,
              enabled: _pushEnabled,
              onChanged: (v) {
                setState(() => _classReminders = v);
                _save(_kClass, v);
              },
            ),
            const SizedBox(height: 16),
            // WhatsApp info row
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Row(
                children: [
                  Icon(Icons.chat_outlined,
                      color: Color(0xFF25D366), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('WhatsApp Updates',
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                                fontSize: 14)),
                        SizedBox(height: 2),
                        Text(
                          'Contact your gym admin to enable or disable WhatsApp notifications.',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 11),
                        ),
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

class _NotifToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final bool highlight;

  const _NotifToggle({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    this.enabled = true,
    required this.onChanged,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final active = enabled && value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (highlight && active)
                  ? AppColors.primary.withOpacity(0.12)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon,
                size: 18,
                color: (highlight && active)
                    ? AppColors.primary
                    : enabled
                        ? AppColors.textSecondary
                        : AppColors.textMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: enabled
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                        fontSize: 14)),
                Text(subtitle,
                    style: TextStyle(
                        color: enabled
                            ? AppColors.textSecondary
                            : AppColors.textMuted,
                        fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: active,
            onChanged: enabled ? onChanged : null,
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState
    extends ConsumerState<_ChangePasswordSheet> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Change Password',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            TextFormField(
              controller: _currentCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current Password'),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _newCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password'),
              validator: (v) =>
                  (v != null && v.length >= 8) ? null : 'Min 8 characters',
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : () {},
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.darkBg))
                  : const Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }
}
