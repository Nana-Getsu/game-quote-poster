import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../models/poster_config.dart';

/// 图像处理服务
class ImageProcessor {
  /// 自动检测文字区域（底部/侧边）
  /// 返回相对坐标 (0~1)
  /// 简单策略：默认底部 28%，用户可手动微调
  static CropRect detectTextRegion(String imagePath) {
    // TODO: 进阶——基于像素密度/边缘检测定位对话框
    return const CropRect(
      left: 0,
      top: 0.67,
      width: 1,
      height: 0.28,
    );
  }

  /// 应用高斯模糊，返回模糊后图片的临时文件路径
  /// [imagePath] 原图路径
  /// [radius] 模糊半径，默认 30
  static Future<String> applyGaussianBlur(
    String imagePath, {
    double radius = 30,
  }) async {
    final file = File(imagePath);
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('无法解码图片: $imagePath');

    final blurred = img.gaussianBlur(image, radius: radius.round());

    final outPath = '${file.parent.path}/_blurred_${DateTime.now().millisecondsSinceEpoch}.png';
    File(outPath).writeAsBytesSync(img.encodePng(blurred));
    return outPath;
  }

  /// 裁剪图片指定区域，返回裁剪后图片的临时文件路径
  /// [cropRect] 相对坐标 (0~1)
  static Future<String> cropImage(
    String imagePath,
    CropRect cropRect,
  ) async {
    final file = File(imagePath);
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('无法解码图片: $imagePath');

    final x = (cropRect.left * image.width).round().clamp(0, image.width);
    final y = (cropRect.top * image.height).round().clamp(0, image.height);
    final w = (cropRect.width * image.width).round().clamp(1, image.width - x);
    final h = (cropRect.height * image.height).round().clamp(1, image.height - y);

    final cropped = img.copyCrop(image, x: x, y: y, width: w, height: h);

    final outPath = '${file.parent.path}/_cropped_${DateTime.now().millisecondsSinceEpoch}.png';
    File(outPath).writeAsBytesSync(img.encodePng(cropped));
    return outPath;
  }

  /// 缩放图片到指定尺寸，保持比例填充
  static Future<String> resizeAndFill(
    String imagePath,
    int targetWidth,
    int targetHeight,
  ) async {
    final file = File(imagePath);
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('无法解码图片: $imagePath');

    final resized = img.copyResizeCropSquare(image, size: targetWidth > targetHeight ? targetHeight : targetWidth);
    // 等比缩放填充到目标尺寸
    final filled = img.copyResize(resized,
        width: targetWidth, height: targetHeight);

    final outPath = '${file.parent.path}/_resized_${DateTime.now().millisecondsSinceEpoch}.png';
    File(outPath).writeAsBytesSync(img.encodePng(filled));
    return outPath;
  }
}

/// 相对坐标 (0~1) 的矩形
class CropRect {
  final double left;
  final double top;
  final double width;
  final double height;

  const CropRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
}
