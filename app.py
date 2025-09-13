from flask import Flask, request, jsonify, send_from_directory
import os
import time
import shutil
import glob
import json

app = Flask(__name__)

UPLOAD_FOLDER = 'uploads'
MOVED_FOLDER = 'moved'
XIANGAO_FOLDER = 'xiangao'
BACK_GROUND = 'background'
BACK_GROUND_PERSON = 'background_person'

os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(MOVED_FOLDER, exist_ok=True)
os.makedirs(XIANGAO_FOLDER, exist_ok=True)
os.makedirs(BACK_GROUND, exist_ok=True)
os.makedirs(BACK_GROUND_PERSON, exist_ok=True)


def get_user_folder(base, user_id):
    folder = os.path.join(base, f"user_{user_id}")
    os.makedirs(folder, exist_ok=True)
    return folder


def timestamp_filename(ext):
    """根据当前时间戳生成文件名"""
    ts = int(time.time() * 1000)  # 毫秒
    return f"{ts}{ext}"

#保存到background文件夹
@app.route('/background', methods=['POST'])
def background():
    # 1. metadata 解析
    metadata_str = request.form.get('metadata')
    if not metadata_str:
        return jsonify({'error': 'metadata required'}), 400

    try:
        metadata = json.loads(metadata_str)  # 解析成 dict
    except Exception as e:
        return jsonify({'error': f'invalid metadata json: {e}'}), 400

    user_id = metadata.get("user_id")
    if not user_id:
        return jsonify({'error': 'user_id required in metadata'}), 400
    user_background_folder = get_user_folder(BACK_GROUND, user_id)
    # 3. 处理文件上传
    saved = []
    flag = metadata.get("flag")
    if not flag:
        return jsonify({'error': 'flag required in metadata'}), 400
    if flag == 'weitiao':
      background_files = []
      user_background_person_folder = get_user_folder(BACK_GROUND_PERSON, user_id)
      os.makedirs(user_background_person_folder, exist_ok=True)
      filenames = request.form.getlist('filenames') 
      if not user_id or not filenames:
          return jsonify({'error': 'user_id and filenames required'}), 400
      for fname in filenames:
        src = os.path.join(user_background_person_folder, fname)
        if not os.path.exists(src):
            continue
        # 保存到 uploads
        dest_background = os.path.join(user_background_folder, fname)
        shutil.copy(src, dest_background)
        saved.append(f"user_{user_id}/{fname}")
      # 2. 保存 metadata.json
      metadata_path = os.path.join(user_background_folder, "metadata.json")
      with open(metadata_path, "w", encoding="utf-8") as f:
          json.dump(metadata, f, ensure_ascii=False, indent=2)
      return jsonify({
        'saved': saved,
        'metadata_file': metadata_path
    }), 200

    files = request.files.getlist('files')
    

    for f in files:
        if f.filename == '':
            continue
        ext = os.path.splitext(f.filename)[1].lower()
        new_filename = timestamp_filename(ext)

        background_path = os.path.join(user_background_folder, new_filename)
        f.save(background_path)
        saved.append(background_path)
          # 2. 保存 metadata.json
    metadata_path = os.path.join(user_background_folder, "metadata.json")
    with open(metadata_path, "w", encoding="utf-8") as f:
        json.dump(metadata, f, ensure_ascii=False, indent=2)
    return jsonify({
        'saved': saved,
        'metadata_file': metadata_path
    }), 200

@app.route('/transfer_background', methods=['POST'])
def transfer_background():
    """
    将选中的 background_person 图片复制到 uploads 和 moved 文件夹，然后删除 background_person
    """
    user_id = request.form.get('user_id')
    filenames = request.form.getlist('filenames')  # 多选文件名列表

    if not user_id or not filenames:
        return jsonify({'error': 'user_id and filenames required'}), 400

    uploaded_files = []
    moved_files = []
    deleted_files = []

    user_background_folder = get_user_folder(BACK_GROUND_PERSON, user_id)
    user_upload_folder = get_user_folder(UPLOAD_FOLDER, user_id)
    user_moved_folder = get_user_folder(MOVED_FOLDER, user_id)

    os.makedirs(user_upload_folder, exist_ok=True)
    os.makedirs(user_moved_folder, exist_ok=True)

    for fname in filenames:
        src = os.path.join(user_background_folder, fname)
        if not os.path.exists(src):
            continue

        # 保存到 uploads
        dest_upload = os.path.join(user_upload_folder, fname)
        shutil.copy(src, dest_upload)
        uploaded_files.append(f"user_{user_id}/{fname}")

        # 保存到 moved
        dest_moved = os.path.join(user_moved_folder, fname)
        shutil.copy(src, dest_moved)
        moved_files.append(f"user_{user_id}/{fname}")

    # 查找图片文件
    pattern = os.path.join(user_background_folder, '*')
    files = glob.glob(pattern)
    for f in files:
      try:
          os.remove(f)
          deleted_files.append(os.path.basename(f))
      except Exception as e:
          print(f"Failed to delete {f}: {e}")

    return jsonify({
        'uploaded': uploaded_files,
        'moved': moved_files,
        'deleted': deleted_files
    }), 200

@app.route('/upload', methods=['POST'])
def upload():
    user_id = request.form.get('user_id')
    if not user_id:
        return jsonify({'error': 'user_id required'}), 400

    files = request.files.getlist('files')
    saved = []

    user_upload_folder = get_user_folder(UPLOAD_FOLDER, user_id)
    user_moved_folder = get_user_folder(MOVED_FOLDER, user_id)

    for f in files:
        if f.filename == '':
            continue
        ext = os.path.splitext(f.filename)[1].lower()  # 保留原扩展名
        new_filename = timestamp_filename(ext)

        upload_path = os.path.join(user_upload_folder, new_filename)
        f.save(upload_path)
        saved.append(upload_path)

        # 移动到 moved
        moved_path = os.path.join(user_moved_folder, new_filename)
        if os.name == 'nt':
            os.system(f'copy "{upload_path}" "{moved_path}"')
        else:
            os.system(f'cp "{upload_path}" "{moved_path}"')

    return jsonify({'saved': saved}), 200

@app.route('/background_person', methods=['GET'])
def list_background_person():
    user_id = request.args.get('user_id')
    if not user_id:
        return jsonify({'error': 'user_id required'}), 400

    files_list = []
    user_folder = get_user_folder(BACK_GROUND_PERSON, user_id)

    for fname in os.listdir(user_folder):
        if fname.lower().endswith(('.jpg', '.jpeg', '.png', '.gif')):
            files_list.append(f"/background_person/user_{user_id}/{fname}")

    return jsonify(sorted(files_list, reverse=True)), 200  # 倒序返回

@app.route('/moved', methods=['GET'])
def list_moved():
    user_id = request.args.get('user_id')
    if not user_id:
        return jsonify({'error': 'user_id required'}), 400

    moved_files = []
    user_moved_folder = get_user_folder(MOVED_FOLDER, user_id)
    for fname in os.listdir(user_moved_folder):
        if fname.lower().endswith(('.jpg', '.jpeg', '.png', '.gif')):
            moved_files.append(f"/moved/user_{user_id}/{fname}")

    return jsonify(sorted(moved_files, reverse=True)), 200  # 倒序返回


@app.route('/xiangao', methods=['GET'])
def list_xiangao():
    user_id = request.args.get('user_id')
    if not user_id:
        return jsonify({'error': 'user_id required'}), 400

    xiangao_files = []
    user_xiangao_folder = get_user_folder(XIANGAO_FOLDER, user_id)
    for fname in os.listdir(user_xiangao_folder):
        if fname.lower().endswith(('.jpg', '.jpeg', '.png', '.gif')):
            xiangao_files.append(f"/xiangao/user_{user_id}/{fname}")

    return jsonify(sorted(xiangao_files, reverse=True)), 200  # 倒序返回


@app.route('/moved/<user_folder>/<path:filename>', methods=['GET'])
def get_moved_file(user_folder, filename):
    return send_from_directory(os.path.join(MOVED_FOLDER, user_folder), filename)


@app.route('/xiangao/<user_folder>/<path:filename>', methods=['GET'])
def get_xiangao_file(user_folder, filename):
    return send_from_directory(os.path.join(XIANGAO_FOLDER, user_folder), filename)

@app.route('/background_person/<user_folder>/<path:filename>', methods=['GET'])
def get_background_person_file(user_folder, filename):
    """
    通过 URL 获取 background_person 文件夹下指定用户的某个文件
    示例 URL: /background_person/user_123/img1.png
    """
    directory = os.path.join(BACK_GROUND_PERSON, user_folder)
    if not os.path.exists(os.path.join(directory, filename)):
        return jsonify({'error': 'File not found'}), 404
    return send_from_directory(directory, filename)

@app.route('/delete', methods=['POST'])
def delete_files():
    user_id = request.form.get('user_id')
    filename = request.form.get('filename')  # 传原始文件名，例如 "123456789.jpg"

    if not user_id or not filename:
        return jsonify({'error': 'user_id and filename required'}), 400

    deleted = []

    # moved 文件名保持原后缀
    user_moved_folder = get_user_folder(MOVED_FOLDER, user_id)
    moved_path = os.path.join(user_moved_folder, filename)
    if os.path.exists(moved_path):
        os.remove(moved_path)
        deleted.append(f"moved/{filename}")

    # xiangao 文件统一后缀 .png
    name_no_ext, _ = os.path.splitext(filename)
    xiangao_filename = f"{name_no_ext}.png"

    user_xiangao_folder = get_user_folder(XIANGAO_FOLDER, user_id)
    xiangao_path = os.path.join(user_xiangao_folder, xiangao_filename)
    if os.path.exists(xiangao_path):
        os.remove(xiangao_path)
        deleted.append(f"xiangao/{xiangao_filename}")

    return jsonify({'deleted': deleted}), 200

@app.route('/deletebackground', methods=['POST'])
def delete_background_person():
    """
    删除指定用户 background_person 文件夹下的所有图片
    """
    user_id = request.form.get('user_id')
    if not user_id:
        return jsonify({'error': 'user_id required'}), 400

    user_folder = get_user_folder(BACK_GROUND_PERSON, user_id)

    # 查找图片文件
    pattern = os.path.join(user_folder, '*')
    files = glob.glob(pattern)
    deleted_files = []

    for f in files:
        try:
            os.remove(f)
            deleted_files.append(os.path.basename(f))
        except Exception as e:
            print(f"Failed to delete {f}: {e}")

    return jsonify({
        'deleted': deleted_files,
        'message': f"{len(deleted_files)} files deleted"
    }), 200


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8001, debug=True)
