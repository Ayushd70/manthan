import 'package:flutter_test/flutter_test.dart';
import 'package:manthan/data/local/field_cipher.dart';
import 'package:manthan/data/local/secure_key_store.dart';

void main() {
  group('AesFieldCipher', () {
    test('round-trips unicode text', () {
      final cipher = AesFieldCipher.random();
      const plain = 'Hello — 私密 chat 🔐';
      final sealed = cipher.encrypt(plain);

      expect(FieldCipher.isEncrypted(sealed), isTrue);
      expect(sealed, isNot(plain));
      expect(cipher.decrypt(sealed), plain);
    });

    test('is idempotent on already-encrypted input', () {
      final cipher = AesFieldCipher.random();
      final once = cipher.encrypt('secret');
      expect(cipher.encrypt(once), once);
    });

    test('dual-reads legacy plaintext', () {
      final cipher = AesFieldCipher.random();
      expect(cipher.decrypt('legacy plaintext'), 'legacy plaintext');
    });

    test('leaves empty strings untouched', () {
      final cipher = AesFieldCipher.random();
      expect(cipher.encrypt(''), '');
      expect(cipher.decrypt(''), '');
    });

    test('different keys cannot decrypt', () {
      final a = AesFieldCipher.random();
      final b = AesFieldCipher.random();
      final sealed = a.encrypt('top secret');
      expect(b.decrypt(sealed), '[unable to decrypt]');
    });
  });

  group('FieldCipherFactory', () {
    test('persists and reloads the DEK', () async {
      final store = MemorySecureKeyStore();
      final first = await FieldCipherFactory.open(store);
      final second = await FieldCipherFactory.open(store);

      final sealed = first.encrypt('persist me');
      expect(second.decrypt(sealed), 'persist me');
    });
  });

  group('PassthroughFieldCipher', () {
    test('returns values unchanged', () {
      const cipher = PassthroughFieldCipher();
      expect(cipher.encrypt('x'), 'x');
      expect(cipher.decrypt('y'), 'y');
    });
  });
}
