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
import json
import numpy as np
from pathlib import Path

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

ARK_API_KEY_V = os.environ.get("ARK_API_KEY_V")
if not ARK_API_KEY_V:
    raise RuntimeError("请先在环境变量 ARK_API_KEY_V 中设置 API key for embedding")

ARK_BASE_URL = "https://ark.cn-beijing.volces.com/api/v3"
MODEL = "doubao-seededit-3-0-i2i-250628"
PROMPTS = [
    ("作为AI图像生成模型，当我上传一张不含人物的风景照片时，请在图像中自然融入逼真的人物。人物应呈现出仿佛正在此地进行专业摄影的姿态，动作优雅且符合网红或时尚摄影的风格。确保人物的服装、造型和配饰与背景的场景、气候及氛围高度协调，呈现出和谐的整体效果。人物需与背景在光影、透视和比例上完美融合，仅添加人物，不更改原有风景。人物的详细信息如下："),
    ("作为AI图像生成模型，当我上传一张无人物的风景照片时，请在画面中自然添加真实的人物，人物应看起来像是在此景点进行时尚拍摄，姿态自然且具有吸引力，符合网红或高端摄影的审美。人物的穿搭、风格及配饰需与背景环境、天气和氛围相匹配，确保整体协调。人物与背景的光影、透视需无缝融合，仅添加符合描述的人物，不改变原有风景。人物的详细信息如下："),
    ("作为AI图像生成模型，当我上传一张不含人物的风景照片时，请在图像中加入真实感十足的人物，人物应像是正在此地进行专业写真拍摄，姿态优雅且符合网红或时尚摄影的风格。确保人物的服饰、造型和配饰与背景的地点、天气及氛围完美契合，呈现自然和谐的效果。人物需与背景在光影和透视上高度融合，仅添加人物，不修改原有风景。人物的详细信息如下："),
    ("作为AI图像生成模型，当我上传一张没有人物的风景照片时，请在画面中自然融入栩栩如生的人物，人物应呈现出在该场景进行艺术化拍摄的姿态，动作优雅且符合网红或专业摄影的风格。人物的服装、造型和配饰需与背景的地点、气候及整体氛围相协调，确保画面整体美感。人物与背景的光影、透视需完全融合，仅添加符合描述的人物，不更改原有风景。人物的详细信息如下：")
]

PROMPTS_WEITIAO = [
    ("对于这张图像我想调整以下的内容："),
    ("对于这张图像我想调整以下的内容："),
    ("对于这张图像我想调整以下的内容："),
    ("对于这张图像我想调整以下的内容：")
]

SEEDS = [123, 123, 123, 123]  # 不同的 seed 值
GUIDANCE_SCALE = 5.5
SIZE = "adaptive"
WATERMARK = True

# 初始化多个客户端（每个 API key 一个客户端）
ark_clients = [Ark(base_url=ARK_BASE_URL, api_key=key) for key in API_KEYS]
ark_client_v = Ark(api_key=ARK_API_KEY_V)

def image_to_base64(image_path):
    """Convert an image file to base64 string."""
    try:
        with open(image_path, "rb") as image_file:
            encoded_string = base64.b64encode(image_file.read()).decode('utf-8')
            # Determine MIME type based on file extension
            ext = Path(image_path).suffix.lower()
            mime_types = {
                '.jpg': 'image/jpeg',
                '.jpeg': 'image/jpeg',
                '.png': 'image/png',
                '.bmp': 'image/bmp',
                '.gif': 'image/gif'
            }
            mime_type = mime_types.get(ext, 'image/jpeg')
            return f"data:{mime_type};base64,{encoded_string}"
    except Exception as e:
        print(f"Error converting {image_path} to base64: {str(e)}")
        return None

def generate_embedding(image_path, client):
    """Generate embedding for a single image using base64 encoding."""
    try:
        base64_image = image_to_base64(image_path)
        if not base64_image:
            return None
            
        resp = client.multimodal_embeddings.create(
            model="doubao-embedding-vision-250615",
            encoding_format="float",
            input=[
                {"text": "Image embedding", "type": "text"},
                {"image_url": {"url": base64_image}, "type": "image_url"}
            ]
        )
        return resp.data.embedding
    except Exception as e:
        print(f"Error processing {image_path}: {str(e)}")
        return None

def load_all_embeddings(embed_dir):
    """Load all embeddings from JSON files in the directory."""
    embeddings = []
    for filename in os.listdir(embed_dir):
        if filename.endswith(".json"):
            file_path = os.path.join(embed_dir, filename)
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
                embeddings.append((data["path"], data["embedding"]))
    return embeddings

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

def generate_image_from_local_to_temp(image_path, client, version, prompt, seed):
    """
    调用 ARK 接口生成图片并下载到临时文件，返回临时文件路径和版本号。
    """
    try:
        # 压缩后转 base64
        b64 = prepare_image_base64(image_path, max_size=1024, quality=85)

        # 调用 SDK 接口
        imagesResponse = client.images.generate(
            model=MODEL,
            prompt=prompt,
            image="data:image/jpeg;base64," + b64,
            seed=seed,
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
    处理单个文件：根据子文件夹的JSON flag决定逻辑。
    - 如果 flag 是 zhidao，则使用修改后的prompt生成四张图片，保存到 background_person（保持目录结构）。
    - 如果 flag 是 tuijian，则生成embedding，找到相似度最高的四张图，从assets复制到 background_person（保持目录结构）。
    - 如果 flag 是 weitiao，则仅读取style字段，拼接到prompt中，生成四张图片，保存到 background_person（保持目录结构）。
    成功后把原文件移动到 moved_background（保持目录结构）。
    """
    # 相对于 UPLOAD_DIR 的路径
    rel_path = os.path.relpath(filepath, UPLOAD_DIR)
    rel_dir = os.path.dirname(rel_path)  # 可能是 "" 或 "a" / "a/b"

    basename = os.path.basename(filepath)
    name_without_ext = os.path.splitext(basename)[0]

    # 构造输出路径（保持子目录）
    output_dir = os.path.join(XIANGAO_DIR, rel_dir)
    os.makedirs(output_dir, exist_ok=True)
    output_paths = [os.path.join(output_dir, f"{name_without_ext}_{i+1}.jpg") for i in range(4)]

    moved_dir = os.path.join(MOVED_DIR, rel_dir)
    os.makedirs(moved_dir, exist_ok=True)
    moved_target = os.path.join(moved_dir, basename)

    print(f"[{datetime.datetime.now().isoformat()}] 开始处理: {rel_path}")

    # 查找子文件夹下的 JSON 文件（假设只有一个）
    json_dir = os.path.join(UPLOAD_DIR, rel_dir)
    json_files = [f for f in os.listdir(json_dir) if f.endswith('.json')]
    if not json_files:
        print(f"[{datetime.datetime.now().isoformat()}] 未找到 JSON 文件，跳过: {rel_path}")
        return

    json_path = os.path.join(json_dir, json_files[0])
    try:
        with open(json_path, 'r', encoding='utf-8') as f:
            json_data = json.load(f)
    except Exception as e:
        print(f"[{datetime.datetime.now().isoformat()}] 读取 JSON 失败: {e}")
        return

    flag = json_data.get("flag", "")
    if flag not in ["zhidao", "tuijian", "weitiao"]:
        print(f"[{datetime.datetime.now().isoformat()}] 无效 flag: {flag}，跳过: {rel_path}")
        return

    tmp_files = []
    try:
        if flag == "zhidao":
            # 读取字段并融入 prompt
            gender = json_data.get("gender", "")
            age = json_data.get("age", "")
            height = json_data.get("height", "")
            weight = json_data.get("weight", "")
            peopleCount = json_data.get("peopleCount", "")
            style = json_data.get("style", "")
            detail_str = f" 人物性别: {gender}, 年龄: {age}, 身高: {height}, 体重: {weight}, 人数: {peopleCount}, 照片风格: {style}。"
            modified_prompts = [p + detail_str for p in PROMPTS]

            # 并发调用四个 API
            with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:
                futures = [
                    executor.submit(generate_image_from_local_to_temp, filepath, ark_clients[i], i+1, modified_prompts[i], SEEDS[i])
                    for i in range(4)
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

        elif flag == "weitiao":
            # 仅读取 style 字段并融入 prompt
            style = json_data.get("style", "")
            detail_str = f" 照片风格: {style}。"
            modified_prompts = [p + detail_str for p in PROMPTS_WEITIAO]

            # 并发调用四个 API
            with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:
                futures = [
                    executor.submit(generate_image_from_local_to_temp, filepath, ark_clients[i], i+1, modified_prompts[i], SEEDS[i])
                    for i in range(4)
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

        elif flag == "tuijian":
            # 生成 embedding
            embedding = generate_embedding(filepath, ark_client_v)
            if not embedding:
                print(f"[{datetime.datetime.now().isoformat()}] 生成 embedding 失败，跳过: {rel_path}")
                return

            # 加载所有 embeddings
            embed_dir = os.path.join(BASE_DIR, "database", "embeddings_output")
            all_embs = load_all_embeddings(embed_dir)

            if not all_embs:
                print(f"[{datetime.datetime.now().isoformat()}] 未找到任何 embeddings，跳过: {rel_path}")
                return

            # 计算相似度
            sims = []
            for path, other_emb in all_embs:
                if np.linalg.norm(embedding) == 0 or np.linalg.norm(other_emb) == 0:
                    sim = 0.0
                else:
                    sim = np.dot(embedding, other_emb) / (np.linalg.norm(embedding) * np.linalg.norm(other_emb))
                sims.append((path, sim))

            # 选择 top 4
            top4 = sorted(sims, key=lambda x: x[1], reverse=True)[:4]

            # 复制 assets 中的图片
            for i, (path, sim) in enumerate(top4):
                asset_path = path.replace("database", "assets", 1)
                if os.path.exists(asset_path):
                    output_path = output_paths[i]
                    shutil.copy(asset_path, output_path)
                    print(f"[{datetime.datetime.now().isoformat()}] 复制 top {i+1} (sim: {sim:.4f}): {asset_path} -> {output_path}")
                else:
                    print(f"[{datetime.datetime.now().isoformat()}] assets 文件不存在: {asset_path}")

        # 所有处理完成后移动原文件
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
