# 05-OCR方案设计

## 双端方案

| | Windows | Android |
|---|---|---|
| 引擎 | PaddleOCR 3.x | Google ML Kit |
| 语言 | 中文 (ch) | 中文 (zh) |
| 调用方式 | HTTP localhost | Flutter Plugin |
| 离线 | 是 | 是 |
| GPU | 不需要（CPU 模式） | 不需要 |

## Windows 端：ocr_server.py

### 技术细节

```python
# 核心依赖
from paddleocr import PaddleOCR
from flask import Flask, request, jsonify

# 初始化（单例，避免重复加载模型）
ocr = PaddleOCR(lang='ch', use_angle_cls=True, show_log=False)

# API 端点
POST /ocr
  body: { "image_path": "xxx.png", "crop_region": [x1,y1,x2,y2] }
  response: { "texts": [{"text": "...", "confidence": 0.95}, ...] }
```

### 启动方式
- Flutter 启动时通过 `Process.start()` 拉起 Python 子进程
- 端口：随机可用端口（避免冲突）
- Flutter 退出时自动 kill 子进程

### 预处理优化
1. 灰度化（提升对比度）
2. 自适应二值化（处理游戏对话框半透明背景）
3. 去噪（去除对话框边框干扰）

## Android 端：Google ML Kit

### 技术细节

```dart
// 依赖
// pubspec.yaml: google_mlkit_text_recognition: ^0.11.0

final textRecognizer = TextRecognizer(script: TextRecognitionScript.chinese);

final inputImage = InputImage.fromFilePath(imagePath);
final recognizedText = await textRecognizer.processImage(inputImage);

for (final block in recognizedText.blocks) {
  print(block.text); // 按块输出识别文字
}
```

### 注意事项
- ML Kit 首次使用会自动下载中文模型（约 30MB）
- 需在 `AndroidManifest.xml` 添加 `INTERNET` 权限（仅用于模型下载）

## 统一接口 `ocr_service.dart`

```dart
abstract class OcrService {
  Future<List<OcrResult>> recognize(String imagePath, Rect? cropRegion);
}

class OcrResult {
  final String text;
  final double confidence;
  final Rect boundingBox;
}
```

- Windows 实现：HTTP 调用 `ocr_server.py`
- Android 实现：直接调用 ML Kit Plugin
- 通过 `Platform.isWindows` / `Platform.isAndroid` 自动切换

## 性能要求

| 指标 | 目标 |
|---|---|
| 首次初始化 | < 5s（Windows 加载 PaddleOCR 模型） |
| 单次识别 | < 2s |
| 识别准确率 | > 90%（游戏对话框场景） |
| 内存占用 | < 500MB |
