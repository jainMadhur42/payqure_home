import 'dart:math';

abstract final class IdGenerator {
  static final Random _random = Random.secure();

  static String create(String prefix) {
    final now = DateTime.now().microsecondsSinceEpoch;
    final suffix = List.generate(
      8,
      (_) => _random.nextInt(16).toRadixString(16),
    ).join();
    return '${prefix}_${now}_$suffix';
  }
}
