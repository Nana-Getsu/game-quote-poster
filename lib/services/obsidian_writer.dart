import 'dart:io';

/// 共享空间写入服务（仅 Windows 端使用）
class ObsidianWriter {
  // 共享空间根路径
  static const String _shareRoot = r'E:\08 vscodeproject\共享空间';

  // 海报图片存放目录
  static const String _postersDir = '游戏名句海报';

  // 名人名言汇总文件
  static const String _quotesFile = '名人名言.md';

  /// 保存海报图片到共享空间
  /// [posterImagePath] 生成的海报临时文件路径
  /// 返回保存后的完整路径
  static Future<String> savePosterImage(String posterImagePath) async {
    final postersDir = Directory('$_shareRoot\\$_postersDir');
    if (!await postersDir.exists()) {
      await postersDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final destName = '名句_$timestamp.png';
    final destPath = '${postersDir.path}\\$destName';

    await File(posterImagePath).copy(destPath);
    return destPath;
  }

  /// 追加名言条目到 名人名言.md
  /// [quoteText] 名言文字
  /// [gameName] 游戏名称
  /// [posterPath] 海报图片完整路径
  static Future<void> appendQuote(
    String quoteText,
    String gameName,
    String posterPath,
  ) async {
    final shareDir = Directory(_shareRoot);
    if (!await shareDir.exists()) {
      await shareDir.create(recursive: true);
    }

    final fileName = posterPath.split('\\').last;
    final entry = '- ![[游戏名句海报/$fileName]] "${quoteText}" — *$gameName*';
    await File('$_shareRoot\\$_quotesFile').writeAsString('$entry\n', mode: FileMode.append);
  }
}
