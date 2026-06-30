import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manthan/app/router.dart';
import 'package:manthan/core/constants/app_info.dart';
import 'package:manthan/core/theme/app_theme.dart';
import 'package:manthan/features/settings/application/settings_controller.dart';

/// Root widget: wires theming (with dynamic color), routing, and settings.
class ManthanApp extends ConsumerWidget {
  const ManthanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final useDynamic = settings.useDynamicColor;
        return MaterialApp.router(
          title: AppInfo.name,
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          theme: AppTheme.build(
            Brightness.light,
            useDynamic ? lightDynamic?.harmonized() : null,
          ),
          darkTheme: AppTheme.build(
            Brightness.dark,
            useDynamic ? darkDynamic?.harmonized() : null,
          ),
          routerConfig: appRouter,
        );
      },
    );
  }
}
