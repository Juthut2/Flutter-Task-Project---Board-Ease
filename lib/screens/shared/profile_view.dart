import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/helpers.dart';
import '../../core/validators.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../services/image_upload_service.dart';
import '../../widgets/complete_profile_banner.dart';
import '../../widgets/profile_details_fields.dart';
import '../../widgets/user_avatar.dart';

/// Profile display and editing, shared by the owner and tenant account tabs.
class ProfileView extends StatefulWidget {
  const ProfileView({super.key, this.startInEditMode = false});

  final bool startInEditMode;

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  String? _gender;
  DateTime? _birthday;
  bool _editing = false;
  bool _saving = false;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _gender = user?.gender;
    _birthday = user?.birthday;
    _editing = widget.startInEditMode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _startEdit(AppUser user) {
    _nameController.text = user.name;
    _phoneController.text = user.phone;
    setState(() {
      _gender = user.gender;
      _birthday = user.birthday;
      _editing = true;
    });
  }

  void _cancelEdit(AppUser user) {
    _nameController.text = user.name;
    _phoneController.text = user.phone;
    setState(() {
      _gender = user.gender;
      _birthday = user.birthday;
      _editing = false;
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final gender = _gender;
    final birthday = _birthday;
    if (gender == null || birthday == null) return;

    final auth = context.read<AuthProvider>();
    setState(() => _saving = true);
    final success = await auth.updateProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      gender: gender,
      birthday: birthday,
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (success) _editing = false;
    });
    AppHelpers.showSnackBar(
      context,
      success
          ? 'Profile updated.'
          : (auth.errorMessage ?? 'Could not update your profile.'),
      isError: !success,
    );
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final auth = context.read<AuthProvider>();
    setState(() => _uploadingPhoto = true);
    try {
      final url = await ImageUploadService().pickAndUpload(
        source: source,
        compressAlways: true,
        maxWidth: AppConstants.imageMaxDimension,
        maxHeight: AppConstants.imageMaxDimension,
        imageQuality: AppConstants.imageQuality,
      );
      if (!mounted || url == null) return;
      final success = await auth.updatePhotoUrl(url);
      if (!mounted) return;
      AppHelpers.showSnackBar(
        context,
        success
            ? 'Profile photo updated.'
            : (auth.errorMessage ?? 'Could not save your photo.'),
        isError: !success,
      );
    } on ImageUploadFailure catch (error) {
      if (mounted) {
        AppHelpers.showSnackBar(context, error.message, isError: true);
      }
    } catch (_) {
      if (mounted) {
        AppHelpers.showSnackBar(
          context,
          'Could not upload the photo. Please try again.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will need to sign in again to access your account.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<AuthProvider>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final roleLabel = user.isOwner ? 'Owner' : 'Tenant';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        if (!_editing) ...<Widget>[
          CompleteProfileBanner(onComplete: () => _startEdit(user)),
          const SizedBox(height: 16),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: <Widget>[
                UserAvatar(
                  name: user.name,
                  photoUrl: user.photoUrl,
                  radius: 48,
                  onTap: _pickPhoto,
                  busy: _uploadingPhoto,
                  showEditBadge: true,
                ),
                const SizedBox(height: 14),
                Text(
                  user.name,
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Chip(
                  avatar: Icon(
                    user.isOwner
                        ? Icons.admin_panel_settings_outlined
                        : Icons.person_outline_rounded,
                    size: 18,
                  ),
                  label: Text(roleLabel),
                ),
                if (!_editing) ...<Widget>[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _startEdit(user),
                    icon: Icon(
                      user.hasCompleteProfile
                          ? Icons.edit_outlined
                          : Icons.auto_fix_high_rounded,
                    ),
                    label: Text(
                      user.hasCompleteProfile
                          ? 'Edit profile'
                          : 'Customize profile',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_editing)
          _EditForm(
            formKey: _formKey,
            user: user,
            nameController: _nameController,
            phoneController: _phoneController,
            gender: _gender,
            birthday: _birthday,
            saving: _saving,
            onGenderChanged: (value) => setState(() => _gender = value),
            onBirthdayChanged: (value) => setState(() => _birthday = value),
            onCancel: () => _cancelEdit(user),
            onSave: _save,
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: Column(
                children: <Widget>[
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: user.phone.isEmpty ? 'Not provided' : user.phone,
                  ),
                  const Divider(),
                  _InfoRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Gender',
                    value: user.genderLabel,
                  ),
                  const Divider(),
                  _InfoRow(
                    icon: Icons.cake_outlined,
                    label: 'Birthday',
                    value: AppHelpers.formatDate(user.birthday),
                  ),
                  const Divider(),
                  _InfoRow(
                    icon: Icons.badge_outlined,
                    label: 'Account type',
                    value: roleLabel,
                  ),
                  const Divider(),
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Member since',
                    value: AppHelpers.formatDate(user.createdAt),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: auth.isLoading ? null : _confirmSignOut,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sign out'),
        ),
        const SizedBox(height: 12),
        Text(
          'Signed in securely with Firebase Authentication.',
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _EditForm extends StatelessWidget {
  const _EditForm({
    required this.formKey,
    required this.user,
    required this.nameController,
    required this.phoneController,
    required this.gender,
    required this.birthday,
    required this.saving,
    required this.onGenderChanged,
    required this.onBirthdayChanged,
    required this.onCancel,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final AppUser user;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final String? gender;
  final DateTime? birthday;
  final bool saving;
  final ValueChanged<String> onGenderChanged;
  final ValueChanged<DateTime> onBirthdayChanged;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Edit profile',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                enabled: !saving,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: Validators.name,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                enabled: !saving,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: Validators.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  hintText: '09171234567',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: user.email,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                  helperText: 'Email cannot be changed here.',
                ),
              ),
              const SizedBox(height: 16),
              ProfileDetailsFields(
                gender: gender,
                onGenderChanged: onGenderChanged,
                birthday: birthday,
                onBirthdayChanged: onBirthdayChanged,
                enabled: !saving,
              ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: saving ? null : onCancel,
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: saving ? null : onSave,
                      child: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save changes'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
