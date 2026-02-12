import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// 性能优化工具类
class PerformanceOptimizer {
  static bool _isPerformanceMode = false;

  // 启用性能模式（降低动画质量）
  static void enablePerformanceMode() {
    _isPerformanceMode = true;
    // 降低动画帧率
    timeDilation = 0.5;
  }

  // 禁用性能模式
  static void disablePerformanceMode() {
    _isPerformanceMode = false;
    timeDilation = 1.0;
  }

  static bool get isPerformanceMode => _isPerformanceMode;

  // 根据性能模式获取动画时长
  static Duration getAnimationDuration(Duration normalDuration) {
    return _isPerformanceMode
        ? Duration(milliseconds: normalDuration.inMilliseconds ~/ 2)
        : normalDuration;
  }

  // 获取粒子数量（性能模式下减少）
  static int getParticleCount(int normalCount) {
    return _isPerformanceMode ? normalCount ~/ 2 : normalCount;
  }

  // 获取模糊强度（性能模式下降低）
  static double getBlurSigma(double normalSigma) {
    return _isPerformanceMode ? normalSigma * 0.5 : normalSigma;
  }
}

// 内存管理器
class MemoryManager {
  static final List<VoidCallback> _disposeCallbacks = [];

  // 注册释放回调
  static void registerDisposeCallback(VoidCallback callback) {
    _disposeCallbacks.add(callback);
  }

  // 执行所有释放回调
  static void disposeAll() {
    for (final callback in _disposeCallbacks) {
      callback();
    }
    _disposeCallbacks.clear();
  }

  // 清理图片缓存
  static void clearImageCache() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  // 建议垃圾回收
  static void suggestGC() {
    // 在支持的平台上触发垃圾回收
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 延迟执行以确保帧渲染完成
      Future.delayed(const Duration(milliseconds: 100), () {
        // 清理未使用的资源
        clearImageCache();
      });
    });
  }
}

// 懒加载包装器
class LazyLoadWrapper extends StatefulWidget {
  final Widget child;
  final bool shouldLoad;

  const LazyLoadWrapper({
    super.key,
    required this.child,
    required this.shouldLoad,
  });

  @override
  State<LazyLoadWrapper> createState() => _LazyLoadWrapperState();
}

class _LazyLoadWrapperState extends State<LazyLoadWrapper> {
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.shouldLoad) {
      _load();
    }
  }

  @override
  void didUpdateWidget(LazyLoadWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldLoad && !oldWidget.shouldLoad) {
      _load();
    }
  }

  void _load() {
    // 延迟加载以避免阻塞UI
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _hasLoaded = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasLoaded) {
      return const SizedBox.shrink();
    }
    return widget.child;
  }
}

// 重绘边界优化
class OptimizedRepaintBoundary extends StatelessWidget {
  final Widget child;

  const OptimizedRepaintBoundary({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: child,
    );
  }
}

// 列表项缓存
class CachedListItem extends StatefulWidget {
  final Widget child;
  final String cacheKey;

  const CachedListItem({
    super.key,
    required this.child,
    required this.cacheKey,
  });

  @override
  State<CachedListItem> createState() => _CachedListItemState();
}

class _CachedListItemState extends State<CachedListItem>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

// 防抖器
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({required this.delay});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() {
    _timer?.cancel();
  }
}

// 节流器
class Throttler {
  final Duration delay;
  Timer? _timer;
  bool _isThrottling = false;

  Throttler({required this.delay});

  void run(VoidCallback action) {
    if (!_isThrottling) {
      action();
      _isThrottling = true;
      _timer = Timer(delay, () {
        _isThrottling = false;
      });
    }
  }

  void cancel() {
    _timer?.cancel();
    _isThrottling = false;
  }
}

// 资源预加载器
class ResourcePreloader {
  static final Map<String, bool> _loadedResources = {};

  // 预加载图片
  static Future<void> preloadImage(BuildContext context, String path) async {
    if (_loadedResources.containsKey(path)) return;

    final image = AssetImage(path);
    await precacheImage(image, context);
    _loadedResources[path] = true;
  }

  // 预加载多个图片
  static Future<void> preloadImages(
    BuildContext context,
    List<String> paths,
  ) async {
    for (final path in paths) {
      await preloadImage(context, path);
    }
  }

  // 检查是否已加载
  static bool isLoaded(String path) {
    return _loadedResources.containsKey(path);
  }

  // 清除缓存
  static void clearCache() {
    _loadedResources.clear();
  }
}

// 帧率监控器
class FrameRateMonitor {
  static final List<Duration> _frameTimes = [];
  static const int _maxSamples = 60;

  static void recordFrame(Duration frameTime) {
    _frameTimes.add(frameTime);
    if (_frameTimes.length > _maxSamples) {
      _frameTimes.removeAt(0);
    }
  }

  static double getAverageFPS() {
    if (_frameTimes.isEmpty) return 60.0;

    final averageFrameTime =
        _frameTimes.reduce((a, b) => a + b).inMicroseconds /
            _frameTimes.length;
    return 1000000 / averageFrameTime;
  }

  static bool get isPerformancePoor {
    return getAverageFPS() < 30;
  }

  static void clear() {
    _frameTimes.clear();
  }
}

// 动画优化器
class AnimationOptimizer {
  // 判断是否应使用简单动画
  static bool shouldUseSimpleAnimation() {
    return PerformanceOptimizer.isPerformanceMode ||
        FrameRateMonitor.isPerformancePoor;
  }

  // 获取优化的动画曲线
  static Curve getOptimizedCurve(Curve normalCurve) {
    return shouldUseSimpleAnimation() ? Curves.linear : normalCurve;
  }

  // 获取优化的动画时长
  static Duration getOptimizedDuration(Duration normalDuration) {
    return shouldUseSimpleAnimation()
        ? Duration(milliseconds: normalDuration.inMilliseconds ~/ 2)
        : normalDuration;
  }
}

// 图片优化加载器
class OptimizedImage extends StatelessWidget {
  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;

  const OptimizedImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: width?.toInt(),
      cacheHeight: height?.toInt(),
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: frame != null
              ? child
              : placeholder ??
                  Container(
                    color: Colors.grey.withOpacity(0.2),
                    child: const Center(
                      child: ProgressRing(),
                    ),
                  ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey.withOpacity(0.2),
          child: const Icon(
            Icons.broken_image,
            color: Colors.grey,
          ),
        );
      },
    );
  }
}

// 构建优化器
class BuildOptimizer {
  // 使用 const 构造函数
  static Widget constWidget(Widget widget) {
    return widget;
  }

  // 条件渲染
  static Widget conditional({
    required bool condition,
    required Widget trueWidget,
    required Widget falseWidget,
  }) {
    return condition ? trueWidget : falseWidget;
  }

  // 延迟构建
  static Widget delayedBuild({
    required Duration delay,
    required WidgetBuilder builder,
    Widget? placeholder,
  }) {
    return FutureBuilder(
      future: Future.delayed(delay),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return builder(context);
        }
        return placeholder ?? const SizedBox.shrink();
      },
    );
  }
}
