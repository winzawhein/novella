import 'package:flutter_riverpod/legacy.dart';

final readerProgressProvider = StateProvider<double>((ref) => .38);
final readerSettingsOpenProvider = StateProvider<bool>((ref) => false);
final readerDarkModeProvider = StateProvider<bool>((ref) => false);
