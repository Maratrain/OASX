import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/config/theme.dart';
import 'package:oasx/modules/common/widgets/appbar.dart';
import 'package:oasx/modules/home/index.dart';
import 'package:oasx/modules/home/models/home_workbench_layout.dart';
import 'package:oasx/modules/settings/index.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/utils/check_version.dart';

const double kPrimaryNavigationRailWidth = 76;

class PrimaryNavigationShell extends StatefulWidget {
  const PrimaryNavigationShell({
    super.key,
    required this.initialRoutePath,
  });

  final String initialRoutePath;

  @override
  State<PrimaryNavigationShell> createState() => _PrimaryNavigationShellState();
}

class _PrimaryNavigationShellState extends State<PrimaryNavigationShell> {
  late String _routePath;
  late final Set<int> _builtIndexes;

  @override
  void initState() {
    super.initState();
    _routePath = _normalizeRoutePath(widget.initialRoutePath);
    _builtIndexes = <int>{_selectedIndexForRoute(_routePath)};
  }

  @override
  void didUpdateWidget(covariant PrimaryNavigationShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextRoutePath = _normalizeRoutePath(widget.initialRoutePath);
    if (nextRoutePath == _routePath) {
      return;
    }
    final previousRoutePath = _routePath;
    _routePath = nextRoutePath;
    _builtIndexes.add(_selectedIndexForRoute(nextRoutePath));
    _handleRouteExit(previousRoutePath, nextRoutePath);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final selectedIndex = _selectedIndexForRoute(_routePath);
        final showRail = _shouldShowRail(constraints.maxWidth);
        final content = _PrimaryNavigationContent(
          selectedIndex: selectedIndex,
          builtIndexes: _builtIndexes,
        );
        return MistBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: buildPlatformAppBar(context, routePath: _routePath),
            resizeToAvoidBottomInset: false,
            body: showRail
                ? Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(9, 14, 0, 12),
                        child: _PrimaryNavigationRail(
                          selectedIndex: selectedIndex,
                          onSelected: _handleDestinationSelected,
                        ),
                      ),
                      Expanded(child: content),
                    ],
                  )
                : content,
            bottomNavigationBar: showRail
                ? null
                : NavigationBar(
                    selectedIndex: selectedIndex,
                    onDestinationSelected: _handleDestinationSelected,
                    destinations: _destinations(),
                  ),
          ),
        );
      },
    );
  }

  bool _shouldShowRail(double maxWidth) {
    const twoPaneShellWidth = kHomeWorkbenchMinCollectionWidth +
        kHomeWorkbenchMinDetailsWidth +
        kHomeWorkbenchDividerWidth +
        kPrimaryNavigationRailWidth;
    return maxWidth >= twoPaneShellWidth;
  }

  String _normalizeRoutePath(String value) {
    return value == '/settings' ? '/settings' : '/home';
  }

  int _selectedIndexForRoute(String value) {
    return value == '/settings' ? 1 : 0;
  }

  String _routePathForIndex(int index) {
    return index == 1 ? '/settings' : '/home';
  }

  void _handleDestinationSelected(int index) {
    final nextRoutePath = _routePathForIndex(index);
    if (nextRoutePath == _routePath) {
      return;
    }
    final previousRoutePath = _routePath;
    setState(() {
      _routePath = nextRoutePath;
      _builtIndexes.add(index);
    });
    _handleRouteExit(previousRoutePath, nextRoutePath);
  }

  void _handleRouteExit(String previousRoutePath, String nextRoutePath) {
    if (previousRoutePath == '/settings' && nextRoutePath != '/settings') {
      unawaited(handleSettingsLeaveEffect());
    }
  }

  List<Widget> _destinations() {
    return [
      NavigationDestination(
        icon: const Icon(Icons.home_rounded),
        label: I18n.home.tr,
      ),
      NavigationDestination(
        icon: const Icon(Icons.settings_rounded),
        label: I18n.setting.tr,
      ),
    ];
  }
}

class _PrimaryNavigationContent extends StatelessWidget {
  const _PrimaryNavigationContent({
    required this.selectedIndex,
    required this.builtIndexes,
  });

  final int selectedIndex;
  final Set<int> builtIndexes;

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: selectedIndex,
      children: [
        builtIndexes.contains(0)
            ? const HomeView(standalone: false)
            : const SizedBox.shrink(),
        builtIndexes.contains(1)
            ? const SettingsView(standalone: false)
            : const SizedBox.shrink(),
      ],
    );
  }
}

/// 设计稿 B 的窄浮动玻璃导航卡：竖排图标+文字，选中为靛紫渐变胶囊。
class _PrimaryNavigationRail extends StatelessWidget {
  const _PrimaryNavigationRail({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 58,
      decoration: BoxDecoration(
        color: isDark ? MistPalette.darkGlass : MistPalette.lightGlass,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? MistPalette.darkGlassBorder
              : MistPalette.lightGlassBorder,
        ),
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x213C5064),
                  blurRadius: 34,
                  offset: Offset(0, 10),
                ),
              ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          _RailItem(
            icon: Icons.home_rounded,
            label: I18n.home.tr,
            selected: selectedIndex == 0,
            isDark: isDark,
            onTap: () => onSelected(0),
          ),
          const SizedBox(height: 6),
          _RailItem(
            icon: Icons.settings_rounded,
            label: I18n.setting.tr,
            selected: selectedIndex == 1,
            isDark: isDark,
            onTap: () => onSelected(1),
          ),
          const Spacer(),
          _RailItem(
            icon: Icons.refresh_rounded,
            label: I18n.mistUpdate.tr,
            selected: false,
            isDark: isDark,
            onTap: () => unawaited(
              checkUpdate(showTip: true),
            ),
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Colors.white
        : (isDark ? const Color(0xFF8A93AB) : const Color(0xFF9AA3B8));
    return SizedBox(
      width: 46,
      height: 50,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: selected
              ? MistDecor.accentCapsule(radius: 13)
              : BoxDecoration(borderRadius: BorderRadius.circular(13)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
