import 'package:flutter/material.dart';

/// 海报模板类型
enum PosterTemplate {
  ink,       // 水墨
  blur,      // 高斯模糊
  glass,     // 毛玻璃
  solid,     // 纯色极简
}

/// 输出比例
enum PosterAspectRatio {
  landscape, // 16:9
  portrait,  // 9:16
  square,    // 4:3
}

/// 文字位置
enum TextPosition {
  left,
  right,
  top,
  bottom,
}

/// 海报全量配置
class PosterConfig extends ChangeNotifier {
  // === 输入 ===
  String? _imagePath;
  String? get imagePath => _imagePath;

  // === OCR ===
  String _extractedText = '';
  String get extractedText => _extractedText;
  bool _isOcrRunning = false;
  bool get isOcrRunning => _isOcrRunning;

  // === 裁剪 ===
  Rect _cropRect = const Rect.fromLTWH(0, 0.67, 1, 0.28);
  Rect get cropRect => _cropRect;

  // === 模板 ===
  PosterTemplate _template = PosterTemplate.blur;
  PosterTemplate get template => _template;

  // === 比例 ===
  PosterAspectRatio _aspectRatio = PosterAspectRatio.landscape;
  PosterAspectRatio get aspectRatio => _aspectRatio;

  // === 文字位置 ===
  TextPosition _textPosition = TextPosition.right;
  TextPosition get textPosition => _textPosition;

  // === 字体 ===
  String _fontFamily = 'NotoSansSC';
  String get fontFamily => _fontFamily;
  double _fontSize = 32.0;
  double get fontSize => _fontSize;

  // === 颜色 ===
  Color _textColor = Colors.white;
  Color get textColor => _textColor;
  Color _backgroundColor = Colors.black54;
  Color get backgroundColor => _backgroundColor;

  // === 游戏名 ===
  String _gameName = '';
  String get gameName => _gameName;

  // === 状态更新方法 ===
  void setImagePath(String? path) {
    _imagePath = path;
    notifyListeners();
  }

  void setExtractedText(String text) {
    _extractedText = text;
    notifyListeners();
  }

  void setOcrRunning(bool running) {
    _isOcrRunning = running;
    notifyListeners();
  }

  void setCropRect(Rect rect) {
    _cropRect = rect;
    notifyListeners();
  }

  void setTemplate(PosterTemplate tpl) {
    _template = tpl;
    notifyListeners();
  }

  void setAspectRatio(PosterAspectRatio ratio) {
    _aspectRatio = ratio;
    notifyListeners();
  }

  void setTextPosition(TextPosition pos) {
    _textPosition = pos;
    notifyListeners();
  }

  void setFontFamily(String font) {
    _fontFamily = font;
    notifyListeners();
  }

  void setFontSize(double size) {
    _fontSize = size.clamp(16, 60);
    notifyListeners();
  }

  void setTextColor(Color color) {
    _textColor = color;
    notifyListeners();
  }

  void setBackgroundColor(Color color) {
    _backgroundColor = color;
    notifyListeners();
  }

  void setGameName(String name) {
    _gameName = name;
    notifyListeners();
  }
}
