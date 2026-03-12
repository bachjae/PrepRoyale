import 'dart:io' show File;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
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

  // Pick image from gallery — returns XFile (cross-platform, works on web)
  Future<XFile?> pickFromGallery() async {
    return await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
  }

  // Pick image from camera — returns XFile (cross-platform, works on web)
  Future<XFile?> pickFromCamera() async {
    return await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
  }

  // Upload profile picture and get download URL
  Future<String> uploadProfilePicture({
    required String userId,
    required XFile imageFile,
  }) async {
    try {
      final uuid = const Uuid().v4();
      final ref = _storage.ref().child('profile_pictures/$userId/$uuid.jpg');
      final metadata = SettableMetadata(contentType: 'image/jpeg');

      // Web uses putData(bytes); native platforms use putFile for efficiency
      final TaskSnapshot snapshot;
      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        snapshot = await ref.putData(bytes, metadata);
      } else {
        snapshot = await ref.putFile(File(imageFile.path), metadata);
      }

      // Verify upload completed successfully
      if (snapshot.state != TaskState.success) {
        throw Exception('Upload failed with state: ${snapshot.state}');
      }

      // Get download URL
      final downloadURL = await ref.getDownloadURL();

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
