from flask import Flask, request, jsonify, send_from_directory
import os
import time

app = Flask(__name__)

UPLOAD_FOLDER = 'uploads'
MOVED_FOLDER = 'moved'
XIANGAO_FOLDER = 'xiangao'

os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(MOVED_FOLDER, exist_ok=True)
os.makedirs(XIANGAO_FOLDER, exist_ok=True)


def get_user_folder(base, user_id):
    folder = os.path.join(base, f"user_{user_id}")
    os.makedirs(folder, exist_ok=True)
    return folder


def timestamp_filename(ext):
    """根据当前时间戳生成文件名"""
    ts = int(time.time() * 1000)  # 毫秒
    return f"{ts}{ext}"


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



if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8001, debug=True)
