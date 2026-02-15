#!/usr/bin/env python3
"""
修复版 ICO 生成脚本
使用 PIL 正确生成包含多个尺寸的 ICO 文件
"""

from PIL import Image, ImageDraw
import struct
import io

def add_rounded_corners(img, radius_percent=20):
    """为图片添加圆角效果"""
    size = min(img.width, img.height)
    radius = int(size * radius_percent / 100)
    
    mask = Image.new('L', (img.width, img.height), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle(
        [(0, 0), (img.width, img.height)],
        radius=radius,
        fill=255
    )
    
    result = img.copy()
    result.putalpha(mask)
    return result

def create_ico_file(input_path, output_path, sizes=None, rounded=True, radius_percent=20, padding_percent=0):
    """
    创建包含多个尺寸的 ICO 文件
    
    Args:
        input_path: 源图片路径
        output_path: 输出 ICO 路径
        sizes: 包含的尺寸列表，默认 [16, 32, 48, 64, 128, 256, 512]
        rounded: 是否添加圆角
        radius_percent: 圆角半径百分比
        padding_percent: 内边距百分比
    """
    if sizes is None:
        sizes = [16, 32, 48, 64, 128, 256, 512]
    
    # 打开源图片
    with Image.open(input_path) as source:
        if source.mode != 'RGBA':
            source = source.convert('RGBA')
        
        # 为每个尺寸创建图像
        images = []
        for size in sizes:
            # 计算目标尺寸（减去内边距）
            target_size = int(size * (1 - padding_percent / 100))
            
            # 缩放图片
            resized = source.copy()
            resized.thumbnail((target_size, target_size), Image.LANCZOS)
            
            # 创建正方形背景
            new_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
            offset = ((size - resized.width) // 2, (size - resized.height) // 2)
            new_img.paste(resized, offset)
            
            # 添加圆角
            if rounded:
                new_img = add_rounded_corners(new_img, radius_percent)
            
            # 转换为 RGB 并保存为 BMP 格式（ICO 需要）
            rgb_img = Image.new('RGB', new_img.size, (255, 255, 255))
            rgb_img.paste(new_img, mask=new_img.split()[3])
            images.append(rgb_img)
    
    # 手动构建 ICO 文件
    num_images = len(images)
    
    # ICO 文件头: 保留(2) + 类型(2) + 图像数量(2)
    ico_header = struct.pack('<HHH', 0, 1, num_images)
    
    # 计算目录项偏移量
    dir_size = 16 * num_images  # 每个目录项 16 字节
    data_offset = 6 + dir_size  # 文件头 6 字节 + 目录
    
    # 构建目录和数据
    directory = b''
    data = b''
    
    for i, img in enumerate(images):
        width = img.width
        height = img.height
        
        # 如果尺寸大于 255，使用 0 表示
        width_byte = width if width < 256 else 0
        height_byte = height if height < 256 else 0
        
        # 将图像保存为 PNG 格式（支持透明度和高质量）
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
    
    print(f"生成ICO: {output_path} (包含 {num_images} 个尺寸: {sizes})")
    import os
    print(f"文件大小: {os.path.getsize(output_path) / 1024:.2f} KB")

if __name__ == "__main__":
    input_path = r"d:\projects\Renaissance\new_logo.png"
    output_path = r"d:\projects\Renaissance\renaissance\windows\runner\resources\app_icon.ico"
    
    create_ico_file(
        input_path,
        output_path,
        sizes=[16, 32, 48, 64, 128, 256, 512],
        rounded=True,
        radius_percent=20,
        padding_percent=0
    )
