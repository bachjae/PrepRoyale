import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Preset avatar URLs (using placeholder images)
  static const List<String> presetAvatars = [
    'https://api.dicebear.com/7.x/avataaars/png?seed=student1',
    'https://api.dicebear.com/7.x/avataaars/png?seed=student2',
    'https://api.dicebear.com/7.x/avataaars/png?seed=student3',
    'https://api.dicebear.com/7.x/avataaars/png?seed=student4',
    'https://api.dicebear.com/7.x/avataaars/png?seed=student5',
    'https://api.dicebear.com/7.x/avataaars/png?seed=student6',
    'https://api.dicebear.com/7.x/avataaars/png?seed=student7',
    'https://api.dicebear.com/7.x/avataaars/png?seed=student8',
    'https://api.dicebear.com/7.x/avataaars/png?seed=student9',
    'https://api.dicebear.com/7.x/avataaars/png?seed=student10',
  ];

  // Pick image from gallery
  Future<File?> pickFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (image == null) return null;
    return File(image.path);
  }

  // Pick image from camera
  Future<File?> pickFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (image == null) return null;
    return File(image.path);
  }

  // Upload profile picture and get download URL
  Future<String> uploadProfilePicture({
    required String userId,
    required File imageFile,
  }) async {
    try {
      final uuid = const Uuid().v4();
      final ref = _storage.ref().child('profile_pictures/$userId/$uuid.jpg');

      // Upload the file
      final uploadTask = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Verify upload completed successfully
      if (uploadTask.state != TaskState.success) {
        throw Exception('Upload failed with state: ${uploadTask.state}');
      }

      // Get download URL
      final downloadURL = await ref.getDownloadURL();

      // Verify the download URL is not empty
      if (downloadURL.isEmpty) {
        throw Exception('Failed to get download URL after upload');
      }

      return downloadURL;
    } catch (e) {
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  // Delete old profile picture
  Future<void> deleteProfilePicture(String url) async {
    try {
      // Only delete if it's a Firebase Storage URL (not a preset)
      if (url.contains('firebasestorage')) {
        final ref = _storage.refFromURL(url);
        await ref.delete();
      }
    } catch (e) {
      // Ignore errors if file doesn't exist
    }
  }
}
