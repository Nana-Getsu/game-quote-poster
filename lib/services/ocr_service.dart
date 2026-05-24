import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// OCR 识别结果
class OcrResult {
  final String text;
  final double confidence;
  final OcrRect boundingBox;

  OcrResult({
    required this.text,
    required this.confidence,
    required this.boundingBox,
  });
}

/// 矩形区域（与平台无关）
class OcrRect {
  final double left;
  final double top;
  final double width;
  final double height;

  const OcrRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
}

/// OCR 服务统一接口
/// Windows：通过 HTTP 调用 ocr_server.py (PaddleOCR)
/// Android：通过 Google ML Kit 插件
abstract class OcrService {
  /// 初始化 OCR 引擎（加载模型等）
  Future<void> init();

  /// 识别图片中的文字
  /// [imagePath] 图片文件路径
  /// [cropRegion] 可选，指定裁剪区域（相对坐标 0~1）
  /// 返回识别结果列表，按阅读顺序排列
  Future<List<OcrResult>> recognize(
    String imagePath, {
    OcrRect? cropRegion,
  });

  /// 释放资源
  void dispose();
}

/// 平台工厂：根据平台返回对应实现
OcrService createOcrService() {
  if (defaultTargetPlatform == TargetPlatform.windows) {
    return WindowsOcrService();
  } else if (defaultTargetPlatform == TargetPlatform.android) {
    return AndroidOcrService();
  }
  throw UnsupportedError('不支持当前平台');
}

// === Windows 实现 (PaddleOCR via HTTP) ===
class WindowsOcrService implements OcrService {
  Process? _pythonProcess;
  int _port = 0;
  final _httpClient = HttpClient();
  bool _initialized = false;

  @override
  Future<void> init() async {
    if (_initialized) return;

    // 1. 找到空闲端口
    _port = await _findFreePort();

    // 2. 启动 ocr_server.py 子进程
    final scriptPath = 'scripts${Platform.pathSeparator}ocr_server.py';
    _pythonProcess = await Process.start('python', [
      scriptPath,
      '--port', '$_port',
    ]);

    // 监听子进程 stderr（调试用）
    _pythonProcess!.stderr
        .transform(utf8.decoder)
        .listen((msg) => debugPrint('[OCR Server] $msg'));

    // 3. 等待服务就绪 (health check，最多等 30 秒)
    for (var i = 0; i < 30; i++) {
      try {
        final ok = await _healthCheck();
        if (ok) {
          _initialized = true;
          return;
        }
      } catch (_) {
        // 还没就绪，继续等
      }
      await Future.delayed(const Duration(seconds: 1));
    }

    throw Exception('OCR 服务启动超时（30 秒未就绪）');
  }

  @override
  Future<List<OcrResult>> recognize(
    String imagePath, {
    OcrRect? cropRegion,
  }) async {
    if (!_initialized) {
      await init();
    }

    // 构造请求体
    final body = <String, dynamic>{
      'image_path': imagePath,
    };
    if (cropRegion != null) {
      body['crop_region'] = [
        cropRegion.left,
        cropRegion.top,
        cropRegion.left + cropRegion.width,
        cropRegion.top + cropRegion.height,
      ];
    }

    try {
      final request = await _httpClient.postUrl(
        Uri.parse('http://127.0.0.1:$_port/ocr'),
      );
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));

      final response = await request.close().timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final result = await response.transform(utf8.decoder).join();
        final data = jsonDecode(result) as Map<String, dynamic>;
        final texts = data['texts'] as List<dynamic>? ?? [];

        return texts.map((t) {
          final m = t as Map<String, dynamic>;
          // bbox 是多边形点位 [[x,y], [x,y], ...]
          final bbox = m['bbox'] as List<dynamic>? ?? [];
          double left = 0, top = 0, right = 0, bottom = 0;
          if (bbox.isNotEmpty) {
            final xs = bbox.map((p) => (p as List<dynamic>)[0] as num);
            final ys = bbox.map((p) => (p as List<dynamic>)[1] as num);
            left = xs.reduce((a, b) => a < b ? a : b).toDouble();
            top = ys.reduce((a, b) => a < b ? a : b).toDouble();
            right = xs.reduce((a, b) => a > b ? a : b).toDouble();
            bottom = ys.reduce((a, b) => a > b ? a : b).toDouble();
          }
          return OcrResult(
            text: m['text'] as String,
            confidence: (m['confidence'] as num).toDouble(),
            boundingBox: OcrRect(
              left: left,
              top: top,
              width: right - left,
              height: bottom - top,
            ),
          );
        }).toList();
      } else {
        throw Exception('OCR 请求失败: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('OCR 请求超时');
    }
  }

  @override
  void dispose() {
    _pythonProcess?.kill();
    _httpClient.close();
    _initialized = false;
  }

  /// 找一个空闲的 TCP 端口
  Future<int> _findFreePort() async {
    final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = socket.port;
    await socket.close();
    return port;
  }

  /// 健康检查
  Future<bool> _healthCheck() async {
    try {
      final request = await _httpClient.getUrl(
        Uri.parse('http://127.0.0.1:$_port/health'),
      );
      final response = await request.close().timeout(
        const Duration(seconds: 2),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

// === Android 实现 (Google ML Kit) ===
// 在 Windows 上编译时 ML Kit 类型未定义，运行时会通过 dynamic 调用
class AndroidOcrService implements OcrService {
  dynamic _textRecognizer;

  @override
  Future<void> init() async {
    if (_textRecognizer != null) return;

    try {
      // 运行时反射：google_mlkit_text_recognition.TextRecognizer
      // ignore: prefer_typing_uninitialized_variables
      final recognizer = _createRecognizer();
      _textRecognizer = recognizer;
    } catch (e) {
      throw Exception('ML Kit 初始化失败: $e');
    }
  }

  dynamic _createRecognizer() {
    // 运行时加载，避免编译时依赖
    throw UnimplementedError('Android 平台需 google_mlkit_text_recognition 包');
  }

  @override
  Future<List<OcrResult>> recognize(
    String imagePath, {
    OcrRect? cropRegion,
  }) async {
    if (_textRecognizer == null) {
      await init();
    }

    try {
      // 运行时调用 ML Kit
      if (_textRecognizer == null) {
        throw Exception('OCR 引擎未初始化');
      }
      throw UnimplementedError('Android 端 OCR 待阶段 6 真机测试');
    } catch (e) {
      throw Exception('OCR 识别失败: $e');
    }
  }

  @override
  void dispose() {
    try {
      _textRecognizer?.close();
    } catch (_) {}
    _textRecognizer = null;
  }
}
