#!/usr/bin/env python3
"""
更新应用logo的脚本
使用新的logo图片生成各个尺寸的图标文件（带圆角）
"""

from PIL import Image, ImageDraw
import os
import sys
import struct
import io

# 配置
ASSETS_DIR = r"d:\projects\Renaissance\renaissance\assets\images"
WEB_DIR = r"d:\projects\Renaissance\renaissance\web\icons"
WEB_FAVICON = r"d:\projects\Renaissance\renaissance\web\favicon.png"
WINDOWS_ICON = r"d:\projects\Renaissance\renaissance\windows\runner\resources\app_icon.ico"

# 需要生成的尺寸列表
ICON_SIZES = [16, 32, 48, 64, 128, 256]

def add_rounded_corners(img, radius_percent=20):
    """为图片添加圆角效果
    
    Args:
        img: PIL Image对象
        radius_percent: 圆角半径百分比（相对于图片尺寸）
    
    Returns:
        带圆角的图片
    """
    # 计算圆角半径（基于图片尺寸的百分比）
    size = min(img.width, img.height)
    radius = int(size * radius_percent / 100)
    
    # 创建圆角蒙版
    mask = Image.new('L', (img.width, img.height), 0)
    draw = ImageDraw.Draw(mask)
    
    # 绘制圆角矩形蒙版
    draw.rounded_rectangle(
        [(0, 0), (img.width, img.height)],
        radius=radius,
        fill=255
    )
    
    # 应用蒙版
    result = img.copy()
    result.putalpha(mask)
    
    return result

def resize_image(input_path, output_path, size, keep_aspect=True, rounded=True, radius_percent=20, padding_percent=0):
    """调整图片尺寸并保存
    
    Args:
        input_path: 输入图片路径
        output_path: 输出图片路径
        size: 目标尺寸
        keep_aspect: 是否保持宽高比
        rounded: 是否添加圆角
        radius_percent: 圆角半径百分比
        padding_percent: 内边距百分比（默认0，即填满整个画布）
    """
    with Image.open(input_path) as img:
        # 转换为RGBA模式以支持透明度
        if img.mode != 'RGBA':
            img = img.convert('RGBA')
        
        if keep_aspect:
            # 计算目标尺寸（减去内边距）
            target_size = int(size * (1 - padding_percent / 100))
            
            # 保持宽高比，使用LANCZOS重采样
            img.thumbnail((target_size, target_size), Image.LANCZOS)
            # 创建正方形背景
            new_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
            # 居中放置
            offset = ((size - img.width) // 2, (size - img.height) // 2)
            new_img.paste(img, offset)
            img = new_img
        else:
            img = img.resize((size, size), Image.LANCZOS)
        
        # 添加圆角（如果需要）
        if rounded:
            img = add_rounded_corners(img, radius_percent)
        
        # 保存为PNG
        img.save(output_path, 'PNG')
        corner_info = " (圆角)" if rounded else ""
        print(f"生成: {output_path} ({size}x{size}){corner_info}")
        return img

def create_ico(input_path, output_path, rounded=True, radius_percent=20, padding_percent=0):
    """创建Windows ICO文件，包含多个尺寸
    
    Args:
        input_path: 输入图片路径
        output_path: 输出ICO文件路径
        rounded: 是否添加圆角
        radius_percent: 圆角半径百分比
        padding_percent: 内边距百分比（默认0，即填满整个画布）
    """
    sizes = [16, 32, 48, 64, 128, 256, 512]
    images = []
    
    with Image.open(input_path) as img:
        if img.mode != 'RGBA':
            img = img.convert('RGBA')
        
        for size in sizes:
            # 计算目标尺寸（减去内边距）
            target_size = int(size * (1 - padding_percent / 100))
            
            resized = img.copy()
            resized.thumbnail((target_size, target_size), Image.LANCZOS)
            # 创建正方形背景
            new_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
            offset = ((size - resized.width) // 2, (size - resized.height) // 2)
            new_img.paste(resized, offset)
            
            # 添加圆角（如果需要）
            if rounded:
                new_img = add_rounded_corners(new_img, radius_percent)
            
            # 转换为 RGB 用于 ICO
            rgb_img = Image.new('RGB', new_img.size, (255, 255, 255))
            rgb_img.paste(new_img, mask=new_img.split()[3])
            images.append(rgb_img)
    
    # 手动构建 ICO 文件（PIL 的 save 方法有问题）
    num_images = len(images)
    
    # ICO 文件头: 保留(2) + 类型(2) + 图像数量(2)
    ico_header = struct.pack('<HHH', 0, 1, num_images)
    
    # 计算目录项偏移量
    dir_size = 16 * num_images  # 每个目录项 16 字节
    data_offset = 6 + dir_size  # 文件头 6 字节 + 目录
    
    # 构建目录和数据
    directory = b''
    data = b''
    
    for img in images:
        width = img.width
        height = img.height
        
        # 如果尺寸大于 255，使用 0 表示
        width_byte = width if width < 256 else 0
        height_byte = height if height < 256 else 0
        
        # 将图像保存为 PNG 格式
        img_buffer = io.BytesIO()
        img.save(img_buffer, format='PNG')
        img_data = img_buffer.getvalue()
        img_size = len(img_data)
        
        # 目录项: 宽度(1) + 高度(1) + 颜色数(1) + 保留(1) + 颜色平面(2) + 位深度(2) + 数据大小(4) + 数据偏移(4)
        directory += struct.pack('<BBBBHHII',
            width_byte,      # 宽度
            height_byte,     # 高度
            0,               # 颜色数（0 = 大于256色）
            0,               # 保留
            1,               # 颜色平面
            32,              # 位深度
            img_size,        # 数据大小
            data_offset      # 数据偏移
        )
        
        data += img_data
        data_offset += img_size
    
    # 写入文件
    with open(output_path, 'wb') as f:
        f.write(ico_header)
        f.write(directory)
        f.write(data)
    
    corner_info = " (圆角)" if rounded else ""
    file_size_kb = os.path.getsize(output_path) / 1024
    print(f"生成ICO: {output_path}{corner_info} ({file_size_kb:.2f} KB)")

def update_app_icons(source_image_path, rounded=True, radius_percent=20, padding_percent=0):
    """更新应用图标
    
    Args:
        source_image_path: 源图片路径
        rounded: 是否添加圆角
        radius_percent: 圆角半径百分比（默认20%）
        padding_percent: 内边距百分比（默认0，即填满整个画布）
    """
    if not os.path.exists(source_image_path):
        print(f"错误: 源图片不存在: {source_image_path}")
        return False
    
    # 确保目录存在
    os.makedirs(ASSETS_DIR, exist_ok=True)
    os.makedirs(WEB_DIR, exist_ok=True)
    
    corner_text = f" (圆角半径: {radius_percent}%)" if rounded else ""
    padding_text = f" (内边距: {padding_percent}%)" if padding_percent > 0 else ""
    print(f"使用源图片: {source_image_path}")
    print(f"开始生成图标{corner_text}{padding_text}...")
    print("-" * 50)
    
    # 生成assets/images目录下的图标
    print("\n1. 生成应用图标 (assets/images):")
    for size in ICON_SIZES:
        output_path = os.path.join(ASSETS_DIR, f"app_icon_{size}.png")
        resize_image(source_image_path, output_path, size, rounded=rounded, radius_percent=radius_percent, padding_percent=padding_percent)
    
    # 生成web图标
    print("\n2. 生成Web图标 (web/icons):")
    web_sizes = {
        "Icon-192.png": 192,
        "Icon-512.png": 512,
        "Icon-maskable-192.png": 192,
        "Icon-maskable-512.png": 512,
    }
    
    for filename, size in web_sizes.items():
        output_path = os.path.join(WEB_DIR, filename)
        resize_image(source_image_path, output_path, size, rounded=rounded, radius_percent=radius_percent, padding_percent=padding_percent)
    
    # 生成favicon
    print("\n3. 生成Favicon:")
    resize_image(source_image_path, WEB_FAVICON, 32, rounded=rounded, radius_percent=radius_percent, padding_percent=padding_percent)
    
    # 生成Windows ICO文件
    print("\n4. 生成Windows ICO图标:")
    create_ico(source_image_path, WINDOWS_ICON, rounded=rounded, radius_percent=radius_percent, padding_percent=padding_percent)
    
    print("\n" + "=" * 50)
    print("✅ 所有图标更新完成!")
    print("=" * 50)
    return True

if __name__ == "__main__":
    if len(sys.argv) > 1 and not sys.argv[1].startswith("--"):
        source_path = sys.argv[1]
    else:
        # 默认查找新logo
        source_path = r"d:\projects\Renaissance\new_logo.png"
    
    # 可以通过参数控制圆角和内边距
    # python update_logo.py path/to/image.png --radius 20 --padding 10
    rounded = True
    radius_percent = 20
    padding_percent = 0
    
    if "--no-rounded" in sys.argv:
        rounded = False
    
    for i, arg in enumerate(sys.argv):
        if arg == "--radius" and i + 1 < len(sys.argv):
            try:
                radius_percent = int(sys.argv[i + 1])
            except ValueError:
                print(f"警告: 无效的半径值 '{sys.argv[i + 1]}'，使用默认值 20")
        elif arg == "--padding" and i + 1 < len(sys.argv):
            try:
                padding_percent = int(sys.argv[i + 1])
            except ValueError:
                print(f"警告: 无效的内边距值 '{sys.argv[i + 1]}'，使用默认值 0")
    
    update_app_icons(source_path, rounded=rounded, radius_percent=radius_percent, padding_percent=padding_percent)
