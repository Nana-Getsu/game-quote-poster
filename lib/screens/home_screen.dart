import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../models/poster_config.dart';
import '../services/ocr_service.dart' show OcrRect, createOcrService;
import '../services/image_processor.dart' show ImageProcessor;
import '../widgets/image_preview.dart';
import '../widgets/poster_preview.dart';
import '../widgets/crop_overlay.dart';
import '../widgets/style_panel.dart' show StylePanel, ImageProcRect;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _dragging = false;

  void _onImageLoaded(String path) {
    final config = context.read<PosterConfig>();
    config.setImagePath(path);

    // 自动检测文字区域（默认底部 28%）
    final detected = ImageProcessor.detectTextRegion(path);
    config.setCropRect(ImageProcRect.toFlutterRect(detected));

    // 自动触发 OCR
    _runOcr(config);
  }

  void _runOcr(PosterConfig config) {
    final imagePath = config.imagePath;
    if (imagePath == null) return;

    config.setOcrRunning(true);
    final ocr = createOcrService();

    ocr.init().then((_) {
      return ocr.recognize(
        imagePath,
        cropRegion: OcrRect(
          left: config.cropRect.left,
          top: config.cropRect.top,
          width: config.cropRect.width,
          height: config.cropRect.height,
        ),
      );
    }).then((results) {
      final text = results.map((r) => r.text).join('\n');
      config.setExtractedText(text);
      config.setOcrRunning(false);
    }).catchError((e) {
      config.setOcrRunning(false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OCR 识别失败: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('游戏截图名句提取'),
        centerTitle: true,
        actions: [
          Consumer<PosterConfig>(
            builder: (_, config, __) =>
                config.isOcrRunning
                    ? const Padding(
                        padding: EdgeInsets.only(right: 16),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white70,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
          ),
        ],
      ),
      body: DropTarget(
        onDragEntered: (_) => setState(() => _dragging = true),
        onDragExited: (_) => setState(() => _dragging = false),
        onDragDone: (detail) {
          setState(() => _dragging = false);
          if (detail.files.isNotEmpty) {
            final path = detail.files.first.path;
            if (_isImageFile(path)) {
              _onImageLoaded(path);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('请拖入图片文件（JPG/PNG/WebP/BMP）')),
              );
            }
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                return isWide ? _buildWideLayout() : _buildNarrowLayout();
              },
            ),
            // 拖拽悬停提示
            if (_dragging)
              Container(
                color: Colors.blue.withValues(alpha: 0.15),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 20),
                      ],
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 64, color: Colors.blue),
                        SizedBox(height: 12),
                        Text('松开加载图片', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _isImageFile(String path) {
    final ext = path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'webp', 'bmp'].contains(ext);
  }

  Widget _buildWideLayout() {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Row(
            children: [
              const Expanded(child: ImagePreview()),
              const VerticalDivider(width: 1),
              Expanded(child: Consumer<PosterConfig>(
                builder: (_, config, __) => PosterPreview(config: config),
              )),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          flex: 2,
          child: StylePanel(onImageLoaded: _onImageLoaded),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: 300,
            child: Stack(
              children: const [
                ImagePreview(),
                CropOverlay(),
              ],
            ),
          ),
          SizedBox(
            height: 300,
            child: Consumer<PosterConfig>(
              builder: (_, config, __) => PosterPreview(config: config),
            ),
          ),
          const Divider(height: 1),
          StylePanel(onImageLoaded: _onImageLoaded),
        ],
      ),
    );
  }
}

