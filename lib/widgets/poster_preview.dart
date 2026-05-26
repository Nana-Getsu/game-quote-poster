import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/poster_config.dart';
import 'text_overlay_editor.dart';

/// 海报预览区（支持两种模式 + 4 套模板 + 3 比例）
class PosterPreview extends StatelessWidget {
  final PosterConfig config;

  const PosterPreview({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final hasImage = config.imagePath != null;

    // 模式 A：文字叠加
    if (config.displayMode == DisplayMode.overlay) {
      return hasImage
          ? TextOverlayEditor(config: config)
          : _buildPlaceholder();
    }

    // 模式 B：左图右文
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = _calculateSize(constraints.maxWidth, constraints.maxHeight);
        return SizedBox(
          width: size.width,
          height: size.height,
          child: hasImage
              ? _buildTemplate(context, size)
              : _buildPlaceholder(),
        );
      },
    );
  }

  Size _calculateSize(double maxW, double maxH) {
    double w, h;
    switch (config.aspectRatio) {
      case PosterAspectRatio.landscape: // 16:9
        w = maxW;
        h = w / 16 * 9;
        if (h > maxH) { h = maxH; w = h / 9 * 16; }
        break;
      case PosterAspectRatio.portrait: // 9:16
        h = maxH;
        w = h / 16 * 9;
        if (w > maxW) { w = maxW; h = w / 9 * 16; }
        break;
      case PosterAspectRatio.square: // 4:3
        w = maxW;
        h = w / 4 * 3;
        if (h > maxH) { w = maxH / 3 * 4; h = maxH; }
        break;
    }
    return Size(w, h);
  }

  Widget _buildTemplate(BuildContext context, Size size) {
    switch (config.template) {
      case PosterTemplate.ink:
        return _buildInk(context, size);
      case PosterTemplate.blur:
        return _buildBlur(context, size);
      case PosterTemplate.glass:
        return _buildGlass(context, size);
      case PosterTemplate.solid:
        return _buildSolid(context, size);
    }
  }

  // === 纯色极简 ===
  Widget _buildSolid(BuildContext context, Size size) {
    final isLandscape = config.aspectRatio == PosterAspectRatio.landscape;
    return _buildTwoPanel(
      imageBuilder: () => _buildImagePane(size, isLandscape),
      textBuilder: () => _buildTextPane(
        bg: Colors.white,
        textColor: Colors.black87,
        size: size,
        isLandscape: isLandscape,
      ),
      size: size,
      isLandscape: isLandscape,
    );
  }

  // === 水墨 ===
  Widget _buildInk(BuildContext context, Size size) {
    final isLandscape = config.aspectRatio == PosterAspectRatio.landscape;
    return _buildTwoPanel(
      imageBuilder: () => ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.33, 0.59, 0.11, 0, 0,
          0.33, 0.59, 0.11, 0, 0,
          0.33, 0.59, 0.11, 0, 0,
          0,    0,    0,    1, 0,
        ]),
        child: _buildImagePane(size, isLandscape),
      ),
      textBuilder: () => _buildTextPane(
        bg: const Color(0xFFF5F0E8), // 宣纸色
        textColor: const Color(0xFF2C2C2C),
        size: size,
        isLandscape: isLandscape,
      ),
      size: size,
      isLandscape: isLandscape,
    );
  }

  // === 高斯模糊 ===
  Widget _buildBlur(BuildContext context, Size size) {
    // 整个海报用原图模糊作背景，文字叠加
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 模糊背景
          if (config.imagePath != null)
            Image.file(
              File(config.imagePath!),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.black26),
            ),
          // 模糊层
          ClipRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: Colors.black12),
            ),
          ),
          // 文字卡片
          Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: size.width * 0.7,
                maxHeight: size.height * 0.6,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.06,
                vertical: size.height * 0.05,
              ),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatText(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: config.fontSize * (size.width / 1920),
                  height: 1.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // === 毛玻璃 ===
  Widget _buildGlass(BuildContext context, Size size) {
    final isLandscape = config.aspectRatio == PosterAspectRatio.landscape;
    return _buildTwoPanel(
      imageBuilder: () => _buildImagePane(size, isLandscape),
      textBuilder: () => ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 用原图 + 模糊做右侧背景
            if (config.imagePath != null)
              Image.file(
                File(config.imagePath!),
                fit: BoxFit.cover,
                alignment: isLandscape ? Alignment.centerRight : Alignment.bottomCenter,
                errorBuilder: (_, __, ___) => Container(color: Colors.grey[300]),
              ),
            BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(color: Colors.white.withValues(alpha: 0.4)),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.03,
                  vertical: size.height * 0.04,
                ),
                child: Text(
                  _formatText(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: config.fontSize * (size.width / 1920),
                    height: 1.6,
                    fontWeight: FontWeight.w600,
                    shadows: const [
                      Shadow(color: Colors.white24, blurRadius: 4),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      size: size,
      isLandscape: isLandscape,
    );
  }

  // === 布局辅助：双面板（横排=左图右文，竖排=上图下文） ===
  Widget _buildTwoPanel({
    required Widget Function() imageBuilder,
    required Widget Function() textBuilder,
    required Size size,
    required bool isLandscape,
  }) {
    if (isLandscape) {
      // 横排：左图右文
      final imgW = size.width * 0.55;
      return Row(
        children: [
          SizedBox(width: imgW, height: size.height, child: imageBuilder()),
          Expanded(child: textBuilder()),
        ],
      );
    } else {
      // 竖排：上图下文
      final imgH = size.height * 0.55;
      return Column(
        children: [
          SizedBox(width: size.width, height: imgH, child: imageBuilder()),
          Expanded(child: textBuilder()),
        ],
      );
    }
  }

  /// 图片面板
  Widget _buildImagePane(Size size, bool isLandscape) {
    if (config.imagePath == null) {
      return Container(color: Colors.grey[400]);
    }
    return ClipRect(
      child: Image.file(
        File(config.imagePath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Container(color: Colors.grey[400], child: const Icon(Icons.broken_image)),
      ),
    );
  }

  /// 文字面板
  Widget _buildTextPane({
    required Color bg,
    required Color textColor,
    required Size size,
    required bool isLandscape,
  }) {
    final hasText = config.extractedText.isNotEmpty;
    return Container(
      color: bg,
      padding: EdgeInsets.symmetric(
        horizontal: size.width * 0.04,
        vertical: size.height * 0.05,
      ),
      child: hasText
          ? Center(
              child: Text(
                _formatText(),
                textAlign: _textAlign(),
                style: TextStyle(
                  color: textColor,
                  fontSize: config.fontSize * (size.width / 1920),
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : Icon(Icons.text_fields, color: textColor.withValues(alpha: 0.2), size: 48),
    );
  }

  String _formatText() => config.extractedText.replaceAll('\\n', '\n');

  TextAlign _textAlign() {
    switch (config.textPosition) {
      case TextPosition.left: return TextAlign.left;
      case TextPosition.right: return TextAlign.right;
      case TextPosition.top:
      case TextPosition.bottom:
        return TextAlign.center;
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text('海报预览', style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}
