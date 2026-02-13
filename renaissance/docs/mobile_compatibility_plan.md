# Renaissance 移动端兼容改造计划

## 一、项目现状分析

### 1.1 当前支持平台
| 平台 | 状态 | 说明 |
|------|------|------|
| Windows | ✅ 已支持 | 主要目标平台 |
| Web | ✅ 已支持 | 有 web 目录 |
| Android | ❌ 未支持 | 缺少 android 目录 |
| iOS | ❌ 未支持 | 缺少 ios 目录 |
| macOS | ❌ 未支持 | 缺少 macos 目录 |
| Linux | ❌ 未支持 | 缺少 linux 目录 |

### 1.2 阻碍移动端兼容的核心问题

#### 1.2.1 桌面专用依赖
| 依赖包 | 问题 | 影响程度 |
|--------|------|----------|
| `just_audio_windows` | Windows 专用音频后端 | 🔴 高 - 需移除 |
| `window_manager` | 桌面窗口管理器 | 🔴 高 - 需条件编译 |
| `fluent_ui` | Microsoft Fluent Design | 🟡 中 - 需UI重构 |

#### 1.2.2 平台特定代码
| 文件 | 问题 | 影响程度 |
|------|------|----------|
| `main.dart` | 直接调用 `windowManager` | 🔴 高 |
| `window_title_bar.dart` | 整个组件依赖 `window_manager` | 🔴 高 |
| `player_page.dart` | 窗口控制按钮、拖动区域 | 🔴 高 |
| `local_music_service.dart` | 文件系统访问方式 | 🟡 中 |
| `keyboard_shortcuts.dart` | 键盘快捷键（移动端无键盘） | 🟢 低 |

#### 1.2.3 UI 布局问题
- 固定宽度侧边栏 (300px)
- 窗口控制按钮（最小化/最大化/关闭）
- 拖动标题栏 (`DragToMoveArea`)
- 桌面端鼠标交互 (`MouseRegion`, `SystemMouseCursors`)

---

## 二、依赖改造计划

### 2.1 pubspec.yaml 修改

```yaml
dependencies:
  # 音频处理 - 移除 just_audio_windows
  just_audio: ^0.9.46
  # just_audio_windows: ^0.2.2  # 删除此行
  audio_session: ^0.1.25
  
  # 状态管理 - 保持不变
  flutter_riverpod: ^2.4.9
  riverpod_annotation: ^2.3.3
  
  # UI 组件 - 需要条件使用
  fluent_ui: ^4.13.0
  # window_manager: ^0.3.5  # 条件依赖或移除
  
  # 新增：平台适配
  flutter_platform_widgets: ^7.0.0  # 可选：跨平台UI组件
  device_info_plus: ^9.0.0  # 设备信息检测
  
  # 新增：移动端文件选择
  file_picker: ^6.1.1  # 替代 file_selector（移动端兼容更好）
  
  # 其他依赖保持不变...
```

### 2.2 依赖替换说明

| 原依赖 | 替换方案 | 说明 |
|--------|----------|------|
| `just_audio_windows` | 移除 | `just_audio` 本身支持 Android/iOS |
| `window_manager` | 条件编译 | 仅桌面端使用 |
| `file_selector` | `file_picker` | 移动端文件选择兼容性更好 |

---

## 三、代码模块改造计划

### 3.1 入口文件改造 (main.dart)

**问题**：直接调用 `windowManager`，移动端不支持

**改造方案**：
```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_session/audio_session.dart';
// 条件导入
import 'package:window_manager/window_manager.dart'
    if (dart.library.io) 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化音频会话
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  // 仅桌面端初始化窗口管理器
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1400, 900),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const ProviderScope(child: RenaissanceApp()));
}
```

### 3.2 窗口标题栏改造 (window_title_bar.dart)

**问题**：整个组件依赖 `window_manager` 和 `DragToMoveArea`

**改造方案**：创建平台自适应组件

```dart
// 新建：shared/components/adaptive_app_bar.dart
class AdaptiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid || Platform.isIOS) {
      return _buildMobileAppBar(context);
    }
    return _buildDesktopAppBar(context);
  }

  Widget _buildMobileAppBar(BuildContext context) {
    return AppBar(
      title: Text(title ?? '文艺复兴'),
      actions: actions,
      leading: showBackButton 
        ? IconButton(icon: Icon(Icons.arrow_back), onPressed: onBackPressed)
        : null,
    );
  }

  Widget _buildDesktopAppBar(BuildContext context) {
    return WindowTitleBar(
      title: title,
      actions: actions,
      showBackButton: showBackButton,
      onBackPressed: onBackPressed,
    );
  }
}
```

### 3.3 播放器页面改造 (player_page.dart)

**问题**：
- 使用 `NavigationView`（Fluent UI 组件）
- 窗口控制按钮
- `DragToMoveArea` 拖动区域
- 固定宽度侧边栏

**改造要点**：

| 改造项 | 桌面端 | 移动端 |
|--------|--------|--------|
| 导航结构 | `NavigationView` + 侧边栏 | `Scaffold` + `BottomNavigationBar` / `Drawer` |
| 窗口控制 | 显示最小化/关闭按钮 | 隐藏 |
| 标题栏 | `DragToMoveArea` | 普通 `AppBar` |
| 歌曲列表 | 固定宽度 300px 侧边栏 | 底部抽屉或独立页面 |
| 混音台面板 | 右侧固定面板 | 底部弹出 ModalBottomSheet |

**布局改造示意**：
```dart
class PlayerPage extends ConsumerStatefulWidget {
  @override
  Widget build(BuildContext context) {
    final isMobile = Platform.isAndroid || Platform.isIOS;
    
    if (isMobile) {
      return _buildMobileLayout(context);
    }
    return _buildDesktopLayout(context);
  }
  
  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('文艺复兴')),
      body: Column(
        children: [
          Expanded(child: _buildPlayerContent()),
          // 移动端使用底部迷你播放器
          _buildMiniPlayer(),
        ],
      ),
      drawer: _buildMobileDrawer(), // 歌曲列表作为抽屉
      bottomNavigationBar: _buildBottomNav(),
    );
  }
  
  Widget _buildDesktopLayout(BuildContext context) {
    return NavigationView(
      appBar: _buildDesktopAppBar(),
      content: Row(
        children: [
          _buildSongList(),
          Expanded(child: _buildPlayerContent()),
        ],
      ),
    );
  }
}
```

### 3.4 本地音乐服务改造 (local_music_service.dart)

**问题**：
- `file_selector` 在移动端体验不佳
- 文件路径处理方式不同
- 音频元数据读取仅支持 Android

**改造方案**：

```dart
class LocalMusicService {
  // 使用 file_picker 替代
  static Future<String?> selectMusicDirectory() async {
    if (Platform.isAndroid || Platform.isIOS) {
      // 移动端：选择文件而非文件夹
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );
      if (result != null && result.files.isNotEmpty) {
        // 保存选择的文件路径
        await _saveSelectedFiles(result.paths);
        return result.paths.first;
      }
      return null;
    }
    
    // 桌面端：选择文件夹
    final selectedDirectory = await getDirectoryPath(
      confirmButtonText: '选择音乐文件夹',
    );
    if (selectedDirectory != null) {
      await saveMusicDirectory(selectedDirectory);
      return selectedDirectory;
    }
    return null;
  }
  
  // 移动端音乐目录
  static Future<String> getMusicDirectory() async {
    if (Platform.isAndroid) {
      // Android: /storage/emulated/0/Music 或应用私有目录
      final extDir = Directory('/storage/emulated/0/Music');
      if (await extDir.exists()) return extDir.path;
    }
    if (Platform.isIOS) {
      // iOS: 使用应用文档目录
      final appDir = await getApplicationDocumentsDirectory();
      return path.join(appDir.path, 'Music');
    }
    // 桌面端逻辑...
  }
}
```

### 3.5 主题系统改造 (app_theme.dart)

**问题**：使用 `FluentThemeData`，移动端需要 `ThemeData`

**改造方案**：

```dart
class AppTheme {
  // 颜色定义保持不变...
  
  // 桌面端主题
  static FluentThemeData get darkFluentTheme => FluentThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: softBlack,
    accentColor: AccentColor.swatch({
      'normal': vintageGold,
      'dark': vintageGold,
    }),
  );
  
  // 移动端主题
  static ThemeData get darkMaterialTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: softBlack,
    colorScheme: ColorScheme.dark(
      primary: vintageGold,
      secondary: warmBrown,
      surface: softBlack,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: softBlack,
      foregroundColor: warmCream,
    ),
  );
}
```

### 3.6 应用入口改造 (app.dart)

**问题**：使用 `FluentApp`，移动端需要 `MaterialApp`

**改造方案**：

```dart
class RenaissanceApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = !kIsWeb && 
        (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
    
    if (isDesktop) {
      return FluentApp(
        title: '文艺复兴',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        theme: AppTheme.lightFluentTheme,
        darkTheme: AppTheme.darkFluentTheme,
        home: const SplashPage(),
      );
    }
    
    return MaterialApp(
      title: '文艺复兴',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: AppTheme.lightMaterialTheme,
      darkTheme: AppTheme.darkMaterialTheme,
      home: const SplashPage(),
    );
  }
}
```

---

## 四、UI 适配详细方案

### 4.1 响应式布局策略

```
┌─────────────────────────────────────────────────────────────┐
│                      屏幕宽度判断                            │
├─────────────────────────────────────────────────────────────┤
│  < 600px    │  Mobile Layout   │ 单列布局 + 抽屉导航        │
│  600-840px  │  Tablet Layout   │ 双列布局 + 底部导航        │
│  > 840px    │  Desktop Layout  │ 三列布局 + 侧边栏          │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 移动端页面结构

```
┌──────────────────────┐
│      AppBar          │
├──────────────────────┤
│                      │
│    专辑封面/播放器    │
│                      │
├──────────────────────┤
│    歌曲信息          │
├──────────────────────┤
│    进度条            │
├──────────────────────┤
│    播放控制          │
├──────────────────────┤
│    迷你歌曲列表      │
└──────────────────────┘
```

### 4.3 组件适配清单

| 组件 | 桌面端 | 移动端 |
|------|--------|--------|
| 导航 | `NavigationView` | `Scaffold` + `Drawer` |
| 按钮 | `fluent_ui.Button` | `Material.ElevatedButton` |
| 图标 | `FluentIcons` | `Icons` (Material) |
| 对话框 | `ContentDialog` | `showDialog` + `AlertDialog` |
| 进度条 | 自定义 `VintageProgressBar` | 复用（已适配） |
| 滑块 | `fluent_ui.Slider` | `Material.Slider` |
| 列表 | `ListView.builder` | 复用（已适配） |

### 4.4 触摸交互优化

- 增大点击区域（最小 48x48 dp）
- 添加触摸反馈（`InkWell` / `GestureDetector`）
- 滑动手势支持（切歌、调节音量）
- 长按菜单（歌曲选项）

---

## 五、平台特定功能处理

### 5.1 文件系统访问

| 平台 | 方案 |
|------|------|
| Windows | 直接文件系统访问 |
| Android | `Storage Access Framework` 或 `MediaStore` API |
| iOS | 应用沙盒 + `UIDocumentPicker` |
| Web | 不支持本地文件（使用云端） |

### 5.2 音频后台播放

| 平台 | 配置 |
|------|------|
| Android | `AndroidManifest.xml` 添加 foreground service |
| iOS | `Info.plist` 添加 `UIBackgroundModes` |

### 5.3 权限配置

**Android (android/app/src/main/AndroidManifest.xml)**:
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

**iOS (ios/Runner/Info.plist)**:
```xml
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
</array>
<key>NSAppleMusicUsageDescription</key>
<string>需要访问您的音乐库以播放本地音乐</string>
```

---

## 六、实施阶段划分

### 阶段一：基础适配（优先级：高）
- [ ] 添加 Android/iOS 平台目录
- [ ] 修改 `pubspec.yaml` 依赖
- [ ] 改造 `main.dart` 入口
- [ ] 改造 `app.dart` 应用入口
- [ ] 创建平台检测工具类

### 阶段二：UI 适配（优先级：高）
- [ ] 创建 `AdaptiveAppBar` 组件
- [ ] 改造 `player_page.dart` 布局
- [ ] 创建移动端导航方案
- [ ] 适配主题系统

### 阶段三：功能适配（优先级：中）
- [ ] 改造 `local_music_service.dart`
- [ ] 适配文件选择功能
- [ ] 配置音频后台播放
- [ ] 添加权限配置

### 阶段四：优化完善（优先级：低）
- [ ] 触摸手势优化
- [ ] 动画性能优化
- [ ] 移动端专属功能（如手势切歌）
- [ ] 测试与修复

---

## 七、风险评估

| 风险项 | 影响程度 | 应对措施 |
|--------|----------|----------|
| `fluent_ui` 在移动端表现异常 | 高 | 完全分离 Material/Fluent UI |
| 文件访问权限问题 | 中 | 使用 `permission_handler` 处理 |
| 音频后台播放中断 | 中 | 配置正确的后台模式 |
| UI 布局错乱 | 中 | 使用响应式布局框架 |
| 性能问题 | 低 | 懒加载、图片缓存优化 |

---

## 八、测试计划

### 8.1 设备测试矩阵

| 设备类型 | 系统版本 | 测试重点 |
|----------|----------|----------|
| Android 手机 | Android 10+ | 文件访问、后台播放 |
| Android 平板 | Android 10+ | 响应式布局 |
| iPhone | iOS 14+ | 文件访问、后台播放 |
| iPad | iOS 14+ | 响应式布局 |

### 8.2 功能测试清单

- [ ] 应用启动与初始化
- [ ] 本地音乐扫描
- [ ] 音乐播放控制
- [ ] 后台播放
- [ ] 混音台功能
- [ ] 盲盒模式
- [ ] 金色信件功能
- [ ] 设置页面
- [ ] 屏幕旋转适配
- [ ] 深色模式

---

## 九、预计工作量

| 阶段 | 工作量估算 |
|------|------------|
| 阶段一：基础适配 | 2-3 天 |
| 阶段二：UI 适配 | 5-7 天 |
| 阶段三：功能适配 | 3-4 天 |
| 阶段四：优化完善 | 2-3 天 |
| **总计** | **12-17 天** |

---

## 十、参考资料

- [Flutter 平台适配指南](https://docs.flutter.dev/development/platform-integration)
- [just_audio 移动端配置](https://pub.dev/packages/just_audio)
- [Material Design 移动端指南](https://m3.material.io/)
- [Flutter 响应式布局](https://docs.flutter.dev/development/ui/layout/adaptive-responsive)
