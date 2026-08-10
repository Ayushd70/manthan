import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// Encrypts/decrypts sensitive string fields for ObjectBox at-rest storage.
///
/// Wire format: `enc:v1:` + base64(nonce ‖ ciphertext ‖ tag) using AES-256-GCM.
/// Values without the prefix are treated as legacy plaintext (dual-read).
abstract interface class FieldCipher {
  /// Encrypts [plain], or returns it unchanged when empty / already encrypted.
  String encrypt(String plain);

  /// Decrypts [stored], or returns it unchanged when not encrypted.
  String decrypt(String stored);

  /// Encrypts a nullable field.
  String? encryptNullable(String? value);

  /// Decrypts a nullable field.
  String? decryptNullable(String? value);

  /// True when [value] uses the current ciphertext prefix.
  static bool isEncrypted(String value) =>
      value.startsWith(AesFieldCipher.prefix);
}

/// AES-256-GCM implementation of [FieldCipher].
class AesFieldCipher implements FieldCipher {
  /// Creates a cipher from a 32-byte DEK.
  AesFieldCipher(Uint8List keyBytes) : _key = Uint8List.fromList(keyBytes) {
    if (keyBytes.length != 32) {
      throw ArgumentError.value(
        keyBytes.length,
        'keyBytes.length',
        'AES-256 key must be 32 bytes',
      );
    }
  }

  /// Creates a cipher from a cryptographically random 32-byte DEK.
  factory AesFieldCipher.random({Random? random}) {
    return AesFieldCipher(generateKeyBytes(random: random));
  }

  /// Generates a fresh 32-byte AES-256 key.
  static Uint8List generateKeyBytes({Random? random}) {
    final rng = random ?? Random.secure();
    return Uint8List.fromList(List<int>.generate(32, (_) => rng.nextInt(256)));
  }

  /// Ciphertext prefix for versioned dual-read migration.
  static const prefix = 'enc:v1:';

  static const _nonceLength = 12;
  static const _macBitLength = 128;

  final Uint8List _key;

  @override
  String encrypt(String plain) {
    if (plain.isEmpty || FieldCipher.isEncrypted(plain)) return plain;

    final nonce = _randomBytes(_nonceLength);
    final input = Uint8List.fromList(utf8.encode(plain));
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true,
        AEADParameters(KeyParameter(_key), _macBitLength, nonce, Uint8List(0)),
      );
    final sealed = cipher.process(input);

    final packed = Uint8List(_nonceLength + sealed.length)
      ..setRange(0, _nonceLength, nonce)
      ..setRange(_nonceLength, _nonceLength + sealed.length, sealed);

    return '$prefix${base64Encode(packed)}';
  }

  @override
  String decrypt(String stored) {
    if (!FieldCipher.isEncrypted(stored)) return stored;

    try {
      final packed = base64Decode(stored.substring(prefix.length));
      if (packed.length <= _nonceLength) return stored;

      final nonce = Uint8List.fromList(packed.sublist(0, _nonceLength));
      final sealed = Uint8List.fromList(packed.sublist(_nonceLength));
      final cipher = GCMBlockCipher(AESEngine())
        ..init(
          false,
          AEADParameters(
            KeyParameter(_key),
            _macBitLength,
            nonce,
            Uint8List(0),
          ),
        );
      final plain = cipher.process(sealed);
      return utf8.decode(plain);
    } on Object {
      // Corrupt / wrong-key ciphertext: surface a safe placeholder rather than
      // crashing the whole app on launch.
      return '[unable to decrypt]';
    }
  }

  @override
  String? encryptNullable(String? value) =>
      value == null ? null : encrypt(value);

  @override
  String? decryptNullable(String? value) =>
      value == null ? null : decrypt(value);

  static Uint8List _randomBytes(int length) {
    final rng = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => rng.nextInt(256)),
    );
  }
}

/// No-op cipher used in tests that do not exercise encryption.
class PassthroughFieldCipher implements FieldCipher {
  const PassthroughFieldCipher();

  @override
  String encrypt(String plain) => plain;

  @override
  String decrypt(String stored) => stored;

  @override
  String? encryptNullable(String? value) => value;

  @override
  String? decryptNullable(String? value) => value;
}
