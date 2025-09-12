import os
import time
import base64
import datetime
import shutil
import tempfile
import requests
from PIL import Image
import numpy as np
from volcenginesdkarkruntime import Ark

# 配置项
BASE_DIR = os.path.abspath(os.path.dirname(__file__))  # 或者直接指定你想要的路径
UPLOAD_DIR = os.path.join(BASE_DIR, "uploads")
XIANGAO_DIR = os.path.join(BASE_DIR, "xiangao")
MOVED_DIR = os.path.join(BASE_DIR, "moved_images")
POLL_INTERVAL = 3  # 秒，轮询间隔
ALLOWED_EXTS = {".jpg", ".jpeg", ".png", ".webp", ".bmp", ".tiff"}

# ARK / 模型 配置
API_KEY = os.environ.get("ARK_API_KEY")
if not API_KEY:
    raise RuntimeError("请先在环境变量 ARK_API_KEY 中设置 ARK_API_KEY")

ARK_BASE_URL = "https://ark.cn-beijing.volces.com/api/v3"
MODEL = "doubao-seededit-3-0-i2i-250628"
PROMPT = ("请为这张图的人物生成简单的线稿，要求仅黑色线条，不需要很多细节，"
          "大约在10-20笔线条左右，描绘出人物的外形和动作（不需要绘制背景，让背景纯白即可），"
          "且与原人物的动作、位置、形象都一致。另外，我希望生成的简笔画可以卡通风格一些，不要偏向写实风格")
GUIDANCE_SCALE = 5.5
SEED = 123
SIZE = "adaptive"
WATERMARK = True

# 初始化客户端（复用）
ark_client = Ark(base_url=ARK_BASE_URL, api_key=API_KEY)


def make_background_transparent(input_path, output_path, threshold=200):
    """把白色背景变透明并保存为 PNG"""
    img = Image.open(input_path).convert("RGBA")
    data = np.array(img)
    r, g, b, a = data.T
    white_areas = (r > threshold) & (g > threshold) & (b > threshold)
    data[..., -1][white_areas.T] = 0
    transparent_img = Image.fromarray(data)
    transparent_img.save(output_path, "PNG")


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


def generate_image_from_local_to_temp(image_path):
    """
    调用 ARK 接口生成图片并下载到临时文件，返回临时文件路径。
    """
    # 压缩后转 base64
    b64 = prepare_image_base64(image_path, max_size=1024, quality=85)

    # 调用 SDK 接口
    imagesResponse = ark_client.images.generate(
        model=MODEL,
        prompt=PROMPT,
        image="data:image/jpeg;base64," + b64,  # 注意这里改成 jpeg
        seed=SEED,
        guidance_scale=GUIDANCE_SCALE,
        size=SIZE,
        watermark=WATERMARK
    )

    # 下载到临时文件
    url = imagesResponse.data[0].url
    resp = requests.get(url, timeout=30)
    resp.raise_for_status()
    fd, tmp_path = tempfile.mkstemp(suffix=".jpg")
    os.close(fd)
    with open(tmp_path, "wb") as f:
        f.write(resp.content)
    return tmp_path


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
    处理单个文件：调用 ARK 生成、背景透明化并保存到 xiangao（保持目录结构），
    成功后把原文件移动到 moved_images（保持目录结构）。
    """
    # 相对于 UPLOAD_DIR 的路径
    rel_path = os.path.relpath(filepath, UPLOAD_DIR)
    rel_dir = os.path.dirname(rel_path)  # 可能是 "" 或 "a" / "a/b"

    basename = os.path.basename(filepath)
    name_without_ext = os.path.splitext(basename)[0]
    output_filename = f"{name_without_ext}.png"

    # 构造输出路径（保持子目录）
    output_dir = os.path.join(XIANGAO_DIR, rel_dir)
    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.join(output_dir, output_filename)

    moved_dir = os.path.join(MOVED_DIR, rel_dir)
    os.makedirs(moved_dir, exist_ok=True)
    moved_target = os.path.join(moved_dir, basename)

    print(f"[{datetime.datetime.now().isoformat()}] 开始处理: {rel_path}")
    tmp_generated = None
    try:
        # 调用生成接口并下载到临时文件
        tmp_generated = generate_image_from_local_to_temp(filepath)
        # 把背景变透明并保存到 xiangao
        make_background_transparent(tmp_generated, output_path, threshold=200)

        # 如果 moved_images 中已存在同名文件 → 备份
        if os.path.exists(moved_target):
            ts = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
            backup_target = f"{moved_target}.{ts}.bak"
            os.rename(moved_target, backup_target)

        shutil.move(filepath, moved_target)
        print(f"[{datetime.datetime.now().isoformat()}] 处理完成: 输出-> {output_path}，原图已移动到 {moved_target}")
    except Exception as e:
        print(f"[{datetime.datetime.now().isoformat()}] 处理失败: {rel_path}，错误: {e}")
        # 出错则保留原文件在 uploads
    finally:
        if tmp_generated and os.path.exists(tmp_generated):
            try:
                os.remove(tmp_generated)
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
