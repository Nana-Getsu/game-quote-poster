import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/poster_config.dart';
import 'crop_overlay.dart';

class ImagePreview extends StatelessWidget {
  const ImagePreview({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<PosterConfig>();
    final imagePath = config.imagePath;

    return Container(
      color: Colors.grey[900],
      child: imagePath != null
          ? Stack(
              children: [
                Center(
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.contain,
                  ),
                ),
                const CropOverlay(),
              ],
            )
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.image_outlined, size: 64, color: Colors.grey[600]),
                  const SizedBox(height: 12),
                  Text(
                    '拖拽图片到此处\n或点击下方 [打开图片]',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                  ),
                ],
              ),
            ),
    );
  }
}
