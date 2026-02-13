import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

void main() {
  print('🎵 生成文艺复兴应用图标...');

  // 创建不同尺寸的图标
  final sizes = [16, 32, 48, 64, 128, 256];
  final images = <img.Image>[];

  for (final size in sizes) {
    print('  生成 ${size}x$size 图标...');
    final image = _createVinylIcon(size);
    images.add(image);
  }

  // 保存为 ICO 文件
  final icoPath = 'windows/runner/resources/app_icon.ico';
  final icoFile = File(icoPath);

  // 确保目录存在
  icoFile.parent.createSync(recursive: true);

  // 写入 ICO 文件
  final icoData = _encodeIco(images);
  icoFile.writeAsBytesSync(icoData);

  print('✅ 图标已生成: $icoPath');
  print('📦 包含尺寸: ${sizes.join(', ')}');
}

/// 创建唱片图标
img.Image _createVinylIcon(int size) {
  final image = img.Image(width: size, height: size);
  final center = size ~/ 2;
  final maxRadius = (size / 2 - 1).toInt();

  // 背景 - 深色渐变
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final dx = x - center;
      final dy = y - center;
      final distance = sqrt(dx * dx + dy * dy);

      if (distance <= maxRadius) {
        // 径向渐变从中心到边缘
        final t = distance / maxRadius;
        final r = (26 * (1 - t) + 10 * t).toInt();
        final g = (26 * (1 - t) + 10 * t).toInt();
        final b = (26 * (1 - t) + 10 * t).toInt();
        image.setPixel(x, y, img.ColorRgba8(r, g, b, 255));
      } else {
        image.setPixel(x, y, img.ColorRgba8(0, 0, 0, 0));
      }
    }
  }

  // 绘制唱片纹路
  final grooveColor = img.ColorRgba8(255, 255, 255, 15);
  for (var r = maxRadius - 2; r > size * 0.25; r -= max(1, size ~/ 60)) {
    _drawCircle(image, center, center, r.toInt(), grooveColor);
  }

  // 绘制高光效果
  _drawShine(image, center, maxRadius, size);

  // 绘制中心标签
  final labelRadius = (size * 0.28).toInt();
  final goldColor1 = img.ColorRgba8(212, 175, 55, 220);
  final goldColor2 = img.ColorRgba8(180, 140, 40, 180);

  for (var y = center - labelRadius; y <= center + labelRadius; y++) {
    for (var x = center - labelRadius; x <= center + labelRadius; x++) {
      final dx = x - center;
      final dy = y - center;
      final distance = sqrt(dx * dx + dy * dy);

      if (distance <= labelRadius) {
        final t = distance / labelRadius;
        final r = (212 * (1 - t) + 180 * t).toInt();
        final g = (175 * (1 - t) + 140 * t).toInt();
        final b = (55 * (1 - t) + 40 * t).toInt();
        image.setPixel(x, y, img.ColorRgba8(r, g, b, 255));
      }
    }
  }

  // 绘制音乐符号
  _drawMusicNote(image, center, (size * 0.15).toInt());

  // 绘制中心孔
  final holeRadius = max(2, size ~/ 25);
  final holeColor = img.ColorRgba8(20, 20, 20, 255);
  for (var y = center - holeRadius; y <= center + holeRadius; y++) {
    for (var x = center - holeRadius; x <= center + holeRadius; x++) {
      final dx = x - center;
      final dy = y - center;
      if (sqrt(dx * dx + dy * dy) <= holeRadius) {
        image.setPixel(x, y, holeColor);
      }
    }
  }

  return image;
}

/// 绘制圆形
void _drawCircle(img.Image image, int cx, int cy, int radius, img.Color color) {
  for (var angle = 0; angle < 360; angle += 2) {
    final rad = angle * pi / 180;
    final x = (cx + radius * cos(rad)).round();
    final y = (cy + radius * sin(rad)).round();
    if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
      image.setPixel(x, y, color);
    }
  }
}

/// 绘制高光效果
void _drawShine(img.Image image, int center, int maxRadius, int size) {
  // 左上角高光
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final dx = x - center;
      final dy = y - center;
      final distance = sqrt(dx * dx + dy * dy);

      if (distance <= maxRadius) {
        // 计算高光强度（基于角度和距离）
        final angle = atan2(dy, dx);
        final normalizedAngle = (angle + pi) / (2 * pi);

        // 高光在左上方
        if (normalizedAngle > 0.6 && normalizedAngle < 0.9 && distance > maxRadius * 0.3) {
          final shineIntensity = (1 - (distance / maxRadius)) * 0.15;
          final pixel = image.getPixel(x, y);
          final r = min(255, (pixel.r + shineIntensity * 255).toInt());
          final g = min(255, (pixel.g + shineIntensity * 255).toInt());
          final b = min(255, (pixel.b + shineIntensity * 255).toInt());
          image.setPixel(x, y, img.ColorRgba8(r, g, b, 255));
        }
      }
    }
  }
}

/// 绘制音乐符号
void _drawMusicNote(img.Image image, int center, int noteSize) {
  final noteColor = img.ColorRgba8(180, 140, 40, 255);

  // 简化的音符绘制 - 使用像素点
  final notePixels = _getNotePixels(noteSize);

  for (final pixel in notePixels) {
    final x = center + pixel.dx;
    final y = center + pixel.dy;
    if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
      image.setPixel(x, y, noteColor);
    }
  }
}

/// 获取音符的像素坐标
List<_Pixel> _getNotePixels(int size) {
  final pixels = <_Pixel>[];
  final scale = size / 20.0;

  // 音符主体（椭圆形）
  for (var y = -8; y <= 8; y++) {
    for (var x = -6; x <= 6; x++) {
      if ((x * x) / 36 + (y * y) / 64 <= 1) {
        pixels.add(_Pixel((x * scale).round(), (y * scale).round()));
      }
    }
  }

  // 音符杆
  for (var y = -15; y <= -5; y++) {
    for (var x = 4; x <= 7; x++) {
      pixels.add(_Pixel((x * scale).round(), (y * scale).round()));
    }
  }

  // 音符旗
  for (var i = 0; i < 8; i++) {
    final x = 7 + i;
    final y = -15 + (i * 0.8).round();
    for (var dy = 0; dy < 2; dy++) {
      pixels.add(_Pixel((x * scale).round(), ((y + dy) * scale).round()));
    }
  }

  return pixels;
}

/// 编码为 ICO 格式
Uint8List _encodeIco(List<img.Image> images) {
  final buffer = BytesBuilder();

  // ICO 文件头
  buffer.addByte(0); // 保留
  buffer.addByte(0);
  buffer.addByte(1); // 类型: 图标
  buffer.addByte(0);
  buffer.addByte(images.length & 0xFF); // 图像数量
  buffer.addByte((images.length >> 8) & 0xFF);

  // 计算目录和数据的偏移量
  final headerSize = 6 + images.length * 16;
  var dataOffset = headerSize;

  final imageDataList = <Uint8List>[];

  // 图像目录
  for (final image in images) {
    final width = image.width;
    final height = image.height;

    // 转换为 PNG
    final pngData = img.encodePng(image);
    imageDataList.add(Uint8List.fromList(pngData));

    // 目录项
    buffer.addByte(width > 255 ? 0 : width); // 宽度
    buffer.addByte(height > 255 ? 0 : height); // 高度
    buffer.addByte(0); // 颜色调色板
    buffer.addByte(0); // 保留
    buffer.addByte(1); // 颜色平面
    buffer.addByte(0);
    buffer.addByte(32); // 每像素位数
    buffer.addByte(0);

    final size = pngData.length;
    buffer.addByte(size & 0xFF);
    buffer.addByte((size >> 8) & 0xFF);
    buffer.addByte((size >> 16) & 0xFF);
    buffer.addByte((size >> 24) & 0xFF);

    buffer.addByte(dataOffset & 0xFF);
    buffer.addByte((dataOffset >> 8) & 0xFF);
    buffer.addByte((dataOffset >> 16) & 0xFF);
    buffer.addByte((dataOffset >> 24) & 0xFF);

    dataOffset += size;
  }

  // 图像数据
  for (final data in imageDataList) {
    buffer.add(data);
  }

  return buffer.toBytes();
}

class _Pixel {
  final int dx;
  final int dy;

  _Pixel(this.dx, this.dy);
}
