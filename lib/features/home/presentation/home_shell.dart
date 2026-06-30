import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:manthan/app/router.dart';

/// Persistent shell hosting the primary navigation destinations.
class HomeShell extends StatelessWidget {
  const HomeShell({required this.child, super.key});

  /// The currently routed page.
  final Widget child;

  static const _destinations = <_Destination>[
    _Destination(
      Routes.chat,
      'Chat',
      Icons.chat_bubble_outline,
      Icons.chat_bubble,
    ),
    _Destination(Routes.models, 'Models', Icons.dns_outlined, Icons.dns),
    _Destination(
      Routes.documents,
      'Docs',
      Icons.description_outlined,
      Icons.description,
    ),
    _Destination(
      Routes.settings,
      'Settings',
      Icons.settings_outlined,
      Icons.settings,
    ),
  ];

  int _indexFor(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index = _destinations.indexWhere((d) => d.route == location);
    return index < 0 ? 0 : index;
  }

  void _onSelect(BuildContext context, int index) {
    context.go(_destinations[index].route);
  }

  @override
  Widget build(BuildContext context) {
    final index = _indexFor(context);
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: <Widget>[
            NavigationRail(
              selectedIndex: index,
              onDestinationSelected: (i) => _onSelect(context, i),
              labelType: NavigationRailLabelType.all,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: _Logo(),
              ),
              destinations: <NavigationRailDestination>[
                for (final d in _destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => _onSelect(context, i),
        destinations: <NavigationDestination>[
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Column(
      children: <Widget>[
        Icon(Icons.blur_on, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          'Manthan',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _Destination {
  const _Destination(this.route, this.label, this.icon, this.selectedIcon);
  final String route;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
