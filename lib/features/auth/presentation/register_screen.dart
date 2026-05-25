import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/validators.dart';
import '../../../flavors/flavor_config.dart';
import '../../../shared/theme/app_theme.dart';
import '../data/auth_repository.dart';
import '../data/models/auth_model.dart';
import '../providers/auth_provider.dart';

// Fetches all active gyms, then scopes the list to the brand family when
// FlavorConfig.brandParentGymId is set (e.g. K2 Fitness shows only its branches).
// The backend already returns parentGymId on each gym — no query param needed.
final _gymsProvider = FutureProvider<List<GymModel>>((ref) async {
  final config = FlavorConfig.instance;
  final allGyms = await ref.read(authRepositoryProvider).getActiveGyms();

  if (!config.hasBrandFilter) return allGyms;

  // brandParentGymId holds the human-readable gymCode (e.g. "GYM-002").
  // Find the parent gym to get its cuid, then include parent + direct children.
  final parent = allGyms.cast<GymModel?>().firstWhere(
    (g) => g?.gymCode == config.brandParentGymId,
    orElse: () => null,
  );
  if (parent == null) return [];

  return allGyms
      .where((g) => g.id == parent.id || g.parentGymId == parent.id)
      .toList();
});

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscurePass = true;
  GymModel? _selectedGym;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGym == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your gym'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    await ref.read(authProvider.notifier).register(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          password: _passCtrl.text,
          gymId: _selectedGym!.id,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final gymsAsync = ref.watch(_gymsProvider);
    final isLoading = authState.maybeWhen(loading: () => true, orElse: () => false);

    ref.listen(authProvider, (_, next) {
      next.maybeWhen(
        error: (message) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.error),
        ),
        orElse: () {},
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
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
                Text('Join ${FlavorConfig.instance.appName}',
                    style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 8),
                Text(FlavorConfig.instance.appTagline,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 28),
                // Name
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: (v) => Validators.required(v, 'Full name'),
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline,
                        color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 14),
                // Email
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined,
                        color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 14),
                // Phone
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: Validators.phone,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number',
                    prefixIcon: Icon(Icons.phone_outlined,
                        color: AppColors.textSecondary),
                    prefixText: '+91 ',
                    prefixStyle: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 14),
                // Gym selector
                gymsAsync.when(
                  data: (gyms) => DropdownButtonFormField<GymModel>(
                    value: _selectedGym,
                    dropdownColor: AppColors.cardBg,
                    decoration: const InputDecoration(
                      labelText: 'Select Your Gym',
                      prefixIcon: Icon(Icons.fitness_center,
                          color: AppColors.textSecondary),
                    ),
                    items: gyms
                        .map((g) => DropdownMenuItem(
                              value: g,
                              child: Text(g.name),
                            ))
                        .toList(),
                    onChanged: (g) => setState(() => _selectedGym = g),
                    validator: (_) =>
                        _selectedGym == null ? 'Please select a gym' : null,
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => const Text('Could not load gyms'),
                ),
                const SizedBox(height: 14),
                // Password
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  textInputAction: TextInputAction.next,
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
                const SizedBox(height: 14),
                // Confirm password
                TextFormField(
                  controller: _confirmPassCtrl,
                  obscureText: _obscurePass,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (v) =>
                      Validators.confirmPassword(v, _passCtrl.text),
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: Icon(Icons.lock_outline,
                        color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.darkBg),
                        )
                      : const Text('Create Account'),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account?',
                        style: Theme.of(context).textTheme.bodyMedium),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text(
                        'Sign In',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
