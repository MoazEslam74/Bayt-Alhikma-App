import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:bayt_alhikma/view_model/local_storage_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_favs');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserProfileAdapter());
    }
    await Hive.openBox<UserProfile>(LocalStorageService.boxName);
    await Hive.openBox<int>(LocalStorageService.ratingsBoxName);
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  test(
    'addFavoriteLocally and removeFavoriteLocally work and getFavoritesLocally reflects changes',
    () async {
      const uid = 'user-1';
      final profile = UserProfile(
        uid: uid,
        firstname: 'First',
        lastname: 'Last',
        username: 'user1',
        email: 'u@example.com',
        categories: <String>[],
        favorites: <String>[],
      );

      // save user locally
      await LocalStorageService.saveUserLocally(profile);

      // add favorite
      const bookId = 'fav-book-1';
      await LocalStorageService.addFavoriteLocally(bookId);
      var favs = LocalStorageService.getFavoritesLocally();
      expect(favs, contains(bookId));

      // remove favorite
      await LocalStorageService.removeFavoriteLocally(bookId);
      favs = LocalStorageService.getFavoritesLocally();
      expect(favs, isNot(contains(bookId)));
    },
  );
}
