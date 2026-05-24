import '../models/poster_config.dart';

/// 海报模板渲染服务
/// 阶段3实现4套模板
class PosterDesigner {
  /// 渲染水墨模板
  static void renderInk(String canvas, PosterConfig config) {
    // TODO: 阶段3
  }

  /// 渲染高斯模糊模板
  static void renderBlur(String canvas, PosterConfig config) {
    // TODO: 阶段3
  }

  /// 渲染毛玻璃模板
  static void renderGlass(String canvas, PosterConfig config) {
    // TODO: 阶段3
  }

  /// 渲染纯色极简模板
  static void renderSolid(String canvas, PosterConfig config) {
    // TODO: 阶段3
  }

  /// 根据配置选择模板渲染
  static void render(String canvas, PosterConfig config) {
    switch (config.template) {
      case PosterTemplate.ink:
        renderInk(canvas, config);
      case PosterTemplate.blur:
        renderBlur(canvas, config);
      case PosterTemplate.glass:
        renderGlass(canvas, config);
      case PosterTemplate.solid:
        renderSolid(canvas, config);
    }
  }
}
