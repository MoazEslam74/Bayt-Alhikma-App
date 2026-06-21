// lib/view_model/local_storage_services.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // Added for debugPrint
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart'; // Required for RSA

part 'local_storage_services.g.dart';

@HiveType(typeId: 0)
class UserProfile extends HiveObject {
  @HiveField(0)
  String uid;
  @HiveField(1)
  String firstname;
  @HiveField(2)
  String lastname;
  @HiveField(3)
  String username;
  @HiveField(4)
  String email;
  @HiveField(5)
  List<String> categories;
  @HiveField(6)
  List<String> favorites;
  @HiveField(7)
  String avatar;
  @HiveField(8)
  bool isSecure;

  UserProfile({
    required this.uid,
    required this.firstname,
    required this.lastname,
    required this.username,
    required this.email,
    required this.categories,
    List<String>? favorites,
    String? avatar,
    bool? isSecure,
  }) : favorites = favorites ?? [],
        avatar = avatar ?? '1.png',
        isSecure = isSecure ?? false;
}

class LocalStorageService {
  static const String boxName = 'userBox';
  static const String ratingsBoxName = 'ratingsBox';
  static const String playbackBoxName = 'playbackBox';
  static const String settingsBoxName = 'settingsBox';
  static const String pdfBoxName = 'pdfBox';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(UserProfileAdapter());

    // 1. Retrieve the RSA-Encrypted AES Key from Secure Storage and decrypt it
    final aesKey = await SecureStorageHelper.getDecryptedAESKey();

    // 2. Initialize Hive with the decrypted 32-byte AES Cipher
    final cipher = HiveAesCipher(aesKey);

    // 3. Open ALL boxes with the encryption cipher
    await Hive.openBox<UserProfile>(boxName, encryptionCipher: cipher);
    await Hive.openBox<int>(ratingsBoxName, encryptionCipher: cipher);
    await Hive.openBox<int>(playbackBoxName, encryptionCipher: cipher);
    await Hive.openBox(settingsBoxName, encryptionCipher: cipher);
    await Hive.openBox<int>(pdfBoxName, encryptionCipher: cipher);
  }

  // --- Methods for Data Access ---

  static Future<void> saveLanguage(String langCode) async {
    final box = Hive.box(settingsBoxName);
    await box.put('language_code', langCode);
  }

  static String getLanguage() {
    final box = Hive.box(settingsBoxName);
    return box.get('language_code') ?? 'en';
  }

  static Future<void> saveUserLocally(UserProfile profile) async {
    final box = Hive.box<UserProfile>(boxName);
    await box.put('profile', profile);
  }

  static UserProfile? getUserLocally() {
    final box = Hive.box<UserProfile>(boxName);
    return box.get('profile');
  }

  static Future<void> updateAvatarLocally(String newAvatar) async {
    final box = Hive.box<UserProfile>(boxName);
    final user = box.get('profile');
    if (user != null) {
      user.avatar = newAvatar;
      await user.save();
    }
  }

  static Future<void> updateSecureStatusLocally(bool isSecure) async {
    final box = Hive.box<UserProfile>(boxName);
    final user = box.get('profile');
    if (user != null) {
      user.isSecure = isSecure;
      await user.save();
    }
  }

  static Future<void> addFavoriteLocally(String bookId) async {
    final box = Hive.box<UserProfile>(boxName);
    final user = box.get('profile');
    if (user != null) {
      if (!user.favorites.contains(bookId)) {
        user.favorites.add(bookId);
        await user.save();
      }
    }
  }

  static Future<void> removeFavoriteLocally(String bookId) async {
    final box = Hive.box<UserProfile>(boxName);
    final user = box.get('profile');
    if (user != null) {
      user.favorites.remove(bookId);
      await user.save();
    }
  }

  static List<String> getFavoritesLocally() {
    final box = Hive.box<UserProfile>(boxName);
    final user = box.get('profile');
    return user?.favorites ?? [];
  }

  static Future<void> saveRating(String bookId, int rating) async {
    final box = Hive.box<int>(ratingsBoxName);
    await box.put(bookId, rating);
  }

  static Future<int?> getRating(String bookId) async {
    final box = Hive.box<int>(ratingsBoxName);
    return box.get(bookId);
  }

  static Future<void> savePlaybackPosition(String bookId, int positionMs) async {
    final box = Hive.box<int>(playbackBoxName);
    await box.put(bookId, positionMs);
  }

  static Future<int> getPlaybackPosition(String bookId) async {
    final box = Hive.box<int>(playbackBoxName);
    return box.get(bookId) ?? 0;
  }

  static Future<void> saveLastPlayedBookId(String id) async {
    final box = Hive.box(settingsBoxName);
    await box.put('lastPlayedId', id);
  }

  static String? getLastPlayedBookId() {
    final box = Hive.box(settingsBoxName);
    return box.get('lastPlayedId');
  }

  static Future<void> savePdfPage(String bookId, int pageNumber) async {
    final box = Hive.box<int>(pdfBoxName);
    await box.put(bookId, pageNumber);
  }

  static Future<int> getPdfPage(String bookId) async {
    final box = Hive.box<int>(pdfBoxName);
    return box.get(bookId) ?? 1;
  }

  static Future<void> clearUserData() async {
    final box = Hive.box<UserProfile>(boxName);
    await box.clear();
  }
}

/// Helper class to manage Hybrid RSA-AES Key protection
class SecureStorageHelper {
  static const _storage = FlutterSecureStorage();
  static const _aesKeyName = 'encrypted_aes_key';

  // Storage keys for RSA Private Key reconstruction
  static const _rsaModulus = 'rsa_modulus';
  static const _rsaExponent = 'rsa_exponent';
  static const _rsaP = 'rsa_p';
  static const _rsaQ = 'rsa_q';

  /// Decrypts the stored AES key using the RSA Private Key
  static Future<Uint8List> getDecryptedAESKey() async {
    try {
      final encryptedAesKeyBase64 = await _storage.read(key: _aesKeyName);
      final modulusStr = await _storage.read(key: _rsaModulus);

      // 1. If no keys exist, generate new ones
      if (encryptedAesKeyBase64 == null || modulusStr == null) {
        return await _generateAndStoreKeys();
      }

      // 2. Reconstruct RSA Private Key from Secure Storage
      final privateExponentStr = await _storage.read(key: _rsaExponent);
      final pStr = await _storage.read(key: _rsaP);
      final qStr = await _storage.read(key: _rsaQ);

      final rsaPrivateKey = RSAPrivateKey(
        BigInt.parse(modulusStr),
        BigInt.parse(privateExponentStr!),
        BigInt.parse(pStr!),
        BigInt.parse(qStr!),
      );

      // 3. Decrypt the AES Key using the reconstructed RSA Private Key
      final rsaEngine = PKCS1Encoding(RSAEngine())
        ..init(false, PrivateKeyParameter<RSAPrivateKey>(rsaPrivateKey));

      final encryptedBytes = base64Url.decode(encryptedAesKeyBase64);
      return rsaEngine.process(encryptedBytes);

    } catch (e) {
      // 🔴 AUTO-RECOVERY FIX: If keys are corrupted by a reinstall, catch the error,
      // wipe the broken storage, and safely generate fresh keys without crashing Hive.
      debugPrint('Encryption keys corrupted. Wiping and recreating... Error: $e');
      await _storage.deleteAll();
      return await _generateAndStoreKeys();
    }
  }

  static Future<Uint8List> _generateAndStoreKeys() async {
    final pair = _generateRSAKeyPair();
    final newAesKey = Hive.generateSecureKey();

    final rsaEngine = PKCS1Encoding(RSAEngine())
      ..init(true, PublicKeyParameter<RSAPublicKey>(pair.publicKey));
    final encryptedAesKey = rsaEngine.process(Uint8List.fromList(newAesKey));

    await _storage.write(key: _aesKeyName, value: base64UrlEncode(encryptedAesKey));
    await _storage.write(key: _rsaModulus, value: pair.privateKey.modulus.toString());
    await _storage.write(key: _rsaExponent, value: pair.privateKey.privateExponent.toString());
    await _storage.write(key: _rsaP, value: pair.privateKey.p.toString());
    await _storage.write(key: _rsaQ, value: pair.privateKey.q.toString());

    return Uint8List.fromList(newAesKey);
  }

  static AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> _generateRSAKeyPair() {
    final keyGen = RSAKeyGenerator()
      ..init(ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64),
        _getSecureRandom(),
      ));
    final pair = keyGen.generateKeyPair();
    return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(
      pair.publicKey as RSAPublicKey,
      pair.privateKey as RSAPrivateKey,
    );
  }

  static SecureRandom _getSecureRandom() {
    final secureRandom = FortunaRandom();

    // Generate a seed using the current time
    final seed = Uint8List.fromList(
      List.generate(32, (n) => DateTime.now().millisecondsSinceEpoch % 256),
    );

    secureRandom.seed(KeyParameter(seed));
    return secureRandom;
  }
}