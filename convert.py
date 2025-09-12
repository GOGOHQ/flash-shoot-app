import os
from PIL import Image

# 根目录
base_dir = "/Users/sixteendog/Downloads/数据库"

# 遍历子文件夹
for folder in os.listdir(base_dir):
    folder_path = os.path.join(base_dir, folder)
    if os.path.isdir(folder_path):  # 确保是文件夹
        files = [f for f in os.listdir(folder_path) if os.path.isfile(os.path.join(folder_path, f))]

        # 排序，保证顺序稳定
        files.sort()

        for i, filename in enumerate(files, start=1):
            old_path = os.path.join(folder_path, filename)

            try:
                # 打开图片
                img = Image.open(old_path).convert("RGB")  # 转成 RGB，避免 PNG 透明层报错
                new_name = f"{i:03d}.jpg"
                new_path = os.path.join(folder_path, new_name)

                # 保存为 JPG
                img.save(new_path, "JPEG", quality=95)

                # 删除原文件（避免堆积不同格式）
                if old_path != new_path:
                    os.remove(old_path)

                print(f"{folder} : {filename} -> {new_name}")

            except Exception as e:
                print(f"❌ 转换失败: {old_path}, 错误: {e}")

print("✅ 全部转换并重命名完成！")
