import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/profile_photo_service.dart';

class ProfilePhotoResult {
  const ProfilePhotoResult(this.imageUrl);

  final String? imageUrl;
}

class ProfilePhotoScreen extends StatefulWidget {
  const ProfilePhotoScreen({super.key, required this.user, this.imageUrl});

  final User user;
  final String? imageUrl;

  @override
  State<ProfilePhotoScreen> createState() => _ProfilePhotoScreenState();
}

class _ProfilePhotoScreenState extends State<ProfilePhotoScreen> {
  static const _primaryBlue = Color(0xFF3D8FEF);
  static const _lightBlue = Color(0xFFEFF6FF);
  static const _secondaryBlue = Color(0xFFACD7FF);
  static const _textPrimary = Color(0xFF1E1E1E);
  static const _textSecondary = Color(0xFF6B7280);
  static const _borderColor = Color(0xFFE5E7EB);
  static const _danger = Color(0xFFEF4444);

  final _picker = ImagePicker();
  final _photoService = ProfilePhotoService();
  File? _selectedPhoto;
  bool _isUploading = false;

  Future<void> _pickPhoto(ImageSource source) async {
    if (_isUploading) return;
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (picked == null) return;

      final extension = picked.path.split('.').last.toLowerCase();
      if (!{'jpg', 'jpeg', 'png'}.contains(extension)) {
        _showSnackBar('Please select a JPG or PNG image.');
        return;
      }
      final file = File(picked.path);
      if (await file.length() > 5 * 1024 * 1024) {
        _showSnackBar('Image must be smaller than 5 MB.');
        return;
      }
      if (mounted) setState(() => _selectedPhoto = file);
    } catch (_) {
      _showSnackBar(
        source == ImageSource.camera
            ? 'Camera permission is required to take a photo.'
            : 'Unable to select a photo. Please try again.',
      );
    }
  }

  Future<void> _save() async {
    final image = _selectedPhoto;
    if (image == null) {
      _showSnackBar('Choose a photo before saving.');
      return;
    }
    setState(() => _isUploading = true);
    try {
      final url = await _photoService.uploadProfilePhoto(image);
      if (!mounted) return;
      Navigator.of(context).pop(ProfilePhotoResult(url));
    } on ProfilePhotoFailure catch (error) {
      _showSnackBar(error.message);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _removeCurrentPhoto() async {
    final hasCurrentPhoto = widget.imageUrl?.isNotEmpty == true;
    if (!hasCurrentPhoto) {
      _showSnackBar('There is no profile photo to remove.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Profile Photo?'),
        content: const Text(
          'Are you sure you want to remove your current profile photo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: _danger),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isUploading = true);
    try {
      await _photoService.removeProfilePhoto(widget.imageUrl);
      if (!mounted) return;
      Navigator.of(context).pop(const ProfilePhotoResult(null));
    } on ProfilePhotoFailure catch (error) {
      _showSnackBar(error.message);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedPhoto;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text(
          'Profile Photo',
          style: TextStyle(fontWeight: FontWeight.w800, color: _textPrimary),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PhotoAvatar(
                imageUrl: widget.imageUrl,
                localPhoto: selected,
                size: 120,
              ),
              const SizedBox(height: 26),
              const Text(
                'Update your profile photo',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose a clear photo so other learners can recognize you.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.45,
                  color: _textSecondary,
                ),
              ),
              const SizedBox(height: 28),
              _UploadArea(
                enabled: !_isUploading,
                onTap: () => _pickPhoto(ImageSource.gallery),
              ),
              const SizedBox(height: 18),
              _ActionCard(
                icon: Icons.camera_alt_outlined,
                title: 'Take Photo',
                subtitle: 'Use your camera',
                enabled: !_isUploading,
                onTap: () => _pickPhoto(ImageSource.camera),
              ),
              const SizedBox(height: 14),
              _ActionCard(
                icon: Icons.photo_library_outlined,
                title: 'Choose from Gallery',
                subtitle: 'Select a photo from your device',
                enabled: !_isUploading,
                onTap: () => _pickPhoto(ImageSource.gallery),
              ),
              const SizedBox(height: 14),
              _ActionCard(
                icon: Icons.delete_outline,
                title: 'Remove Current Photo',
                subtitle: 'Delete existing profile photo',
                iconColor: _danger,
                textColor: _danger,
                enabled: !_isUploading,
                onTap: _removeCurrentPhoto,
              ),
              if (selected != null) ...[
                const SizedBox(height: 26),
                const Text(
                  'Selected Photo Preview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                _PreviewCard(photo: selected),
              ],
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _isUploading ? null : _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: _primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: _isUploading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Save Profile Photo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              TextButton(
                onPressed: _isUploading
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
    );
  }
}

class _PhotoAvatar extends StatelessWidget {
  const _PhotoAvatar({
    required this.imageUrl,
    required this.localPhoto,
    required this.size,
  });

  final String? imageUrl;
  final File? localPhoto;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ImageProvider? image = localPhoto != null
        ? FileImage(localPhoto!)
        : imageUrl != null
        ? NetworkImage(imageUrl!)
        : null;
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipOval(
          child: image == null
              ? const ColoredBox(
                  color: _ProfilePhotoScreenState._lightBlue,
                  child: Center(
                    child: Icon(
                      Icons.person,
                      size: 62,
                      color: _ProfilePhotoScreenState._primaryBlue,
                    ),
                  ),
                )
              : Image(image: image, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

class _UploadArea extends StatelessWidget {
  const _UploadArea({required this.enabled, required this.onTap});
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 190,
        decoration: BoxDecoration(
          color: _ProfilePhotoScreenState._lightBlue,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _ProfilePhotoScreenState._secondaryBlue),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              color: _ProfilePhotoScreenState._primaryBlue,
              size: 54,
            ),
            SizedBox(height: 14),
            Text(
              'Upload a new photo',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6),
            Text(
              'JPG or PNG • Max 5 MB',
              style: TextStyle(
                fontSize: 16,
                color: _ProfilePhotoScreenState._textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
    this.iconColor = _ProfilePhotoScreenState._primaryBlue,
    this.textColor = _ProfilePhotoScreenState._textPrimary,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;
  final Color iconColor;
  final Color textColor;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _ProfilePhotoScreenState._borderColor),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor == _ProfilePhotoScreenState._danger
                    ? const Color(0xFFFFF1F2)
                    : _ProfilePhotoScreenState._lightBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 29),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 15,
                      color: _ProfilePhotoScreenState._textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: iconColor, size: 30),
          ],
        ),
      ),
    ),
  );
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.photo});
  final File photo;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(color: _ProfilePhotoScreenState._borderColor),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        _PhotoAvatar(imageUrl: null, localPhoto: photo, size: 94),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Adjust Photo',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 4),
              Text(
                'Crop and position your photo',
                style: TextStyle(
                  fontSize: 15,
                  color: _ProfilePhotoScreenState._textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
