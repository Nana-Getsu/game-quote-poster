import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/poster_config.dart';

/// 文字叠加编辑器：文字浮在原图上，可拖动
class TextOverlayEditor extends StatefulWidget {
  final PosterConfig config;

  const TextOverlayEditor({super.key, required this.config});

  @override
  State<TextOverlayEditor> createState() => _TextOverlayEditorState();
}

class _TextOverlayEditorState extends State<TextOverlayEditor> {
  final _repaintKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    final hasImage = config.imagePath != null;
    final hasText = config.extractedText.isNotEmpty;

    if (!hasImage) {
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text('请先加载图片', style: TextStyle(color: Colors.grey[500])),
            ],
          ),
        ),
      );
    }

    return RepaintBoundary(
      key: _repaintKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ClipRect(
            child: Stack(
              children: [
                // 底层：原图
                Positioned.fill(
                  child: _buildBackground(config, constraints),
                ),
                // 如果有文字：可拖动的文字层
                if (hasText)
                  Positioned(
                    left: config.overlayTextX * constraints.maxWidth - 100,
                    top: config.overlayTextY * constraints.maxHeight - 30,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        final newX = (config.overlayTextX * constraints.maxWidth + details.delta.dx) / constraints.maxWidth;
                        final newY = (config.overlayTextY * constraints.maxHeight + details.delta.dy) / constraints.maxHeight;
                        config.setOverlayTextPosition(newX, newY);
                      },
                      child: _buildTextOverlay(config),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 背景图（根据模板加滤镜）
  Widget _buildBackground(PosterConfig config, BoxConstraints constraints) {
    final image = Image.file(
      File(config.imagePath!),
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Container(color: Colors.grey[400]),
    );

    switch (config.template) {
      case PosterTemplate.blur:
        return Stack(
          fit: StackFit.expand,
          children: [
            image,
            ClipRect(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(color: Colors.black12),
              ),
            ),
          ],
        );
      case PosterTemplate.ink:
        return ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            0.33, 0.59, 0.11, 0, 0,
            0.33, 0.59, 0.11, 0, 0,
            0.33, 0.59, 0.11, 0, 0,
            0, 0, 0, 1, 0,
          ]),
          child: image,
        );
      case PosterTemplate.glass:
      case PosterTemplate.solid:
        return image;
    }
  }

  /// 可拖动的文字
  Widget _buildTextOverlay(PosterConfig config) {
    final text = config.extractedText.replaceAll('\\n', '\n');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: config.fontFamily == 'System' ? null : config.fontFamily,
          fontSize: config.fontSize,
          color: config.textColor,
          fontWeight: FontWeight.bold,
          height: 1.5,
          shadows: const [
            Shadow(color: Colors.black38, blurRadius: 4, offset: Offset(1, 1)),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
