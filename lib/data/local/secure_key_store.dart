import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:manthan/data/local/field_cipher.dart';

/// Abstraction over a small key/value secret store (DEK, tokens, …).
abstract interface class SecureKeyStore {
  /// Reads [key], or null when missing.
  Future<String?> read(String key);

  /// Writes [value] under [key].
  Future<void> write(String key, String value);

  /// Deletes [key] if present.
  Future<void> delete(String key);
}

/// [FlutterSecureStorage]-backed [SecureKeyStore].
class FlutterSecureKeyStore implements SecureKeyStore {
  FlutterSecureKeyStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// In-memory [SecureKeyStore] for unit tests.
class MemorySecureKeyStore implements SecureKeyStore {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);
}

/// Loads or creates the AES-256 data-encryption key and returns a [FieldCipher].
abstract final class FieldCipherFactory {
  /// Secure-storage key for the base64-encoded 32-byte DEK.
  static const dekStorageKey = 'manthan.dek.v1';

  /// Returns an [AesFieldCipher] backed by a DEK in [store].
  static Future<FieldCipher> open(SecureKeyStore store) async {
    final existing = await store.read(dekStorageKey);
    if (existing != null && existing.isNotEmpty) {
      return AesFieldCipher(Uint8List.fromList(base64Decode(existing)));
    }

    final keyBytes = AesFieldCipher.generateKeyBytes();
    await store.write(dekStorageKey, base64Encode(keyBytes));
    return AesFieldCipher(keyBytes);
  }
}
