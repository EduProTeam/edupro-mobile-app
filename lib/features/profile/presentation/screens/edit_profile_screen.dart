import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../auth/services/auth_service.dart';
import 'profile_photo_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.user});

  final User user;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const _primaryBlue = Color(0xFF3D8FEF);
  static const _textPrimary = Color(0xFF1E1E1E);
  static const _textSecondary = Color(0xFF6B7280);
  static const _borderColor = Color(0xFFE5E7EB);

  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _organizationController = TextEditingController();
  final _professionalTitleController = TextEditingController();
  final _bioController = TextEditingController();

  List<String> _skills = [];
  List<String> _interests = [];
  String? _profileImageUrl;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.user.email ?? '';
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _organizationController.dispose();
    _professionalTitleController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final document = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get();
      final profile = document.data();
      _fullNameController.text =
          _text(profile?['fullName']) ?? widget.user.displayName?.trim() ?? '';
      _usernameController.text = _text(profile?['username']) ?? '';
      _phoneController.text = _text(profile?['phone']) ?? '';
      _organizationController.text = _text(profile?['organization']) ?? '';
      _professionalTitleController.text =
          _text(profile?['professionalTitle']) ?? '';
      _bioController.text = _text(profile?['bio']) ?? '';
      _profileImageUrl = _text(profile?['profileImageUrl']);
      _skills = _stringList(profile?['skills']);
      _interests = _stringList(profile?['learningInterests']);
    } catch (_) {
      _showSnackBar('Unable to load profile details. You can still edit them.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (_isSaving || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _authService.updateProfile(
        fullName: _fullNameController.text.trim(),
        username: _optional(_usernameController.text),
        phone: _optional(_phoneController.text),
        organization: _optional(_organizationController.text),
        professionalTitle: _optional(_professionalTitleController.text),
        bio: _optional(_bioController.text),
        skills: _skills,
        learningInterests: _interests,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AuthFailure catch (error) {
      _showSnackBar(error.message);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _addValue({required bool isSkill}) async {
    final label = isSkill ? 'Skill' : 'Learning Interest';
    final value = await showDialog<String>(
      context: context,
      builder: (_) => _AddValueDialog(label: label),
    );

    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return;
    }

    final values = isSkill ? _skills : _interests;
    if (values.any((item) => item.toLowerCase() == normalized.toLowerCase())) {
      _showSnackBar('$label is already added.');
      return;
    }
    setState(() => values.add(normalized));
  }

  String? _text(dynamic value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }

  List<String> _stringList(dynamic value) {
    if (value is! Iterable) return [];
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String? _optional(String value) => value.trim().isEmpty ? null : value.trim();

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _openProfilePhoto() async {
    final result = await Navigator.of(context).push<ProfilePhotoResult>(
      MaterialPageRoute<ProfilePhotoResult>(
        builder: (_) =>
            ProfilePhotoScreen(user: widget.user, imageUrl: _profileImageUrl),
      ),
    );
    if (result != null && mounted) {
      setState(() => _profileImageUrl = result.imageUrl);
      _showSnackBar(
        result.imageUrl == null
            ? 'Profile photo removed successfully.'
            : 'Profile photo updated successfully.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.w800, color: _textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _primaryBlue,
                    ),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              top: false,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Avatar(
                        imageUrl: _profileImageUrl,
                        onTap: _openProfilePhoto,
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _openProfilePhoto,
                        child: const Text(
                          'Change Profile Photo',
                          style: TextStyle(fontSize: 17, color: _primaryBlue),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _ProfileField(
                        label: 'Full Name',
                        icon: Icons.person_outline,
                        controller: _fullNameController,
                        validator: (value) {
                          final name = value?.trim() ?? '';
                          if (name.length < 2) return 'Enter your full name.';
                          return null;
                        },
                      ),
                      _ProfileField(
                        label: 'Username',
                        icon: Icons.alternate_email,
                        controller: _usernameController,
                      ),
                      _ProfileField(
                        label: 'Email Address',
                        icon: Icons.email_outlined,
                        controller: _emailController,
                        readOnly: true,
                      ),
                      _ProfileField(
                        label: 'Phone Number',
                        icon: Icons.phone_outlined,
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                      ),
                      _ProfileField(
                        label: 'University / Organization',
                        icon: Icons.account_balance_outlined,
                        controller: _organizationController,
                      ),
                      _ProfileField(
                        label: 'Professional Title',
                        icon: Icons.work_outline,
                        controller: _professionalTitleController,
                      ),
                      _ProfileField(
                        label: 'Bio',
                        icon: Icons.edit_outlined,
                        controller: _bioController,
                        maxLines: 3,
                        maxLength: 150,
                      ),
                      const SizedBox(height: 8),
                      _EditableChipSection(
                        title: 'Skills',
                        values: _skills,
                        addLabel: '+ Add Skill',
                        onAdd: () => _addValue(isSkill: true),
                        onRemove: (value) =>
                            setState(() => _skills.remove(value)),
                      ),
                      const SizedBox(height: 24),
                      _EditableChipSection(
                        title: 'Learning Interests',
                        values: _interests,
                        addLabel: '+ Add Interest',
                        isInterest: true,
                        onAdd: () => _addValue(isSkill: false),
                        onRemove: (value) =>
                            setState(() => _interests.remove(value)),
                      ),
                      const SizedBox(height: 30),
                      FilledButton(
                        onPressed: _isSaving ? null : _save,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          backgroundColor: _primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                      TextButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontSize: 17, color: _primaryBlue),
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.imageUrl, required this.onTap});
  final String? imageUrl;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 112,
        height: 112,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 102,
              height: 102,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEFF6FF),
                border: Border.all(color: Colors.white, width: 4),
                image: imageUrl == null
                    ? null
                    : DecorationImage(
                        image: NetworkImage(imageUrl!),
                        fit: BoxFit.cover,
                      ),
              ),
              child: imageUrl == null
                  ? const Icon(
                      Icons.person,
                      size: 52,
                      color: _EditProfileScreenState._primaryBlue,
                    )
                  : null,
            ),
            Positioned(
              right: 0,
              bottom: 5,
              child: Material(
                color: _EditProfileScreenState._primaryBlue,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onTap,
                  customBorder: const CircleBorder(),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      size: 20,
                      color: Colors.white,
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

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.icon,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
  });
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool readOnly;
  final int maxLines;
  final int? maxLength;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _EditProfileScreenState._textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          readOnly: readOnly,
          maxLines: maxLines,
          maxLength: maxLength,
          style: TextStyle(
            color: readOnly
                ? _EditProfileScreenState._textSecondary
                : _EditProfileScreenState._textPrimary,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: _EditProfileScreenState._textSecondary,
            ),
            filled: true,
            fillColor: readOnly ? const Color(0xFFF9FAFB) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: _EditProfileScreenState._borderColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: _EditProfileScreenState._primaryBlue,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _EditableChipSection extends StatelessWidget {
  const _EditableChipSection({
    required this.title,
    required this.values,
    required this.addLabel,
    required this.onAdd,
    required this.onRemove,
    this.isInterest = false,
  });
  final String title;
  final List<String> values;
  final String addLabel;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;
  final bool isInterest;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: _EditProfileScreenState._textPrimary,
        ),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          ...values.map(
            (value) => InputChip(
              label: Text(value),
              onDeleted: () => onRemove(value),
              labelStyle: const TextStyle(
                color: _EditProfileScreenState._primaryBlue,
                fontWeight: FontWeight.w600,
              ),
              deleteIconColor: _EditProfileScreenState._primaryBlue,
              backgroundColor: isInterest
                  ? const Color(0xFFEFF6FF)
                  : Colors.white,
              side: const BorderSide(
                color: _EditProfileScreenState._primaryBlue,
              ),
            ),
          ),
          ActionChip(
            label: Text(addLabel),
            onPressed: onAdd,
            labelStyle: const TextStyle(
              color: _EditProfileScreenState._primaryBlue,
              fontWeight: FontWeight.w700,
            ),
            backgroundColor: Colors.white,
            side: const BorderSide(color: _EditProfileScreenState._primaryBlue),
          ),
        ],
      ),
    ],
  );
}

class _AddValueDialog extends StatefulWidget {
  const _AddValueDialog({required this.label});

  final String label;

  @override
  State<_AddValueDialog> createState() => _AddValueDialogState();
}

class _AddValueDialogState extends State<_AddValueDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add ${widget.label}'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          hintText: 'Enter a ${widget.label.toLowerCase()}',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}
