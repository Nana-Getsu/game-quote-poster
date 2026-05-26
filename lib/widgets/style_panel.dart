import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/poster_config.dart';
import '../services/ocr_service.dart';
import '../services/obsidian_writer.dart';
import '../services/image_processor.dart';

/// 底部控制面板
/// 包含：文字编辑框、比例/模板/字体/位置选择器、操作按钮
class StylePanel extends StatelessWidget {
  final void Function(String path)? onImageLoaded;

  const StylePanel({super.key, this.onImageLoaded});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<PosterConfig>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 识别文字编辑框
          _buildTextField(config),
          const SizedBox(height: 12),

          // 模式切换
          _buildModeSwitch(config),
          const SizedBox(height: 8),

          // 参数控制行
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _buildRatioSelector(config),
              _buildTemplateSelector(config),
              _buildTextPositionSelector(config),
              _buildFontSelector(config),
              _buildFontSizeSlider(config),
            ],
          ),
          const SizedBox(height: 12),

          // 操作按钮
          _buildActionButtons(context, config),
        ],
      ),
    );
  }

  Widget _buildTextField(PosterConfig config) {
    return TextField(
      controller: TextEditingController(text: config.extractedText),
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: '识别文字（可编辑修改）',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      onChanged: (text) => config.setExtractedText(text),
    );
  }

  Widget _buildModeSwitch(PosterConfig config) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('显示模式: '),
        SegmentedButton<DisplayMode>(
          segments: const [
            ButtonSegment(value: DisplayMode.overlay, label: Text('文字叠加')),
            ButtonSegment(value: DisplayMode.splitPanel, label: Text('左图右文')),
          ],
          selected: {config.displayMode},
          onSelectionChanged: (s) => config.setDisplayMode(s.first),
        ),
      ],
    );
  }

  Widget _buildRatioSelector(PosterConfig config) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('比例: '),
        SegmentedButton<PosterAspectRatio>(
          segments: const [
            ButtonSegment(value: PosterAspectRatio.landscape, label: Text('16:9')),
            ButtonSegment(value: PosterAspectRatio.portrait, label: Text('9:16')),
            ButtonSegment(value: PosterAspectRatio.square, label: Text('4:3')),
          ],
          selected: {config.aspectRatio},
          onSelectionChanged: (s) => config.setAspectRatio(s.first),
        ),
      ],
    );
  }

  Widget _buildTemplateSelector(PosterConfig config) {
    return DropdownButton<PosterTemplate>(
      value: config.template,
      items: const [
        DropdownMenuItem(value: PosterTemplate.blur, child: Text('高斯模糊')),
        DropdownMenuItem(value: PosterTemplate.ink, child: Text('水墨')),
        DropdownMenuItem(value: PosterTemplate.glass, child: Text('毛玻璃')),
        DropdownMenuItem(value: PosterTemplate.solid, child: Text('纯色极简')),
      ],
      onChanged: (v) {
        if (v != null) config.setTemplate(v);
      },
    );
  }

  Widget _buildTextPositionSelector(PosterConfig config) {
    return DropdownButton<TextPosition>(
      value: config.textPosition,
      items: const [
        DropdownMenuItem(value: TextPosition.right, child: Text('文字在右')),
        DropdownMenuItem(value: TextPosition.left, child: Text('文字在左')),
        DropdownMenuItem(value: TextPosition.bottom, child: Text('文字在下')),
        DropdownMenuItem(value: TextPosition.top, child: Text('文字在上')),
      ],
      onChanged: (v) {
        if (v != null) config.setTextPosition(v);
      },
    );
  }

  Widget _buildFontSelector(PosterConfig config) {
    final fonts = _scanSystemFonts();

    return DropdownButton<String>(
      value: fonts.contains(config.fontFamily) ? config.fontFamily : 'System',
      isExpanded: false,
      items: fonts.map((font) {
        return DropdownMenuItem(value: font, child: Text(font));
      }).toList(),
      onChanged: (v) {
        if (v != null) config.setFontFamily(v);
      },
    );
  }

  /// 扫描 Windows 系统字体 + 内置备选
  List<String> _scanSystemFonts() {
    final fonts = <String>['System'];
    try {
      final fontsDir = Directory(r'C:\Windows\Fonts');
      if (fontsDir.existsSync()) {
        for (final entity in fontsDir.listSync()) {
          final name = entity.path;
          // 过滤中文字体
          if (name.contains('msyh') || name.contains('Microsoft YaHei')) {
            fonts.add('Microsoft YaHei');
          }
          if (name.contains('simhei') || name.contains('SimHei')) {
            fonts.add('SimHei');
          }
          if (name.contains('simsun') || name.contains('SimSun')) {
            fonts.add('SimSun');
          }
          if (name.contains('simkai') || name.contains('KaiTi')) {
            fonts.add('KaiTi');
          }
          if (name.contains('FangSong') || name.contains('仿宋')) {
            fonts.add('FangSong');
          }
        }
      }
    } catch (_) {}

    // 去重 + 内置备选
    final unique = fonts.toSet().toList()..remove('System');
    // System 总是在最前面
    unique.insert(0, 'System');
    return unique;
  }

  Widget _buildFontSizeSlider(PosterConfig config) {
    return SizedBox(
      width: 200,
      child: Row(
        children: [
          const Text('字号: '),
          Expanded(
            child: Slider(
              value: config.fontSize,
              min: 16,
              max: 60,
              divisions: 44,
              label: '${config.fontSize.round()}pt',
              onChanged: (v) => config.setFontSize(v),
            ),
          ),
          Text('${config.fontSize.round()}pt'),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, PosterConfig config) {
    return Wrap(
      spacing: 12,
      children: [
        ElevatedButton.icon(
          onPressed: () => _pickImage(context, config),
          icon: const Icon(Icons.folder_open),
          label: const Text('打开图片'),
        ),
        ElevatedButton.icon(
          onPressed: () => _reRunOcr(config),
          icon: const Icon(Icons.refresh),
          label: const Text('重新识别'),
        ),
        FilledButton.icon(
          onPressed: () => _save(context, config),
          icon: const Icon(Icons.save),
          label: const Text('保存'),
        ),
      ],
    );
  }

  void _pickImage(BuildContext context, PosterConfig config) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp'],
    );
    if (result == null || result.files.isEmpty) return;

    final path = result.files.single.path;
    if (path == null) return;

    // 委托给外部回调（home_screen 处理 OCR 全流程）
    if (onImageLoaded != null) {
      onImageLoaded!(path);
    }
  }

  void _reRunOcr(PosterConfig config) {
    final imagePath = config.imagePath;
    if (imagePath == null) return;

    config.setOcrRunning(true);
    final ocr = createOcrService();

    ocr.init().then((_) {
      return ocr.recognize(
        imagePath,
        cropRegion: ocrServiceRectFromConfig(config),
      );
    }).then((results) {
      final text = results.map((r) => r.text).join('\n');
      config.setExtractedText(text);
      config.setOcrRunning(false);
    }).catchError((e) {
      config.setExtractedText('[识别失败] $e');
      config.setOcrRunning(false);
    });
  }

  /// 将 PosterConfig 中的 Flutter Rect 转为 OcrRect
  static OcrRect ocrServiceRectFromConfig(PosterConfig config) {
    final r = config.cropRect;
    return OcrRect(
      left: r.left,
      top: r.top,
      width: r.width,
      height: r.height,
    );
  }

  void _save(BuildContext context, PosterConfig config) async {
    final imagePath = config.imagePath;
    final quoteText = config.extractedText;

    if (imagePath == null || quoteText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先加载图片并完成 OCR 识别')),
      );
      return;
    }

    try {
      // 1. 保存海报图片到 Obsidian vault
      final imgRelPath = await ObsidianWriter.savePosterImage(imagePath);
      // 2. 追加名言到 名人名言.md
      await ObsidianWriter.appendQuote(
        quoteText,
        config.gameName.isNotEmpty ? config.gameName : '未知游戏',
        imgRelPath,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已保存到 Obsidian: $imgRelPath'),
            backgroundColor: Colors.green[700],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }
}

/// 桥接 image_processor 的 CropRect 到 Flutter Rect
class ImageProcRect {
  static Rect toFlutterRect(CropRect r) {
    return Rect.fromLTWH(r.left, r.top, r.width, r.height);
  }
}
