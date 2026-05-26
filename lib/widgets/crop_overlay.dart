import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/poster_config.dart';

/// 文字区域裁剪框（叠加在原图上）
/// 支持拖拽移动 + 拖边缩放
class CropOverlay extends StatefulWidget {
  const CropOverlay({super.key});

  @override
  State<CropOverlay> createState() => _CropOverlayState();
}

class _CropOverlayState extends State<CropOverlay> {
  Timer? _debounceTimer;
  Offset? _lastPanStart;
  Rect? _lastCropRect;

  // 拖动模式：move=移动整体, top=拖上边, bottom=拖下边
  String? _dragMode;

  void _onDragStart(DragStartDetails details, String mode) {
    final config = context.read<PosterConfig>();
    _lastPanStart = details.localPosition;
    _lastCropRect = config.cropRect;
    _dragMode = mode;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_lastPanStart == null || _lastCropRect == null) return;

    final config = context.read<PosterConfig>();
    // 把像素位移转换为相对坐标（0~1）
    final size = (context.findRenderObject() as RenderBox).size;
    final dx = details.localPosition.dx - _lastPanStart!.dx;
    final dy = details.localPosition.dy - _lastPanStart!.dy;
    final relDx = dx / size.width;
    final relDy = dy / size.height;

    double newLeft = _lastCropRect!.left;
    double newTop = _lastCropRect!.top;
    double newWidth = _lastCropRect!.width;
    double newHeight = _lastCropRect!.height;

    switch (_dragMode) {
      case 'move':
        newLeft = (_lastCropRect!.left + relDx).clamp(0.0, 1.0 - newWidth);
        newTop = (_lastCropRect!.top + relDy).clamp(0.0, 1.0 - newHeight);
        break;
      case 'top':
        newTop = (_lastCropRect!.top + relDy).clamp(0.0, _lastCropRect!.top + _lastCropRect!.height - 0.05);
        newHeight = (_lastCropRect!.height - relDy).clamp(0.05, _lastCropRect!.top + _lastCropRect!.height);
        break;
      case 'bottom':
        newHeight = (_lastCropRect!.height + relDy).clamp(0.05, 1.0 - _lastCropRect!.top);
        break;
      case 'left':
        newLeft = (_lastCropRect!.left + relDx).clamp(0.0, _lastCropRect!.left + _lastCropRect!.width - 0.05);
        newWidth = (_lastCropRect!.width - relDx).clamp(0.05, _lastCropRect!.left + _lastCropRect!.width);
        break;
      case 'right':
        newWidth = (_lastCropRect!.width + relDx).clamp(0.05, 1.0 - _lastCropRect!.left);
        break;
    }

    config.setCropRect(Rect.fromLTWH(newLeft, newTop, newWidth, newHeight));
  }

  void _onDragEnd(DragEndDetails details) {
    _lastPanStart = null;
    _lastCropRect = null;
    _dragMode = null;

    // 拖拽结束后延迟触发 OCR 重新识别（回调到 style_panel 统一处理）
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final config = context.read<PosterConfig>();
      config.setCropRect(config.cropRect); // 触发通知
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<PosterConfig>();
    final cropRect = config.cropRect;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Stack(
          children: [
            // 非文字区域半透明遮罩
            // 上部遮罩
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: cropRect.top * h,
              child: Container(color: Colors.black54),
            ),
            // 下部遮罩
            Positioned(
              top: cropRect.bottom * h,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(color: Colors.black54),
            ),
            // 裁剪框（可拖拽移动）
            Positioned(
              top: cropRect.top * h,
              left: cropRect.left * w,
              width: cropRect.width * w,
              height: cropRect.height * h,
              child: GestureDetector(
                onPanStart: (d) => _onDragStart(d, 'move'),
                onPanUpdate: _onDragUpdate,
                onPanEnd: _onDragEnd,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.cyanAccent, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            // 上边拖拽手柄
            Positioned(
              top: cropRect.top * h - 4,
              left: cropRect.left * w,
              width: cropRect.width * w,
              height: 8,
              child: GestureDetector(
                onPanStart: (d) => _onDragStart(d, 'top'),
                onPanUpdate: _onDragUpdate,
                onPanEnd: _onDragEnd,
                child: Container(
                  color: Colors.cyanAccent.withValues(alpha: 0.3),
                  child: Center(
                    child: Container(width: 40, height: 3, color: Colors.white),
                  ),
                ),
              ),
            ),
            // 下边拖拽手柄
            Positioned(
              top: cropRect.bottom * h - 4,
              left: cropRect.left * w,
              width: cropRect.width * w,
              height: 8,
              child: GestureDetector(
                onPanStart: (d) => _onDragStart(d, 'bottom'),
                onPanUpdate: _onDragUpdate,
                onPanEnd: _onDragEnd,
                child: Container(
                  color: Colors.cyanAccent.withValues(alpha: 0.3),
                  child: Center(
                    child: Container(width: 40, height: 3, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
