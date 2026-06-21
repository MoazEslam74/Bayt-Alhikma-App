import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:bayt_alhikma/view_model/local_storage_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_get_rating');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserProfileAdapter());
    }
    await Hive.openBox<int>(LocalStorageService.ratingsBoxName);
    await Hive.openBox<UserProfile>(LocalStorageService.boxName);
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  test('getRating returns null when no rating saved', () async {
    const unknownId = 'unknown-book-999';
    final loaded = await LocalStorageService.getRating(unknownId);
    expect(loaded, isNull);
  });
}
