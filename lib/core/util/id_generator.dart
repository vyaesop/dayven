import 'dart:math';

/// Generates client-side identifiers for planner entities.
///
/// In the cloud-only, offline-first model the client owns the primary key for
/// every event and calendar it creates. This lets a create performed while
/// offline carry a stable id that the backend later accepts via an idempotent
/// upsert — no server round-trip is needed to mint the id, and replaying a
/// queued create is naturally idempotent.
class IdGenerator {
  IdGenerator._();

  static final Random _random = Random.secure();

  /// Returns an RFC 4122 version-4 UUID string.
  static String uuidV4() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    // Set the version (4) and variant (10xx) bits.
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String hex(int start, int end) {
      final buffer = StringBuffer();
      for (var i = start; i < end; i++) {
        buffer.write(bytes[i].toRadixString(16).padLeft(2, '0'));
      }
      return buffer.toString();
    }

    return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  }
}
