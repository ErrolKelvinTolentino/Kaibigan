import 'dart:math';

class UuidUtil {
  static final Random _random = Random.secure();

  /// Generates a standard RFC 4122 v4 UUID string (e.g. 123e4567-e89b-12d3-a456-426614174000)
  static String generate() {
    final values = List<int>.generate(16, (i) => _random.nextInt(256));

    // Set version to 4 (bits 4-7 of time_hi_and_version to 0100)
    values[6] = (values[6] & 0x0f) | 0x40;
    // Set variant to IETF (bits 6-7 of clock_seq_hi_and_reserved to 10)
    values[8] = (values[8] & 0x3f) | 0x80;

    return '${_toHex(values.sublist(0, 4))}-'
        '${_toHex(values.sublist(4, 6))}-'
        '${_toHex(values.sublist(6, 8))}-'
        '${_toHex(values.sublist(8, 10))}-'
        '${_toHex(values.sublist(10, 16))}';
  }

  static String _toHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
