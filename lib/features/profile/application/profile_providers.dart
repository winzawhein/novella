import 'dart:io';

import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/auth_screen.dart';

final readerProfileProvider =
    StateNotifierProvider<ReaderProfileController, ReaderProfile>((ref) {
      ref.watch(authStateProvider);
      return ReaderProfileController(Supabase.instance.client.auth.currentUser);
    });

class ReaderProfile {
  const ReaderProfile({required this.name, this.photoPath});

  final String name;
  final String? photoPath;
}

class ReaderProfileController extends StateNotifier<ReaderProfile> {
  ReaderProfileController(this.user)
    : super(ReaderProfile(name: _accountName(user))) {
    _restore();
  }

  final User? user;
  String get _photoKey => 'profile_photo_path_${user?.id ?? "guest"}';

  static String _accountName(User? user) {
    if (user == null || user.isAnonymous) return 'Guest';
    for (final key in ['display_name', 'full_name', 'name']) {
      final value = user.userMetadata?[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    final email = user.email;
    if (email != null && email.isNotEmpty) return email.split('@').first;
    final phone = user.phone;
    return phone != null && phone.isNotEmpty ? phone : 'Reader';
  }

  Future<void> _restore() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    final photoPath = preferences.getString(_photoKey);
    state = ReaderProfile(
      name: state.name,
      photoPath: photoPath != null && File(photoPath).existsSync()
          ? photoPath
          : null,
    );
  }

  Future<void> updateName(String value) async {
    final name = value.trim();
    if (name.isEmpty) return;
    if (user == null || user!.isAnonymous) return;
    await Supabase.instance.client.auth.updateUser(
      UserAttributes(data: {'display_name': name}),
    );
    if (mounted) state = ReaderProfile(name: name, photoPath: state.photoPath);
  }

  Future<bool> choosePhoto() async {
    final selected = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 960,
    );
    if (selected == null || !mounted) return false;

    final directory = await getApplicationDocumentsDirectory();
    final extension = selected.path.contains('.')
        ? selected.path.substring(selected.path.lastIndexOf('.'))
        : '.jpg';
    final destination = File(
      '${directory.path}/novella-profile-${user?.id ?? "guest"}$extension',
    );
    await File(selected.path).copy(destination.path);
    if (mounted) {
      state = ReaderProfile(name: state.name, photoPath: destination.path);
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_photoKey, destination.path);
    return true;
  }
}
