import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manthan/app/app.dart';
import 'package:manthan/core/providers.dart';
import 'package:manthan/data/local/object_box.dart';
import 'package:manthan/data/local/secure_key_store.dart';
import 'package:manthan/data/local/storage_encryption_migrator.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final objectBox = await ObjectBox.open();
  final prefs = await SharedPreferences.getInstance();
  final keyStore = FlutterSecureKeyStore();
  final cipher = await FieldCipherFactory.open(keyStore);

  await StorageEncryptionMigrator.migrateIfNeeded(
    prefs: prefs,
    store: objectBox.store,
    cipher: cipher,
  );

  runApp(
    ProviderScope(
      overrides: [
        objectBoxProvider.overrideWithValue(objectBox),
        sharedPreferencesProvider.overrideWithValue(prefs),
        secureKeyStoreProvider.overrideWithValue(keyStore),
        fieldCipherProvider.overrideWithValue(cipher),
      ],
      child: const ManthanApp(),
    ),
  );
}
