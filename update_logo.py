#!/usr/bin/env python3
"""
更新应用logo的脚本
使用新的logo图片生成各个尺寸的图标文件（带圆角）
"""

from PIL import Image, ImageDraw
import os
import sys

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

def resize_image(input_path, output_path, size, keep_aspect=True, rounded=True, radius_percent=20):
    """调整图片尺寸并保存
    
    Args:
        input_path: 输入图片路径
        output_path: 输出图片路径
        size: 目标尺寸
        keep_aspect: 是否保持宽高比
        rounded: 是否添加圆角
        radius_percent: 圆角半径百分比
    """
    with Image.open(input_path) as img:
        # 转换为RGBA模式以支持透明度
        if img.mode != 'RGBA':
            img = img.convert('RGBA')
        
        if keep_aspect:
            # 保持宽高比，使用LANCZOS重采样
            img.thumbnail((size, size), Image.LANCZOS)
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

def create_ico(input_path, output_path, rounded=True, radius_percent=20):
    """创建Windows ICO文件，包含多个尺寸
    
    Args:
        input_path: 输入图片路径
        output_path: 输出ICO文件路径
        rounded: 是否添加圆角
        radius_percent: 圆角半径百分比
    """
    sizes = [16, 32, 48, 64, 128, 256]
    images = []
    
    with Image.open(input_path) as img:
        if img.mode != 'RGBA':
            img = img.convert('RGBA')
        
        for size in sizes:
            resized = img.copy()
            resized.thumbnail((size, size), Image.LANCZOS)
            # 创建正方形背景
            new_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
            offset = ((size - resized.width) // 2, (size - resized.height) // 2)
            new_img.paste(resized, offset)
            
            # 添加圆角（如果需要）
            if rounded:
                new_img = add_rounded_corners(new_img, radius_percent)
            
            images.append(new_img)
    
    # 保存为ICO
    images[0].save(
        output_path,
        format='ICO',
        sizes=[(img.width, img.height) for img in images],
        append_images=images[1:]
    )
    corner_info = " (圆角)" if rounded else ""
    print(f"生成ICO: {output_path}{corner_info}")

def update_app_icons(source_image_path, rounded=True, radius_percent=20):
    """更新应用图标
    
    Args:
        source_image_path: 源图片路径
        rounded: 是否添加圆角
        radius_percent: 圆角半径百分比（默认20%）
    """
    if not os.path.exists(source_image_path):
        print(f"错误: 源图片不存在: {source_image_path}")
        return False
    
    # 确保目录存在
    os.makedirs(ASSETS_DIR, exist_ok=True)
    os.makedirs(WEB_DIR, exist_ok=True)
    
    corner_text = f" (圆角半径: {radius_percent}%)" if rounded else ""
    print(f"使用源图片: {source_image_path}")
    print(f"开始生成图标{corner_text}...")
    print("-" * 50)
    
    # 生成assets/images目录下的图标
    print("\n1. 生成应用图标 (assets/images):")
    for size in ICON_SIZES:
        output_path = os.path.join(ASSETS_DIR, f"app_icon_{size}.png")
        resize_image(source_image_path, output_path, size, rounded=rounded, radius_percent=radius_percent)
    
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
        resize_image(source_image_path, output_path, size, rounded=rounded, radius_percent=radius_percent)
    
    # 生成favicon
    print("\n3. 生成Favicon:")
    resize_image(source_image_path, WEB_FAVICON, 32, rounded=rounded, radius_percent=radius_percent)
    
    # 生成Windows ICO文件
    print("\n4. 生成Windows ICO图标:")
    create_ico(source_image_path, WINDOWS_ICON, rounded=rounded, radius_percent=radius_percent)
    
    print("\n" + "=" * 50)
    print("✅ 所有图标更新完成!")
    print("=" * 50)
    return True

if __name__ == "__main__":
    if len(sys.argv) > 1:
        source_path = sys.argv[1]
    else:
        # 默认查找新logo
        source_path = r"d:\projects\Renaissance\new_logo.png"
    
    # 可以通过参数控制圆角
    # python update_logo.py path/to/image.png --rounded --radius 20
    rounded = True
    radius_percent = 20
    
    if "--no-rounded" in sys.argv:
        rounded = False
    
    for i, arg in enumerate(sys.argv):
        if arg == "--radius" and i + 1 < len(sys.argv):
            try:
                radius_percent = int(sys.argv[i + 1])
            except ValueError:
                print(f"警告: 无效的半径值 '{sys.argv[i + 1]}'，使用默认值 20")
    
    update_app_icons(source_path, rounded=rounded, radius_percent=radius_percent)
