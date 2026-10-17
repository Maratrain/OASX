import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:oasx/modules/common/models/oas_repo_ref.dart';
import 'package:oasx/modules/common/models/storage_key.dart';
import 'package:oasx/translation/i18n_content.dart';

/// 标题栏「仓库名 / 分支」指示：读取 OAS 仓库的 git 元数据后展示。
///
/// 采用纯文本样式（前置竖线 + 尾部下拉箭头），紧贴窗口按钮（最小化）左侧；
/// 读不到 OAS 根目录或仓库信息时整体隐藏，不占位；点击可手动刷新。
class OasRepoChip extends StatefulWidget {
  const OasRepoChip({super.key});

  /// 文本最大宽度，超出后省略。
  static const double maxWidth = 320;

  @override
  State<OasRepoChip> createState() => _OasRepoChipState();
}

class _OasRepoChipState extends State<OasRepoChip> {
  OasRepoRef? _ref;
  VoidCallback? _stopListen;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
    // OAS 根目录在设置页改动后需要重新读取。
    _stopListen = GetStorage().listenKey(
      StorageKey.rootPathServer.name,
      (_) => unawaited(_refresh()),
    );
  }

  @override
  void dispose() {
    _stopListen?.call();
    super.dispose();
  }

  Future<void> _refresh() async {
    final ref = await Future<OasRepoRef?>(
      () => OasRepoRef.read(_resolveRootPath()),
    );
    if (!mounted) {
      return;
    }
    setState(() => _ref = ref);
  }

  String _resolveRootPath() {
    final stored = GetStorage().read(StorageKey.rootPathServer.name);
    return stored is String ? stored.trim() : '';
  }

  @override
  Widget build(BuildContext context) {
    final ref = _ref;
    if (ref == null || !ref.isAvailable) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final valueColor = isDark ? const Color(0xFFC9D1E0) : const Color(0xFF3B4359);
    final labelColor = isDark ? const Color(0xFF7C869B) : const Color(0xFF8A93A8);
    final dividerColor = isDark ? const Color(0xFF444D5F) : const Color(0xFFC2C9D8);

    return Tooltip(
      message: _tooltip(ref),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => unawaited(_refresh()),
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 1, height: 16, color: dividerColor),
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: OasRepoChip.maxWidth),
                child: Text.rich(
                  TextSpan(
                    children: _spans(
                      ref,
                      valueColor: valueColor,
                      labelColor: labelColor,
                      dividerColor: dividerColor,
                    ),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.expand_more, size: 16, color: labelColor),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  List<TextSpan> _spans(
    OasRepoRef ref, {
    required Color valueColor,
    required Color labelColor,
    required Color dividerColor,
  }) {
    final valueStyle = TextStyle(fontSize: 12, color: valueColor);
    final labelStyle = TextStyle(fontSize: 12, color: labelColor);
    final dividerStyle = TextStyle(fontSize: 12, color: dividerColor);
    final spans = <TextSpan>[];

    if (ref.source.isNotEmpty) {
      spans.add(TextSpan(text: ref.source, style: valueStyle));
    }
    if (ref.branch.isNotEmpty) {
      final prefix = spans.isEmpty ? '' : ' ';
      spans.add(
        TextSpan(text: '$prefix${I18n.oasRepoBranch.tr}', style: labelStyle),
      );
      spans.add(TextSpan(text: ' · ', style: dividerStyle));
      spans.add(TextSpan(text: ref.branch, style: valueStyle));
    }
    return spans;
  }

  String _tooltip(OasRepoRef ref) {
    final lines = <String>[];
    if (ref.remoteUrl.isNotEmpty) {
      final remote = ref.remoteName.isEmpty ? '' : '${ref.remoteName} → ';
      lines.add('${I18n.oasSourceRepo.tr}: $remote${ref.remoteUrl}');
    } else if (ref.source.isNotEmpty) {
      lines.add('${I18n.oasSourceRepo.tr}: ${ref.source}');
    }
    if (ref.branch.isNotEmpty) {
      lines.add('${I18n.oasRepoBranch.tr}: ${ref.branch}');
    }
    if (ref.commit.isNotEmpty) {
      lines.add('${I18n.oasCommit.tr}: ${ref.commit}');
    }
    if (!ref.fromGit) {
      lines.add(I18n.oasRepoChipFromDeploy.tr);
    }
    lines.add(I18n.oasRepoChipRefresh.tr);
    return lines.join('\n');
  }
}
