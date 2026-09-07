import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:oasx/config/theme.dart';
import 'package:oasx/translation/i18n_content.dart';

/// 「晨雾玻璃」标题栏品牌区：logo + OASX + 版本胶囊 + 连接状态胶囊。
///
/// 对应设计稿 B 顶栏左侧：渐变圆角 logo、粗体品牌名、
/// 等宽字体版本号胶囊、带发光绿点的「已连接 127.0.0.1:22288」胶囊。
class MistBrandHeader extends StatelessWidget {
  const MistBrandHeader({
    super.key,
    this.connected = true,
    this.address = '',
  });

  /// 后端是否已连接（false 时胶囊转为灰色「未连接」态）。
  final bool connected;

  /// 展示在连接胶囊里的后端地址。
  final String address;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            gradient: MistPalette.accentGradient,
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [
              BoxShadow(
                color: Color(0x666B7CFA),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
        ),
        const SizedBox(width: 9),
        Text(
          'OASX',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFE8ECF7) : const Color(0xFF232A3B),
          ),
        ),
        const SizedBox(width: 12),
        const _VersionChip(),
        const SizedBox(width: 12),
        _ConnectionChip(
          isDark: isDark,
          connected: connected,
          address: address,
        ),
      ],
    );
  }
}

class _VersionChip extends StatefulWidget {
  const _VersionChip();

  @override
  State<_VersionChip> createState() => _VersionChipState();
}

class _VersionChipState extends State<_VersionChip> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (!mounted) {
        return;
      }
      setState(() {
        _version = 'v${packageInfo.version}'.split('-').first;
      });
    } catch (_) {
      // 版本号加载失败时保持占位符即可。
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _CaptionChip(
      isDark: isDark,
      children: [
        Text(
          _version.isEmpty ? 'v—' : _version,
          style: TextStyle(
            fontSize: 10.5,
            fontFamily: 'Cascadia Code',
            color: isDark ? const Color(0xFF8A93AB) : const Color(0xFF9AA3B8),
          ),
        ),
      ],
    );
  }
}

class _ConnectionChip extends StatelessWidget {
  const _ConnectionChip({
    required this.isDark,
    required this.connected,
    required this.address,
  });

  final bool isDark;
  final bool connected;
  final String address;

  @override
  Widget build(BuildContext context) {
    final statusColor = connected ? MistPalette.runGreen : MistPalette.stopGrey;
    return _CaptionChip(
      isDark: isDark,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
            boxShadow: connected
                ? [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.7),
                      blurRadius: 7,
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          connected ? I18n.mistConnected.tr : I18n.mistDisconnected.tr,
          style: TextStyle(
            fontSize: 11.5,
            color: isDark ? const Color(0xFFB8C0D4) : const Color(0xFF5A6378),
          ),
        ),
        if (address.trim().isNotEmpty) ...[
          const SizedBox(width: 4),
          Text(
            address.trim(),
            style: TextStyle(
              fontSize: 10.5,
              fontFamily: 'Cascadia Code',
              color: isDark ? const Color(0xFF8A93AB) : const Color(0xFF9AA3B8),
            ),
          ),
        ],
      ],
    );
  }
}

class _CaptionChip extends StatelessWidget {
  const _CaptionChip({required this.isDark, required this.children});

  final bool isDark;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x14FFFFFF) : const Color(0xA6FFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark ? const Color(0x1FFFFFFF) : const Color(0x171E283A),
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}
