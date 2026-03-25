import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/pointycastle.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/gcm.dart';

import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/digests/sha256.dart';

/// AES-GCM encryption with proper PBKDF2 key derivation.
/// Fixes from audit: uses salt, 600k iterations, proper IV handling.
class CryptoUtils {
  static const int _saltLength = 32;
  static const int _ivLength = 12;
  static const int _keyLength = 32; // 256-bit
  static const int _pbkdf2Iterations = 600000; // OWASP 2023 recommendation

  static Uint8List _secureRandom(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(length, (_) => random.nextInt(256)),
    );
  }

  static Uint8List _deriveKey(String password, Uint8List salt) {
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, _pbkdf2Iterations, _keyLength));
    return pbkdf2.process(Uint8List.fromList(utf8.encode(password)));
  }

  /// Encrypt data with AES-256-GCM using PBKDF2-derived key.
  /// Output format: [salt (32 bytes)] [iv (12 bytes)] [ciphertext + tag]
  static Future<String> encrypt(String plaintext, String password) async {
    final salt = _secureRandom(_saltLength);
    final iv = _secureRandom(_ivLength);
    final key = _deriveKey(password, salt);

    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true,
        AEADParameters(
          KeyParameter(key),
          128, // tag length in bits
          iv,
          Uint8List(0),
        ),
      );

    final plainBytes = Uint8List.fromList(utf8.encode(plaintext));
    final cipherBytes = cipher.process(plainBytes);

    // Combine: salt + iv + ciphertext
    final combined = Uint8List(salt.length + iv.length + cipherBytes.length);
    combined.setAll(0, salt);
    combined.setAll(salt.length, iv);
    combined.setAll(salt.length + iv.length, cipherBytes);

    return base64Encode(combined);
  }

  /// Decrypt data encrypted with [encrypt].
  static Future<String> decrypt(
    String encryptedBase64,
    String password,
  ) async {
    final combined = base64Decode(encryptedBase64);

    final salt = Uint8List.sublistView(combined, 0, _saltLength);
    final iv = Uint8List.sublistView(
      combined,
      _saltLength,
      _saltLength + _ivLength,
    );
    final cipherBytes = Uint8List.sublistView(
      combined,
      _saltLength + _ivLength,
    );

    final key = _deriveKey(password, salt);

    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        false,
        AEADParameters(
          KeyParameter(key),
          128,
          iv,
          Uint8List(0),
        ),
      );

    final plainBytes = cipher.process(cipherBytes);
    return utf8.decode(plainBytes);
  }
}
