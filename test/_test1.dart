import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:bayt_alhikma/view_model/local_storage_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_save_rating');
    Hive.init(tempDir.path);
    // register adapter from your generated part
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

  test('saveRating stores rating and getRating returns it', () async {
    const bookId = 'book-123';
    const rating = 4;

    await LocalStorageService.saveRating(bookId, rating);
    final loaded = await LocalStorageService.getRating(bookId);

    expect(loaded, equals(rating));
  });
}
