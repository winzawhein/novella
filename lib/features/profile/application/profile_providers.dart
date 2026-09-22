import 'dart:io';

import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final readerProfileProvider =
    StateNotifierProvider<ReaderProfileController, ReaderProfile>(
      (ref) => ReaderProfileController(),
    );

class ReaderProfile {
  const ReaderProfile({required this.name, this.photoPath});

  final String name;
  final String? photoPath;
}

class ReaderProfileController extends StateNotifier<ReaderProfile> {
  ReaderProfileController() : super(const ReaderProfile(name: 'Timmy')) {
    _restore();
  }

  static const _nameKey = 'profile_name';
  static const _photoKey = 'profile_photo_path';

  Future<void> _restore() async {
    final preferences = await SharedPreferences.getInstance();
    final photoPath = preferences.getString(_photoKey);
    state = ReaderProfile(
      name: preferences.getString(_nameKey) ?? 'Timmy',
      photoPath: photoPath != null && File(photoPath).existsSync()
          ? photoPath
          : null,
    );
  }

  Future<void> updateName(String value) async {
    final name = value.trim();
    if (name.isEmpty) return;
    state = ReaderProfile(name: name, photoPath: state.photoPath);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_nameKey, name);
  }

  Future<bool> choosePhoto() async {
    final selected = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 960,
    );
    if (selected == null) return false;

    final directory = await getApplicationDocumentsDirectory();
    final extension = selected.path.contains('.')
        ? selected.path.substring(selected.path.lastIndexOf('.'))
        : '.jpg';
    final destination = File('${directory.path}/novella-profile$extension');
    await File(selected.path).copy(destination.path);
    state = ReaderProfile(name: state.name, photoPath: destination.path);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_photoKey, destination.path);
    return true;
  }
}
