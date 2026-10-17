import 'dart:io';

import 'package:oasx/modules/server/models/deploy_git_config.dart';

/// OAS 仓库的「仓库名 / 分支」快照，供标题栏展示。
///
/// 优先读取本地 git 元数据（`.git/HEAD` + `.git/config`），
/// 读不到时回退到 `config/deploy.yaml` 里配置的安装源与分支。
class OasRepoRef {
  const OasRepoRef({
    required this.source,
    required this.branch,
    required this.remoteName,
    required this.remoteUrl,
    required this.commit,
    required this.fromGit,
  });

  /// 形如 `owner/repo` 的源仓库标识，解析失败时为空串。
  final String source;

  /// 当前分支名，处于分离 HEAD 或读取失败时为空串。
  final String branch;

  /// 分支跟踪的远端名，如 `origin`，未知时为空串。
  final String remoteName;

  /// 远端完整地址，未知时为空串。
  final String remoteUrl;

  /// 当前分支的提交短哈希，未知时为空串。
  final String commit;

  /// 数据是否来自本地 git 元数据；`false` 表示回退到了 `deploy.yaml`。
  final bool fromGit;

  /// 是否具备可展示的内容。
  bool get isAvailable => source.isNotEmpty || branch.isNotEmpty;

  /// 读取 [rootPath] 指向的 OAS 仓库信息，完全读不到时返回 null。
  static OasRepoRef? read(String rootPath) {
    final root = _normalizeRoot(rootPath);
    if (root.isEmpty || !Directory(root).existsSync()) {
      return null;
    }

    final gitDir = _resolveGitDir(root);
    final head = gitDir == null ? null : _readHead(gitDir);
    final remote = gitDir == null ? null : _readRemote(gitDir, head?.branch ?? '');
    final deploy = _readDeploy(root);

    final gitBranch = head?.branch ?? '';
    final gitSource = remote?.repo ?? '';
    final source = gitSource.isNotEmpty ? gitSource : deploy.source;
    final branch = gitBranch.isNotEmpty ? gitBranch : deploy.branch;

    if (source.isEmpty && branch.isEmpty) {
      return null;
    }

    return OasRepoRef(
      source: source,
      branch: branch,
      remoteName: remote?.name ?? '',
      remoteUrl: remote?.url ?? '',
      commit: head?.commit ?? '',
      fromGit: gitSource.isNotEmpty || gitBranch.isNotEmpty,
    );
  }

  static String _normalizeRoot(String rootPath) {
    return rootPath.trim().replaceFirst(RegExp(r'[\\/]+$'), '');
  }

  /// 解析 `.git` 目录：普通仓库为目录，worktree 为 `gitdir: ...` 文本文件。
  static String? _resolveGitDir(String root) {
    final directory = Directory('$root/.git');
    if (directory.existsSync()) {
      return directory.path;
    }

    final pointer = File('$root/.git');
    if (!pointer.existsSync()) {
      return null;
    }
    final content = _readText(pointer);
    if (!content.toLowerCase().startsWith('gitdir:')) {
      return null;
    }
    final target = content.substring('gitdir:'.length).trim();
    if (target.isEmpty) {
      return null;
    }
    final absolute = RegExp(r'^[a-zA-Z]:').hasMatch(target) || target.startsWith('/')
        ? target
        : '$root/$target';
    return Directory(absolute).existsSync() ? Directory(absolute).path : null;
  }

  /// 读取 HEAD：返回当前分支名与提交短哈希（分离 HEAD 时分支为空）。
  static _HeadInfo? _readHead(String gitDir) {
    final file = File('$gitDir/HEAD');
    if (!file.existsSync()) {
      return null;
    }
    final content = _readText(file);
    if (!content.startsWith('ref:')) {
      return _HeadInfo(branch: '', commit: _shortSha(content));
    }

    final ref = content.substring('ref:'.length).trim();
    const prefix = 'refs/heads/';
    final branch = ref.startsWith(prefix) ? ref.substring(prefix.length) : '';
    return _HeadInfo(
      branch: branch,
      commit: branch.isEmpty ? '' : _readBranchCommit(gitDir, branch),
    );
  }

  static String _readBranchCommit(String gitDir, String branch) {
    final loose = File('$gitDir/refs/heads/$branch');
    if (loose.existsSync()) {
      return _shortSha(_readText(loose));
    }

    final packed = File('$gitDir/packed-refs');
    if (packed.existsSync()) {
      final suffix = ' refs/heads/$branch';
      for (final line in packed.readAsLinesSync()) {
        final trimmed = line.trim();
        if (trimmed.endsWith(suffix)) {
          return _shortSha(trimmed.split(' ').first);
        }
      }
    }
    return '';
  }

  /// 解析分支跟踪的远端（无跟踪关系时退回 origin，再退回首个远端）。
  static _RemoteInfo? _readRemote(String gitDir, String branch) {
    final file = File('$gitDir/config');
    if (!file.existsSync()) {
      return null;
    }
    final sections = _parseGitConfig(file.readAsStringSync());

    var name = '';
    if (branch.isNotEmpty) {
      name = _sectionValue(sections, 'branch "$branch"', 'remote');
    }
    var url = name.isEmpty ? '' : _sectionValue(sections, 'remote "$name"', 'url');
    if (url.isEmpty) {
      name = 'origin';
      url = _sectionValue(sections, 'remote "origin"', 'url');
    }
    if (url.isEmpty) {
      for (final entry in sections.entries) {
        if (!entry.key.toLowerCase().startsWith('remote ')) {
          continue;
        }
        final candidate = entry.value['url'] ?? '';
        if (candidate.isEmpty) {
          continue;
        }
        name = _sectionName(entry.key);
        url = candidate;
        break;
      }
    }

    if (url.isEmpty) {
      return null;
    }
    return _RemoteInfo(name: name, url: url, repo: _repoFromUrl(url));
  }

  /// 读取 deploy.yaml 配置的安装源与分支，作为 git 元数据缺失时的兜底。
  static _DeployInfo _readDeploy(String root) {
    try {
      final config = DeployGitConfig.read(root);
      return _DeployInfo(
        source: _repoFromUrl(config.repository),
        branch: config.branch.trim(),
      );
    } catch (_) {
      return const _DeployInfo(source: '', branch: '');
    }
  }

  static Map<String, Map<String, String>> _parseGitConfig(String content) {
    final sections = <String, Map<String, String>>{};
    Map<String, String>? current;
    for (final line in content.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#') || trimmed.startsWith(';')) {
        continue;
      }
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        final name = trimmed.substring(1, trimmed.length - 1).trim();
        current = sections.putIfAbsent(name, () => <String, String>{});
        continue;
      }
      final separator = trimmed.indexOf('=');
      if (current == null || separator <= 0) {
        continue;
      }
      current[trimmed.substring(0, separator).trim().toLowerCase()] =
          trimmed.substring(separator + 1).trim();
    }
    return sections;
  }

  static String _sectionValue(
    Map<String, Map<String, String>> sections,
    String section,
    String key,
  ) {
    final direct = sections[section];
    if (direct != null) {
      return direct[key] ?? '';
    }
    final lowered = section.toLowerCase();
    for (final entry in sections.entries) {
      if (entry.key.toLowerCase() == lowered) {
        return entry.value[key] ?? '';
      }
    }
    return '';
  }

  static String _sectionName(String section) {
    final start = section.indexOf('"');
    final end = section.lastIndexOf('"');
    if (start >= 0 && end > start) {
      return section.substring(start + 1, end);
    }
    return section.split(' ').last;
  }

  /// 从远端地址取出 `owner/repo`，兼容 https 与 `git@host:owner/repo` 两种写法。
  static String _repoFromUrl(String url) {
    var value = url.trim();
    if (value.isEmpty) {
      return '';
    }

    final schemeIndex = value.indexOf('://');
    if (schemeIndex >= 0) {
      value = value.substring(schemeIndex + 3);
    } else {
      final colonIndex = value.indexOf(':');
      if (colonIndex >= 0 && !value.substring(0, colonIndex).contains('/')) {
        value = value.substring(colonIndex + 1);
      }
    }

    final slashIndex = value.indexOf('/');
    if (slashIndex >= 0 && value.substring(0, slashIndex).contains('.')) {
      value = value.substring(slashIndex + 1);
    }

    value = value.replaceFirst(RegExp(r'\.git$'), '').replaceFirst(RegExp(r'/+$'), '');
    final segments = value.split('/').where((segment) => segment.isNotEmpty).toList();
    if (segments.length < 2) {
      return segments.isEmpty ? '' : segments.first;
    }
    return '${segments[segments.length - 2]}/${segments.last}';
  }

  static String _shortSha(String value) {
    final trimmed = value.trim();
    return trimmed.length <= 7 ? trimmed : trimmed.substring(0, 7);
  }

  static String _readText(File file) {
    try {
      return file.readAsStringSync().trim();
    } catch (_) {
      return '';
    }
  }
}

class _HeadInfo {
  const _HeadInfo({required this.branch, required this.commit});

  final String branch;
  final String commit;
}

class _RemoteInfo {
  const _RemoteInfo({required this.name, required this.url, required this.repo});

  final String name;
  final String url;
  final String repo;
}

class _DeployInfo {
  const _DeployInfo({required this.source, required this.branch});

  final String source;
  final String branch;
}
