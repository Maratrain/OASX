import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/config/theme.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/models/config_model.dart';
import 'package:oasx/modules/home/widgets/config_collection_script_label.dart';
import 'package:oasx/modules/home/widgets/config_collection_task_preview.dart';
import 'package:oasx/translation/i18n_content.dart';

class ConfigCollectionTile extends StatelessWidget {
  const ConfigCollectionTile({
    super.key,
    required this.controller,
    required this.script,
    required this.onTap,
    required this.onTogglePower,
    required this.onRename,
    required this.onExport,
    required this.onDelete,
  });

  final HomeDashboardController controller;
  final ScriptModel script;
  final VoidCallback onTap;
  final VoidCallback onTogglePower;
  final VoidCallback onRename;
  final VoidCallback onExport;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Obx(() {
          final isActive = controller.activeScriptName.value == script.name;
          final showLinkCheckbox = controller.isLinkModeEnabled.value;
          final isLinked = controller.isScriptLinked(script.name);
          final isDragCopyLoading = controller.isDragCopyPendingFor(
            script.name,
          );
          final accentColor = _accentColor(
            context,
            controller.scriptCollectionStateFor(script),
          );
          return DecoratedBox(
            decoration: BoxDecoration(
              color: isActive
                  ? (isDark
                      ? theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.20,
                        )
                      : const Color(0xE6FFFFFF))
                  : (isDark
                      ? theme.cardColor
                      : const Color(0x8CFFFFFF)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive
                    ? MistPalette.accent.withValues(alpha: 0.35)
                    : Colors.transparent,
              ),
              boxShadow: isActive && !isDark
                  ? const [
                      BoxShadow(
                        color: Color(0x295B7CFA),
                        blurRadius: 18,
                        offset: Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                if (isActive)
                  Positioned(
                    left: 0,
                    top: 12,
                    bottom: 12,
                    child: Container(
                      width: 3,
                      decoration: BoxDecoration(
                        gradient: MistPalette.accentGradient,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isDragCopyLoading ? null : onTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        isActive ? 13 : 10,
                        9,
                        8,
                        9,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (showLinkCheckbox) ...[
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: Checkbox(
                                value: isLinked,
                                onChanged: (value) => controller
                                    .setScriptLinked(
                                  script.name,
                                  value ?? false,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            const SizedBox(width: 2),
                          ],
                          Expanded(
                            child: Stack(
                              children: [
                                AbsorbPointer(
                                  absorbing: isDragCopyLoading,
                                  child: _ScriptMeta(
                                    script: script,
                                    accentColor: accentColor,
                                    powerButton: _PowerButton(
                                      onTogglePower: onTogglePower,
                                    ),
                                    popupButton: _ActionMenuButton(
                                      onRename: onRename,
                                      onExport: onExport,
                                      onDelete: onDelete,
                                    ),
                                  ),
                                ),
                                if (isDragCopyLoading)
                                  const Positioned.fill(
                                    child: _DragCopyLoadingMask(),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Color _accentColor(BuildContext context, HomeScriptStateFilter value) {
    final scheme = Theme.of(context).colorScheme;
    return switch (value) {
      HomeScriptStateFilter.running => MistPalette.runGreen,
      HomeScriptStateFilter.stopped => MistPalette.stopGrey,
      HomeScriptStateFilter.abnormal => MistPalette.warnOrange,
      HomeScriptStateFilter.offline => MistPalette.warnOrange,
      HomeScriptStateFilter.all => scheme.outline,
    };
  }
}

class _ScriptMeta extends StatelessWidget {
  const _ScriptMeta({
    required this.script,
    required this.accentColor,
    required this.powerButton,
    required this.popupButton,
  });

  final ScriptModel script;
  final Color accentColor;
  final Widget powerButton;
  final Widget popupButton;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _StateDot(color: accentColor),
            const SizedBox(width: 8),
            Expanded(
              child: ConfigCollectionScriptLabel(script: script, centered: false),
            ),
            powerButton,
            popupButton,
          ],
        ),
        const SizedBox(height: 3),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: DefaultTextStyle(
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF8A93AB)
                  : const Color(0xFF9AA3B8),
            ),
            child: ConfigCollectionTaskPreview(script: script),
          ),
        ),
      ],
    );
  }
}

class _DragCopyLoadingMask extends StatelessWidget {
  const _DragCopyLoadingMask();

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.68),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      ),
    );
  }
}

class _StateDot extends StatelessWidget {
  const _StateDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final glowing = color != MistPalette.stopGrey;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color.withValues(alpha: glowing ? 1 : 0.5),
        shape: BoxShape.circle,
        boxShadow: glowing
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.7),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
    );
  }
}

class _PowerButton extends StatelessWidget {
  const _PowerButton({required this.onTogglePower});

  final VoidCallback onTogglePower;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTogglePower,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      padding: EdgeInsets.zero,
      iconSize: 23,
      icon: const Icon(Icons.power_settings_new_rounded),
    );
  }
}

class _ActionMenuButton extends StatelessWidget {
  const _ActionMenuButton({
    required this.onRename,
    required this.onExport,
    required this.onDelete,
  });

  final VoidCallback onRename;
  final VoidCallback onExport;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 32,
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        tooltip: '',
        icon: const Icon(Icons.more_vert_rounded, size: 18),
        onSelected: (value) async {
          if (value == 'rename') {
            onRename();
            return;
          }
          if (value == 'export') {
            onExport();
            return;
          }
          onDelete();
        },
        itemBuilder: (context) => [
          PopupMenuItem(value: 'rename', child: Text(I18n.rename.tr)),
          PopupMenuItem(value: 'export', child: Text(I18n.configExport.tr)),
          PopupMenuItem(value: 'delete', child: Text(I18n.delete.tr)),
        ],
      ),
    );
  }
}
