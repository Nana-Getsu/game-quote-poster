"""
游戏截图名句提取 — Windows OCR 本地服务
PaddleOCR 中文识别，Flutter 通过 HTTP 调用

启动方式: python ocr_server.py --port 8765
"""

import sys
import json
import argparse
from http.server import HTTPServer, BaseHTTPRequestHandler

try:
    from paddleocr import PaddleOCR
    PADDLE_AVAILABLE = True
except ImportError:
    PADDLE_AVAILABLE = False
    print("[WARN] PaddleOCR 未安装，请运行: pip install paddleocr")


def init_ocr():
    """延迟初始化 PaddleOCR（避免启动时阻塞）"""
    if not PADDLE_AVAILABLE:
        return None
    return PaddleOCR(lang='ch')


class OcrHandler(BaseHTTPRequestHandler):
    ocr = None

    def do_POST(self):
        if self.path != '/ocr':
            self.send_error(404)
            return

        content_length = int(self.headers['Content-Length'])
        body = self.rfile.read(content_length)
        data = json.loads(body)

        image_path = data.get('image_path', '')
        crop_region = data.get('crop_region')  # optional: [x1,y1,x2,y2]

        if not image_path:
            self.send_error(400, 'Missing image_path')
            return

        try:
            texts = self._recognize(image_path, crop_region)
            self.send_response(200)
            self.send_header('Content-Type', 'application/json; charset=utf-8')
            self.end_headers()
            self.wfile.write(json.dumps({'texts': texts}, ensure_ascii=False).encode('utf-8'))
        except Exception as e:
            self.send_error(500, str(e))

    def do_GET(self):
        if self.path == '/health':
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b'ok')
        else:
            self.send_error(404)

    def _recognize(self, image_path, crop_region):
        if self.ocr is None:
            self.ocr = init_ocr()
        if self.ocr is None:
            raise RuntimeError('PaddleOCR 未安装')

        # 如果指定了裁剪区域，先用 Pillow 裁剪
        ocr_input_path = image_path
        if crop_region and len(crop_region) == 4:
            try:
                from PIL import Image
                img = Image.open(image_path)
                w, h = img.size

                x1, y1, x2, y2 = crop_region
                # 如果值是 0~1 的相对坐标，转为像素
                if all(0 <= v <= 1 for v in crop_region):
                    x1, y1, x2, y2 = int(x1 * w), int(y1 * h), int(x2 * w), int(y2 * h)

                # 确保裁剪区域在图片范围内
                x1, y1 = max(0, x1), max(0, y1)
                x2, y2 = min(w, x2), min(h, y2)

                cropped = img.crop((x1, y1, x2, y2))
                import tempfile
                tmp = tempfile.NamedTemporaryFile(suffix='.png', delete=False)
                cropped.save(tmp.name)
                ocr_input_path = tmp.name
            except Exception as e:
                print(f'[WARN] 裁剪失败，使用原图: {e}')

        # PaddleOCR 3.x 使用 predict() 方法
        result = self.ocr.predict(ocr_input_path)

        # 清理临时文件
        if ocr_input_path != image_path:
            import os
            os.unlink(ocr_input_path)

        if not result:
            return []

        texts = []
        for page in result:
            for rec_text, rec_score, rec_poly in zip(
                page['rec_texts'],
                page['rec_scores'],
                page['rec_polys']
            ):
                # 将 numpy 数组转为 Python 列表（才能 JSON 序列化）
                import numpy as np
                bbox = rec_poly
                if isinstance(bbox, np.ndarray):
                    bbox = bbox.tolist()

                texts.append({
                    'text': rec_text,
                    'confidence': round(float(rec_score), 3),
                    'bbox': bbox,
                })

        return texts


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--port', type=int, default=8765)
    args = parser.parse_args()

    server = HTTPServer(('127.0.0.1', args.port), OcrHandler)
    print(f'OCR Server running on http://127.0.0.1:{args.port}')
    print(f'Health check: http://127.0.0.1:{args.port}/health')
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print('\nShutting down...')
        server.shutdown()


if __name__ == '__main__':
    main()
