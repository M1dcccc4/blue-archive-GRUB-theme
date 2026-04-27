import os
import cv2
import numpy as np

def invert_color_keep_alpha(image):
    """
    对图像进行颜色反色，保留 alpha 通道不变。
    支持：3通道(RGB/BGR)、4通道(RGBA)、1通道(灰度)。
    """
    if image is None:
        return None

    # 获取通道数
    if len(image.shape) == 2:
        # 灰度图，直接反色
        inverted = 255 - image
    else:
        h, w, c = image.shape
        if c == 3:
            # 三通道，全部取反
            inverted = 255 - image
        elif c == 4:
            # 四通道：前三个颜色通道取反，alpha 通道保持不变
            inverted = np.zeros_like(image)
            inverted[:, :, :3] = 255 - image[:, :, :3]
            inverted[:, :, 3] = image[:, :, 3]
        else:
            raise ValueError(f"不支持的通道数: {c}")
    return inverted

def process_png_files(root_dir='.'):
    """
    遍历 root_dir 下所有 .png 文件（包括子目录），反色后覆盖保存。
    """
    for dirpath, dirnames, filenames in os.walk(root_dir):
        for filename in filenames:
            if not filename.lower().endswith('.png'):
                continue

            file_path = os.path.join(dirpath, filename)
            print(f"处理: {file_path}")

            # 读取 PNG，保留 alpha 通道（IMREAD_UNCHANGED）
            img = cv2.imread(file_path, cv2.IMREAD_UNCHANGED)
            if img is None:
                print(f"  警告：无法读取文件 {file_path}，跳过")
                continue

            # 反色处理
            inverted = invert_color_keep_alpha(img)

            # 保存（覆盖原文件）
            success = cv2.imwrite(file_path, inverted)
            if success:
                print(f"  已保存: {file_path}")
            else:
                print(f"  错误：保存失败 {file_path}")

if __name__ == "__main__":
    # 可修改为需要遍历的目标目录，默认当前目录
    target_dir = "."
    process_png_files(target_dir)