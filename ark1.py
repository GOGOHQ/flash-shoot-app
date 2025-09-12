import os
import time
import base64
import datetime
import shutil
import tempfile
import requests
from PIL import Image
import concurrent.futures
from volcenginesdkarkruntime import Ark

# 配置项
BASE_DIR = os.path.abspath(os.path.dirname(__file__))
UPLOAD_DIR = os.path.join(BASE_DIR, "background")
XIANGAO_DIR = os.path.join(BASE_DIR, "background_person")
MOVED_DIR = os.path.join(BASE_DIR, "moved_background")
POLL_INTERVAL = 3  # 秒，轮询间隔
ALLOWED_EXTS = {".jpg", ".jpeg", ".png", ".webp", ".bmp", ".tiff"}

# ARK / 模型 配置
API_KEYS = [
    os.environ.get("ARK_API_KEY_1"),
    os.environ.get("ARK_API_KEY_2"),
    os.environ.get("ARK_API_KEY_3"),
    os.environ.get("ARK_API_KEY_4")
]
for i, key in enumerate(API_KEYS, 1):
    if not key:
        raise RuntimeError(f"请先在环境变量 ARK_API_KEY_{i} 中设置 API key")

ARK_BASE_URL = "https://ark.cn-beijing.volces.com/api/v3"
MODEL = "doubao-seededit-3-0-i2i-250628"
PROMPT = ("我希望你作为AI图像生成模型，当我上传一张风景照片（没有人物）时，请在图片中自然地加入一个真实的人物。这个人要看起来像是真的在这个旅游景点拍写真，姿势自然好看（类似网红或专业摄影的风格）。请确保人物的穿搭、风格和配饰与背景的环境相协调，能够匹配地点、天气和整体氛围。人物要与背景自然融合，包括光影和透视关系，不能改变原有风景，只添加符合描述的人物即可。")
GUIDANCE_SCALE = 5.5
SEED = 123
SIZE = "adaptive"
WATERMARK = True

# 初始化多个客户端（每个 API key 一个客户端）
ark_clients = [Ark(base_url=ARK_BASE_URL, api_key=key) for key in API_KEYS]

def prepare_image_base64(image_path, max_size=1024, quality=85):
    """
    压缩并转换图片为 base64。
    - max_size: 限制最长边
    - quality: JPEG/WEBP 压缩质量
    """
    from io import BytesIO
    img = Image.open(image_path).convert("RGB")

    # 等比缩放
    w, h = img.size
    scale = min(max_size / max(w, h), 1.0)  # 只缩小，不放大
    if scale < 1.0:
        new_w, new_h = int(w * scale), int(h * scale)
        img = img.resize((new_w, new_h), Image.LANCZOS)

    # 保存到内存 buffer
    buf = BytesIO()
    img.save(buf, format="JPEG", quality=quality, optimize=True)
    b64 = base64.b64encode(buf.getvalue()).decode("utf-8")
    return b64

def generate_image_from_local_to_temp(image_path, client, version):
    """
    调用 ARK 接口生成图片并下载到临时文件，返回临时文件路径和版本号。
    """
    try:
        # 压缩后转 base64
        b64 = prepare_image_base64(image_path, max_size=1024, quality=85)

        # 调用 SDK 接口
        imagesResponse = client.images.generate(
            model=MODEL,
            prompt=PROMPT,
            image="data:image/jpeg;base64," + b64,
            seed=SEED,
            guidance_scale=GUIDANCE_SCALE,
            size=SIZE,
            watermark=WATERMARK
        )

        # 下载到临时文件
        url = imagesResponse.data[0].url
        resp = requests.get(url, timeout=30)
        resp.raise_for_status()
        fd, tmp_path = tempfile.mkstemp(suffix=".png")  # 直接保存为 PNG
        os.close(fd)
        with open(tmp_path, "wb") as f:
            f.write(resp.content)
        return tmp_path, version
    except Exception as e:
        print(f"[{datetime.datetime.now().isoformat()}] 版本 {version} 生成失败: {e}")
        return None, version

def safe_is_image_readable(path):
    """尝试用 PIL 打开图片，判断是否可读（用于避免读取到正在写入中的文件）"""
    try:
        with Image.open(path) as img:
            img.verify()
        return True
    except Exception:
        return False

def ensure_dirs():
    for d in (UPLOAD_DIR, XIANGAO_DIR, MOVED_DIR):
        os.makedirs(d, exist_ok=True)

def process_one_file(filepath):
    """
    处理单个文件：使用四个 API key 并发调用 ARK 生成四张图片，保存到 xiangao（保持目录结构），
    成功后把原文件移动到 moved_images（保持目录结构）。
    """
    # 相对于 UPLOAD_DIR 的路径
    rel_path = os.path.relpath(filepath, UPLOAD_DIR)
    rel_dir = os.path.dirname(rel_path)  # 可能是 "" 或 "a" / "a/b"

    basename = os.path.basename(filepath)
    name_without_ext = os.path.splitext(basename)[0]

    # 构造输出路径（保持子目录）
    output_dir = os.path.join(XIANGAO_DIR, rel_dir)
    os.makedirs(output_dir, exist_ok=True)
    output_paths = [os.path.join(output_dir, f"{name_without_ext}_v{i+1}.png") for i in range(4)]

    moved_dir = os.path.join(MOVED_DIR, rel_dir)
    os.makedirs(moved_dir, exist_ok=True)
    moved_target = os.path.join(moved_dir, basename)

    print(f"[{datetime.datetime.now().isoformat()}] 开始处理: {rel_path}")

    # 并发调用四个 API
    tmp_files = []
    try:
        with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:
            futures = [
                executor.submit(generate_image_from_local_to_temp, filepath, client, i+1)
                for i, client in enumerate(ark_clients)
            ]
            results = concurrent.futures.wait(futures, timeout=60)  # 设置超时

        # 处理生成结果
        for future in results.done:
            tmp_path, version = future.result()
            if tmp_path:
                output_path = output_paths[version-1]
                shutil.move(tmp_path, output_path)
                print(f"[{datetime.datetime.now().isoformat()}] 版本 v{version} 生成成功: {output_path}")
                tmp_files.append(tmp_path)
            else:
                print(f"[{datetime.datetime.now().isoformat()}] 版本 v{version} 生成失败，跳过")

        # 所有生成完成后移动原文件
        if os.path.exists(moved_target):
            ts = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
            backup_target = f"{moved_target}.{ts}.bak"
            os.rename(moved_target, backup_target)

        shutil.move(filepath, moved_target)
        print(f"[{datetime.datetime.now().isoformat()}] 原图已移动到: {moved_target}")

    except Exception as e:
        print(f"[{datetime.datetime.now().isoformat()}] 处理失败: {rel_path}，错误: {e}")
        # 出错则保留原文件在 uploads
    finally:
        # 清理临时文件
        for tmp_path in tmp_files:
            if tmp_path and os.path.exists(tmp_path):
                try:
                    os.remove(tmp_path)
                except Exception:
                    pass

def iter_all_images(root_dir):
    """递归遍历 root_dir 下的所有图片文件，返回文件路径生成器"""
    for dirpath, dirnames, filenames in os.walk(root_dir):
        for fname in filenames:
            if fname.startswith("."):
                continue
            ext = os.path.splitext(fname)[1].lower()
            if ext not in ALLOWED_EXTS:
                continue
            fpath = os.path.join(dirpath, fname)
            yield fpath

def main_loop():
    ensure_dirs()
    print(f"监控目录: {UPLOAD_DIR}，输出目录: {XIANGAO_DIR}，已处理原图目录: {MOVED_DIR}")
    try:
        while True:
            for fpath in sorted(iter_all_images(UPLOAD_DIR)):
                # 检查文件是否可读（避免部分写入）
                if not safe_is_image_readable(fpath):
                    continue
                # 处理文件
                process_one_file(fpath)
            time.sleep(POLL_INTERVAL)
    except KeyboardInterrupt:
        print("退出监控")

if __name__ == "__main__":
    main_loop()
