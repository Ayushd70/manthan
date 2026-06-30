import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manthan/app/app.dart';
import 'package:manthan/core/providers.dart';
import 'package:manthan/data/local/object_box.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final objectBox = await ObjectBox.open();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        objectBoxProvider.overrideWithValue(objectBox),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const ManthanApp(),
    ),
  );
}
