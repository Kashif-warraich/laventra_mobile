import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/data/models/user_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/services/biometric_service.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileFormKey  = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  final TextEditingController _passwordCtrl     = TextEditingController();
  final TextEditingController _confirmPassCtrl  = TextEditingController();

  bool _obscurePassword        = true;
  bool _obscureConfirmPassword = true;
  bool _biometricEnabled       = false;
  bool _biometricAvailable     = false;
  bool _isFaceId               = false;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl = TextEditingController(text: widget.user.firstName);
    _lastNameCtrl  = TextEditingController(text: widget.user.lastName);
    _usernameCtrl  = TextEditingController(text: widget.user.username);
    _emailCtrl     = TextEditingController(text: widget.user.email);
    _phoneCtrl     = TextEditingController(text: widget.user.phoneNumber ?? '');

    // Load fresh data from API
    context.read<ProfileBloc>().add(
      ProfileLoadRequested(widget.user.id),
    );

    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    final available = await BiometricService.instance.isAvailable();
    final enabled   = await SecureStorage.instance.getBiometricEnabled();
    final faceId    = await BiometricService.instance.isFaceId();
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled   = enabled;
        _isFaceId           = faceId;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // Confirm identity before enabling
      final success = await BiometricService.instance.authenticate(
        reason: 'Verify your identity to enable biometric login',
      );
      if (!success) return;
    }
    if (value) {
      await SecureStorage.instance.setBiometricEnabled(true);
    } else {
      await SecureStorage.instance.clearBiometricCredentials();
    }
    if (mounted) {
      setState(() => _biometricEnabled = value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? '${_isFaceId ? 'Face ID' : 'Fingerprint'} login enabled'
                : 'Biometric login disabled',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _populateFields(UserModel user) {
    _firstNameCtrl.text = user.firstName;
    _lastNameCtrl.text  = user.lastName;
    _usernameCtrl.text  = user.username;
    _emailCtrl.text     = user.email;
    _phoneCtrl.text     = user.phoneNumber ?? '';
  }

  void _submitProfile(UserModel user) {
    if (_profileFormKey.currentState?.validate() ?? false) {
      context.read<ProfileBloc>().add(
        ProfileUpdateRequested(
          userId:      user.id,
          firstName:   _firstNameCtrl.text.trim(),
          lastName:    _lastNameCtrl.text.trim(),
          username:    _usernameCtrl.text.trim(),
          email:       _emailCtrl.text.trim(),
          phoneNumber: _phoneCtrl.text.trim().isEmpty
              ? null
              : _phoneCtrl.text.trim(),
        ),
      );
    }
  }

  void _submitPassword(UserModel user) {
    if (_passwordFormKey.currentState?.validate() ?? false) {
      context.read<ProfileBloc>().add(
        ProfilePasswordUpdateRequested(
          userId:               user.id,
          password:             _passwordCtrl.text,
          passwordConfirmation: _confirmPassCtrl.text,
        ),
      );
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(100, 44),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileLoaded) {
          _populateFields(state.user);
        }
        if (state is ProfileUpdateSuccess) {
          _populateFields(state.user);
          if (state.message.contains('Password')) {
            _passwordCtrl.clear();
            _confirmPassCtrl.clear();
          }
        }
      },
      builder: (context, state) {
        final user = switch (state) {
          ProfileLoaded       s => s.user,
          ProfileUpdating     s => s.user,
          ProfileUpdateSuccess s => s.user,
          ProfileError        s => s.user ?? widget.user,
          _                     => widget.user,
        };

        final isLoading  = state is ProfileLoading;
        final isUpdating = state is ProfileUpdating;
        final isSuccess  = state is ProfileUpdateSuccess;
        final error      = state is ProfileError ? state.message : null;
        final successMsg = isSuccess
            ? (state as ProfileUpdateSuccess).message
            : null;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              IconButton(
                onPressed: _confirmLogout,
                icon: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.error,
                ),
                tooltip: 'Sign Out',
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [

                // ── Profile Header ──
                _ProfileHeader(user: user),

                const SizedBox(height: 24),

                // ── Success / Error Banner ──
                if (successMsg != null)
                  _Banner(
                    message: successMsg,
                    isSuccess: true,
                  ),
                if (error != null)
                  _Banner(
                    message: error,
                    isSuccess: false,
                  ),

                if (successMsg != null || error != null)
                  const SizedBox(height: 16),

                // ── Personal Info Form ──
                _SectionCard(
                  title: 'Personal Information',
                  icon: Icons.person_outline_rounded,
                  child: Form(
                    key: _profileFormKey,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _Field(
                                label:      'First Name',
                                controller: _firstNameCtrl,
                                validator:  (v) => v!.isEmpty
                                    ? 'Required'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _Field(
                                label:      'Last Name',
                                controller: _lastNameCtrl,
                                validator:  (v) => v!.isEmpty
                                    ? 'Required'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _Field(
                          label:      'Username',
                          controller: _usernameCtrl,
                          prefixText: '@',
                          validator:  (v) => v!.isEmpty
                              ? 'Required'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _Field(
                          label:       'Email Address',
                          controller:  _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          validator:   (v) {
                            if (v!.isEmpty) return 'Required';
                            if (!v.contains('@')) return 'Invalid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _Field(
                          label:       'Phone Number',
                          controller:  _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          required:    false,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: isUpdating
                              ? null
                              : () => _submitProfile(user),
                          child: isUpdating
                              ? const _LoadingIndicator()
                              : const Text('Save Changes'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Change Password Form ──
                _SectionCard(
                  title: 'Change Password',
                  icon:  Icons.lock_outline_rounded,
                  child: Form(
                    key: _passwordFormKey,
                    child: Column(
                      children: [
                        _PasswordField(
                          label:      'New Password',
                          controller: _passwordCtrl,
                          obscure:    _obscurePassword,
                          onToggle:   () => setState(() {
                            _obscurePassword = !_obscurePassword;
                          }),
                          validator: (v) {
                            if (v!.isEmpty) return 'Required';
                            if (v.length < 6) return 'Min 6 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _PasswordField(
                          label:      'Confirm Password',
                          controller: _confirmPassCtrl,
                          obscure:    _obscureConfirmPassword,
                          onToggle:   () => setState(() {
                            _obscureConfirmPassword =
                            !_obscureConfirmPassword;
                          }),
                          validator: (v) {
                            if (v!.isEmpty) return 'Required';
                            if (v != _passwordCtrl.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: isUpdating
                              ? null
                              : () => _submitPassword(user),
                          child: isUpdating
                              ? const _LoadingIndicator()
                              : const Text('Update Password'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Security ──
                if (_biometricAvailable)
                  _SectionCard(
                    title: 'Security',
                    icon:  Icons.security_rounded,
                    child: Row(
                      children: [
                        Icon(
                          _isFaceId
                              ? Icons.face_unlock_outlined
                              : Icons.fingerprint_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isFaceId ? 'Face ID' : 'Fingerprint Login',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Sign in without entering your password',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value:    _biometricEnabled,
                          onChanged: _toggleBiometric,
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // ── Sign Out ──
                OutlinedButton.icon(
                  onPressed: _confirmLogout,
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.error,
                  ),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(color: AppColors.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Profile Header Widget ──────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final UserModel user;
  const _ProfileHeader({required this.user});

  Color _roleColor(String role) => switch (role) {
    'admin'       => AppColors.primary,
    'super_admin' => const Color(0xFF7C3AED),
    _             => AppColors.textSecondary,
  };

  Color _statusColor(String status) => switch (status) {
    'active'    => AppColors.success,
    'inactive'  => AppColors.warning,
    'suspended' => AppColors.error,
    _           => AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '${user.firstName[0]}${user.lastName[0]}'.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            user.fullName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            '@${user.username}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
          ),

          const SizedBox(height: 4),

          Text(
            user.email,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 16),

          // Role + Status badges
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Badge(
                label: user.role.toUpperCase(),
                color: _roleColor(user.role),
              ),
              const SizedBox(width: 8),
              _Badge(
                label:  user.status.toUpperCase(),
                color:  _statusColor(user.status),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color  color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Section Card ──────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.border),
          child,
        ],
      ),
    );
  }
}

// ── Reusable Field ────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final String                  label;
  final TextEditingController   controller;
  final TextInputType           keyboardType;
  final String?                 prefixText;
  final String? Function(String?)? validator;
  final bool                    required;

  const _Field({
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.prefixText,
    this.validator,
    this.required = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller:   controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixText: prefixText,
            hintText:   required ? null : 'Optional',
          ),
          validator: validator,
        ),
      ],
    );
  }
}

// ── Password Field ────────────────────────────────────────────────
class _PasswordField extends StatelessWidget {
  final String                    label;
  final TextEditingController     controller;
  final bool                      obscure;
  final VoidCallback              onToggle;
  final String? Function(String?)? validator;

  const _PasswordField({
    required this.label,
    required this.controller,
    required this.obscure,
    required this.onToggle,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller:  controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.textSecondary,
            ),
            suffixIcon: IconButton(
              onPressed: onToggle,
              icon: Icon(
                obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}

// ── Banner ────────────────────────────────────────────────────────
class _Banner extends StatelessWidget {
  final String message;
  final bool   isSuccess;
  const _Banner({required this.message, required this.isSuccess});

  @override
  Widget build(BuildContext context) {
    final color = isSuccess ? AppColors.success : AppColors.error;
    final icon  = isSuccess
        ? Icons.check_circle_outline_rounded
        : Icons.error_outline_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color:      color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loading Indicator ─────────────────────────────────────────────
class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 20,
      width:  20,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }
}