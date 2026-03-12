import 'dart:io' show File;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/router.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../../services/storage_service.dart';

class ProfilePictureSelector extends ConsumerStatefulWidget {
  final bool isNewUser;

  const ProfilePictureSelector({
    super.key,
    this.isNewUser = false,
  });

  @override
  ConsumerState<ProfilePictureSelector> createState() => _ProfilePictureSelectorState();
}

class _ProfilePictureSelectorState extends ConsumerState<ProfilePictureSelector> {
  String? _selectedPreset;
  XFile? _selectedFile; // XFile is cross-platform (works on web + mobile)
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Avatar'),
        leading: widget.isNewUser
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
        actions: [
          if (widget.isNewUser)
            TextButton(
              onPressed: () => _saveAndContinue(skip: true),
              child: const Text('Skip'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Selected preview
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryColor,
                        width: 3,
                      ),
                    ),
                    child: ClipOval(
                      child: _buildSelectedImage(),
                    ),
                  ),
                  if (_selectedPreset != null || _selectedFile != null)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.successColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Upload custom image
            Text(
              'Upload Your Own',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _CustomUploadButton(
                    icon: Icons.photo_library_outlined,
                    label: 'Gallery',
                    onTap: _pickFromGallery,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CustomUploadButton(
                    icon: Icons.camera_alt_outlined,
                    label: 'Camera',
                    onTap: _pickFromCamera,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Preset avatars
            Text(
              'Or Choose a Preset',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: StorageService.presetAvatars.length,
              itemBuilder: (context, index) {
                final preset = StorageService.presetAvatars[index];
                final isSelected = _selectedPreset == preset && _selectedFile == null;

                return GestureDetector(
                  onTap: () => _selectPreset(preset),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: preset,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppTheme.backgroundColor,
                          child: const Icon(Icons.person, color: AppTheme.textTertiary),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppTheme.backgroundColor,
                          child: const Icon(Icons.person, color: AppTheme.textTertiary),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: (_selectedPreset != null || _selectedFile != null) && !_isLoading
                    ? _saveAndContinue
                    : null,
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.isNewUser ? 'Continue' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedImage() {
    if (_selectedFile != null) {
      // Web: XFile.path is a blob URL — use Image.network
      // Native: XFile.path is a file system path — use Image.file
      if (kIsWeb) {
        return Image.network(_selectedFile!.path, fit: BoxFit.cover);
      } else {
        return Image.file(File(_selectedFile!.path), fit: BoxFit.cover);
      }
    } else if (_selectedPreset != null) {
      return CachedNetworkImage(
        imageUrl: _selectedPreset!,
        fit: BoxFit.cover,
        placeholder: (_, __) => const Icon(Icons.person, size: 48),
        errorWidget: (_, __, ___) => const Icon(Icons.person, size: 48),
      );
    } else {
      return const Icon(Icons.person, size: 48, color: AppTheme.textTertiary);
    }
  }

  void _selectPreset(String preset) {
    setState(() {
      _selectedPreset = preset;
      _selectedFile = null;
    });
  }

  Future<void> _pickFromGallery() async {
    final storageService = ref.read(storageServiceProvider);
    final file = await storageService.pickFromGallery();
    if (file != null) {
      setState(() {
        _selectedFile = file;
        _selectedPreset = null;
      });
    }
  }

  Future<void> _pickFromCamera() async {
    final storageService = ref.read(storageServiceProvider);
    final file = await storageService.pickFromCamera();
    if (file != null) {
      setState(() {
        _selectedFile = file;
        _selectedPreset = null;
      });
    }
  }

  Future<void> _saveAndContinue({bool skip = false}) async {
    if (skip) {
      context.go(Routes.home);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) {
        throw Exception('User ID not found. Please log in again.');
      }

      String? imageUrl;

      if (_selectedFile != null) {
        // Upload custom image
        final storageService = ref.read(storageServiceProvider);
        try {
          imageUrl = await storageService.uploadProfilePicture(
            userId: userId,
            imageFile: _selectedFile!,
          );
          if (imageUrl.isEmpty) {
            throw Exception('Upload succeeded but got empty URL');
          }
        } catch (uploadError) {
          throw Exception('Failed to upload image: $uploadError');
        }
      } else if (_selectedPreset != null) {
        imageUrl = _selectedPreset;
      }

      if (imageUrl != null && imageUrl.isNotEmpty) {
        final firebaseService = ref.read(firebaseServiceProvider);
        await firebaseService.updateUserProfile(
          userId: userId,
          profilePictureUrl: imageUrl,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture saved successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }

      if (!mounted) return;
      context.go(Routes.home);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save profile picture: $e'),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _CustomUploadButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CustomUploadButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, size: 32, color: AppTheme.primaryColor),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
