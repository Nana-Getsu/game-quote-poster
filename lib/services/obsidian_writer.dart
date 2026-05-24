import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Obsidian Vault 写入服务（仅 Windows 端使用）
class ObsidianWriter {
  // Obsidian vault 根路径
  static const String _vaultRoot = r'E:\02 obsidian\Main\Main';

  // 海报图片存放目录
  static const String _postersDir = r'10 Reading\posters';

  // 名人名言汇总文件
  static const String _quotesFile = r'10 Reading\名人名言.md';

  /// 保存海报图片到 Obsidian vault
  /// [posterImagePath] 生成的海报临时文件路径
  /// 返回 vault 中图片的相对路径（用于 wiki-link）
  static Future<String> savePosterImage(String posterImagePath) async {
    final postersDir = Directory('$_vaultRoot\\$_postersDir');
    if (!await postersDir.exists()) {
      await postersDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final destName = '名句_$timestamp.png';
    final destPath = '${postersDir.path}\\$destName';

    await File(posterImagePath).copy(destPath);
    return '$_postersDir\\$destName'.replaceAll('\\', '/');
  }

  /// 追加名言条目到 名人名言.md
  /// [quoteText] 名言文字
  /// [gameName] 游戏名称
  /// [imageRelPath] 海报图片在 vault 中的相对路径
  static Future<void> appendQuote(
    String quoteText,
    String gameName,
    String imageRelPath,
  ) async {
    final quotesFile = File('$_vaultRoot\\$_quotesFile');
    final readingDir = Directory('$_vaultRoot\\10 Reading');
    if (!await readingDir.exists()) {
      await readingDir.create(recursive: true);
    }

    // 检查是否需要添加游戏名分组标题
    final entry = '- ![[${_getFileName(imageRelPath)}]] "${quoteText}" — *$gameName*';
    await quotesFile.writeAsString('$entry\n', mode: FileMode.append);
  }

  /// 从完整路径提取文件名
  static String _getFileName(String path) {
    return path.split('/').last;
  }
}
