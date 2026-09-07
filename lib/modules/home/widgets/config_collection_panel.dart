import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/common/models/config_drag_payload.dart';
import 'package:oasx/config/theme.dart';
import 'package:oasx/modules/common/widgets/mist_glass.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/models/config_model.dart';
import 'package:oasx/modules/home/widgets/config_collection_tile.dart';
import 'package:oasx/translation/i18n_content.dart';

class ConfigCollectionPanel extends StatefulWidget {
  static const _visibleStateFilters = [
    HomeScriptStateFilter.all,
    HomeScriptStateFilter.running,
    HomeScriptStateFilter.stopped,
    HomeScriptStateFilter.abnormal,
  ];

  const ConfigCollectionPanel({
    super.key,
    required this.controller,
    required this.fillHeight,
    required this.loadingAddScript,
    required this.refreshingScripts,
    required this.onAddScriptTap,
    required this.onRefreshScriptsTap,
    required this.onActivateScript,
    required this.onTogglePower,
    required this.onRenameScript,
    required this.onExportScript,
    required this.onDeleteScript,
  });

  final HomeDashboardController controller;
  final bool fillHeight;
  final bool loadingAddScript;
  final bool refreshingScripts;
  final VoidCallback onAddScriptTap;
  final VoidCallback onRefreshScriptsTap;
  final Future<void> Function(String scriptName) onActivateScript;
  final Future<void> Function(String scriptName, bool enable) onTogglePower;
  final Future<void> Function(String scriptName) onRenameScript;
  final Future<void> Function(String scriptName) onExportScript;
  final Future<void> Function(String scriptName) onDeleteScript;

  @override
  State<ConfigCollectionPanel> createState() => _ConfigCollectionPanelState();
}

class _ConfigCollectionPanelState extends State<ConfigCollectionPanel> {
  static const _autoScrollEdgeExtent = 56.0;
  static const _autoScrollStep = 10.0;

  /// Controller reused when the compact search field is visible.
  late final TextEditingController _searchController;
  final ScrollController _listScrollController = ScrollController();
  final GlobalKey _listViewportKey = GlobalKey();
  Timer? _autoScrollTimer;
  double _autoScrollDirection = 0;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.controller.searchQuery.value,
    );
  }

  @override
  void dispose() {
    _stopAutoScroll();
    _searchController.dispose();
    _listScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
        child: Obx(() {
          final activeDragPayload = widget.controller.activeDragPayload.value;
          if (activeDragPayload == null) {
            _stopAutoScroll();
          }
          final scripts = widget.controller.visibleScripts;
          final hasConfigs = widget.controller.orderedScripts.isNotEmpty;
          final searchValue = widget.controller.searchQuery.value;
          if (_searchController.text != searchValue) {
            _searchController.value = TextEditingValue(
              text: searchValue,
              selection: TextSelection.collapsed(offset: searchValue.length),
            );
          }
          final listView = DragTarget<ConfigDragPayload>(
            onWillAcceptWithDetails: (_) => true,
            onMove: (details) => _handleDragMove(details.offset),
            onLeave: (_) => _stopAutoScroll(),
            builder: (context, _, __) => SizedBox.expand(
              key: _listViewportKey,
              child: ListView.separated(
                controller: _listScrollController,
                itemCount: scripts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 7),
                padding: const EdgeInsets.only(bottom: 10),
                itemBuilder: (context, index) =>
                    _buildDropTargetTile(context, scripts[index]),
              ),
            ),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 9),
              _buildSearchField(context),
              const SizedBox(height: 9),
              _buildFilterChips(context),
              const SizedBox(height: 10),
              ExpandedOrSizedBox(
                fillHeight: widget.fillHeight,
                child: hasConfigs
                    ? listView
                    : Center(
                        child: Text(
                          I18n.homeEmptyScriptHint.tr,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
              ),
            ],
          );
        }),
      ),
    );
  }

  /// Wraps one config tile in the drop target used by drag-copy flows.
  Widget _buildDropTargetTile(BuildContext context, ScriptModel script) {
    return DragTarget<ConfigDragPayload>(
      onWillAcceptWithDetails: (details) {
        return _canAcceptPayload(script.name, details.data);
      },
      onMove: (details) => _handleDragMove(details.offset),
      onLeave: (_) => _stopAutoScroll(),
      onAcceptWithDetails: (details) async {
        _stopAutoScroll();
        widget.controller.clearConfigDrag();
        await widget.controller.acceptConfigDrag(
          payload: details.data,
          destinationConfig: script.name,
        );
      },
      builder: (context, candidateData, rejectedData) {
        final candidate = candidateData.isNotEmpty ? candidateData.first : null;
        final isHighlighted = _canAcceptPayload(script.name, candidate);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: isHighlighted
                ? Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.28)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHighlighted
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
            ),
          ),
          child: ConfigCollectionTile(
            controller: widget.controller,
            script: script,
            onTap: () => widget.onActivateScript(script.name),
            onTogglePower: () => widget.onTogglePower(
              script.name,
              script.state.value != ScriptState.running,
            ),
            onRename: () => widget.onRenameScript(script.name),
            onExport: () => widget.onExportScript(script.name),
            onDelete: () => widget.onDeleteScript(script.name),
          ),
        );
      },
    );
  }

  /// Returns whether the dragged payload may be dropped on the config row.
  bool _canAcceptPayload(String destinationConfig, ConfigDragPayload? payload) {
    return payload != null &&
        payload.canDropOn(destinationConfig) &&
        !widget.controller.isDragCopyPendingFor(destinationConfig);
  }

  /// Starts or stops list auto-scroll based on the current drag location.
  void _handleDragMove(Offset globalOffset) {
    final renderObject = _listViewportKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) {
      _stopAutoScroll();
      return;
    }
    final localOffset = renderObject.globalToLocal(globalOffset);
    final viewportHeight = renderObject.size.height;
    if (localOffset.dy <= _autoScrollEdgeExtent) {
      _startAutoScroll(-1);
      return;
    }
    if (localOffset.dy >= viewportHeight - _autoScrollEdgeExtent) {
      _startAutoScroll(1);
      return;
    }
    _stopAutoScroll();
  }

  /// Creates one periodic scroll loop in the given direction.
  void _startAutoScroll(double direction) {
    if (_autoScrollTimer != null && _autoScrollDirection == direction) {
      return;
    }
    _stopAutoScroll();
    _autoScrollDirection = direction;
    _autoScrollTimer = Timer.periodic(
      const Duration(milliseconds: 24),
      (_) => _tickAutoScroll(),
    );
  }

  /// Advances the list while drag hover stays inside one edge zone.
  void _tickAutoScroll() {
    if (!_listScrollController.hasClients) {
      _stopAutoScroll();
      return;
    }
    final position = _listScrollController.position;
    final currentOffset = position.pixels;
    final nextOffset = (currentOffset + _autoScrollDirection * _autoScrollStep)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((nextOffset - currentOffset).abs() < 0.5) {
      _stopAutoScroll();
      return;
    }
    _listScrollController.jumpTo(nextOffset);
  }

  /// Cancels any running auto-scroll loop.
  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    _autoScrollDirection = 0;
  }

  /// 设计稿 phead：脚本标题 + 计数胶囊 + 刷新/添加按钮。
  Widget _buildHeader(BuildContext context) {
    return Obx(() {
      final total = widget.controller.orderedScripts.length;
      return Row(
        children: [
          Text(
            I18n.mistScriptTitle.tr,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
            decoration: BoxDecoration(
              color: MistPalette.accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$total',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                fontFamily: 'Cascadia Code',
                color: MistPalette.accent,
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: I18n.homeConnectionRetryAction.tr,
            onPressed: widget.refreshingScripts ? null : widget.onRefreshScriptsTap,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 30, height: 30),
            iconSize: 16,
            icon: widget.refreshingScripts
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 4),
          Obx(
            () => IconButton(
              tooltip: widget.controller.isLinkModeEnabled.value
                  ? I18n.closeTheLinker.tr
                  : I18n.turnOnTheLinker.tr,
              onPressed: widget.controller.toggleLinkMode,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 30, height: 30),
              iconSize: 16,
              style: IconButton.styleFrom(
                backgroundColor: widget.controller.isLinkModeEnabled.value
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                foregroundColor: widget.controller.isLinkModeEnabled.value
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : null,
              ),
              icon: const Icon(Icons.link_rounded),
            ),
          ),
          const SizedBox(width: 4),
          MistGradientIconButton(
            icon: Icons.add_rounded,
            size: 26,
            tooltip: I18n.configAdd.tr,
            onPressed: widget.loadingAddScript ? null : widget.onAddScriptTap,
          ),
        ],
      );
    });
  }

  /// 圆角玻璃搜索框（设计稿 B 左栏样式）。
  Widget _buildSearchField(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: _searchController,
      decoration: InputDecoration(
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 18,
          color: isDark ? const Color(0xFF8A93AB) : const Color(0xFF9AA3B8),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 34),
        hintText: I18n.homeScriptSearchHint.tr,
        hintStyle: TextStyle(
          fontSize: 11.5,
          color: isDark ? const Color(0xFF8A93AB) : const Color(0xFF9AA3B8),
        ),
        filled: true,
        fillColor: isDark ? const Color(0x14FFFFFF) : const Color(0xB3FFFFFF),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        constraints: const BoxConstraints(minHeight: 31),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark
                ? const Color(0x1FFFFFFF)
                : const Color(0x171E283A),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark
                ? const Color(0x1FFFFFFF)
                : const Color(0x171E283A),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: MistPalette.accent),
        ),
      ),
      style: const TextStyle(fontSize: 12),
      onChanged: widget.controller.setSearchQuery,
    );
  }

  /// 状态筛选胶囊行：全部 / 运行中 / 已停止 / 异常（带计数）。
  Widget _buildFilterChips(BuildContext context) {
    final controller = widget.controller;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final value in ConfigCollectionPanel._visibleStateFilters)
          MistPillChip(
            label: _stateLabel(value),
            count: '${_filterCount(value)}',
            selected: controller.stateFilter.value == value,
            onTap: () => controller.setStateFilterValue(value),
          ),
      ],
    );
  }

  int _filterCount(HomeScriptStateFilter value) {
    return switch (value) {
      HomeScriptStateFilter.all => widget.controller.orderedScripts.length,
      _ => widget.controller.countScriptsByState(value),
    };
  }

  String _stateLabel(HomeScriptStateFilter value) {
    return switch (value) {
      HomeScriptStateFilter.all => I18n.mistFilterAll.tr,
      HomeScriptStateFilter.running => I18n.mistFilterRunning.tr,
      HomeScriptStateFilter.abnormal => I18n.mistFilterAbnormal.tr,
      HomeScriptStateFilter.stopped => I18n.mistFilterStopped.tr,
      HomeScriptStateFilter.offline => I18n.mistFilterAbnormal.tr,
    };
  }
}

class ExpandedOrSizedBox extends StatelessWidget {
  const ExpandedOrSizedBox({
    super.key,
    required this.fillHeight,
    required this.child,
  });

  final bool fillHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (fillHeight) {
      return Expanded(child: child);
    }
    return SizedBox(height: 320, child: child);
  }
}
