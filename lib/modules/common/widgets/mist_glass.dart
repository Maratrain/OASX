import 'package:flutter/material.dart';
import 'package:oasx/config/theme.dart';

/// 「晨雾玻璃」共享小组件：胶囊筛选 chip / 状态胶囊 / ghost 按钮 /
/// 渐变图标按钮 / 下划线 tab，对应设计稿 B 的控件语言。

/// 胶囊筛选 chip：选中为靛紫渐变白字，未选中为半透明白 + 细描边。
class MistPillChip extends StatelessWidget {
  const MistPillChip({
    super.key,
    required this.label,
    this.count,
    this.selected = false,
    this.onTap,
    this.compact = false,
  });

  final String label;

  /// 可选的等宽计数（如「全部 5」中的 5）。
  final String? count;
  final bool selected;
  final VoidCallback? onTap;

  /// 紧凑模式（右侧面板 tab 用），内边距更小、字号更小。
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 10,
          vertical: compact ? 5 : 4,
        ),
        decoration: selected
            ? MistDecor.accentCapsule()
            : BoxDecoration(
                color: isDark
                    ? const Color(0x14FFFFFF)
                    : const Color(0x99FFFFFF),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isDark
                      ? const Color(0x1FFFFFFF)
                      : const Color(0x171E283A),
                ),
              ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: compact ? 11.5 : 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected
                    ? Colors.white
                    : (isDark
                        ? const Color(0xFFB8C0D4)
                        : const Color(0xFF5A6378)),
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 3),
              Text(
                count!,
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'Cascadia Code',
                  color: selected
                      ? Colors.white.withValues(alpha: 0.85)
                      : (isDark
                          ? const Color(0xFF8A93AB)
                          : const Color(0xFF9AA3B8)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 状态胶囊：彩点 + 文字，底色为该色的浅晕染（如「运行中」绿胶囊）。
class MistStatusPill extends StatelessWidget {
  const MistStatusPill({
    super.key,
    required this.label,
    required this.color,
    this.showDot = true,
  });

  final String label;
  final Color color;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.6),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.05,
              color: isDark
                  ? Color.lerp(color, Colors.white, 0.35)
                  : color,
            ),
          ),
        ],
      ),
    );
  }
}

/// 极小状态标签（任务行内的 RUNNING / WAITING 徽标）。
class MistMiniTag extends StatelessWidget {
  const MistMiniTag({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.07,
          color: isDark ? Color.lerp(color, Colors.white, 0.35) : color,
        ),
      ),
    );
  }
}

/// ghost 按钮：白底细描边小按钮，可着色（琥珀「全部立即运行」/ 绿「全部等待」）。
class MistGhostButton extends StatelessWidget {
  const MistGhostButton({
    super.key,
    required this.icon,
    required this.label,
    this.foreground,
    this.background,
    this.borderColor,
    this.onPressed,
    this.loading = false,
  });

  final IconData icon;
  final String label;
  final Color? foreground;
  final Color? background;
  final Color? borderColor;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = foreground ??
        (isDark ? const Color(0xFFB8C0D4) : const Color(0xFF5A6378));
    return InkWell(
      onTap: loading ? null : onPressed,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: background ??
              (isDark ? const Color(0x14FFFFFF) : const Color(0xB3FFFFFF)),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: borderColor ??
                (isDark ? const Color(0x1FFFFFFF) : const Color(0x171E283A)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const SizedBox(
                width: 12.5,
                height: 12.5,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(icon, size: 12.5, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 11.5, color: fg),
            ),
          ],
        ),
      ),
    );
  }
}

/// 靛紫渐变 icon 按钮（脚本面板的「添加」按钮）。
class MistGradientIconButton extends StatelessWidget {
  const MistGradientIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.size = 26,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final button = Container(
      width: size,
      height: size,
      decoration: MistDecor.accentCapsule(radius: 8),
      child: Icon(icon, size: size * 0.5, color: Colors.white),
    );
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: button,
      ),
    );
  }
}

/// 下划线文字 tab：选中为靛紫加粗 + 底部渐变短横条。
class MistUnderlineTabs<T> extends StatelessWidget {
  const MistUnderlineTabs({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onSelected,
  });

  final List<(T, String)> tabs;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (index, (value, label)) in tabs.indexed) ...[
          if (index > 0) const SizedBox(width: 4),
          InkWell(
            onTap: () => onSelected(value),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight:
                          value == selected ? FontWeight.w700 : FontWeight.w400,
                      color: value == selected
                          ? MistPalette.accent
                          : (isDark
                              ? const Color(0xFF8A93AB)
                              : const Color(0xFF9AA3B8)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    height: 3,
                    width: value == selected ? 28 : 0,
                    decoration: BoxDecoration(
                      gradient: MistPalette.accentGradient,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
