import 'package:manthan/objectbox.g.dart';

/// Thin wrapper that owns the application's ObjectBox [Store].
///
/// Opened once during startup and shared via Riverpod. Keeping it in one place
/// makes it trivial to override with a temporary store in integration tests.
class ObjectBox {
  ObjectBox._(this.store);

  /// The underlying ObjectBox store.
  final Store store;

  /// Opens the store, optionally at a custom [directory] (used by tests).
  static Future<ObjectBox> open({String? directory}) async {
    final store = await openStore(directory: directory);
    return ObjectBox._(store);
  }

  /// Closes the store and releases native resources.
  void close() => store.close();
}
