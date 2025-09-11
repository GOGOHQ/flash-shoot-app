from flask import Flask, request, jsonify, send_from_directory
from flask_socketio import SocketIO, emit
import os

app = Flask(__name__)
app.config['SECRET_KEY'] = 'secret!'

# 配置 SocketIO，允许跨域
socketio = SocketIO(app, cors_allowed_origins="*")

UPLOAD_FOLDER = 'uploads'
MOVED_FOLDER = 'moved'

os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(MOVED_FOLDER, exist_ok=True)


@app.route('/upload', methods=['POST'])
def upload():
    files = request.files.getlist('files')
    saved = []
    for f in files:
        if f.filename == '':
            continue
        path = os.path.join(UPLOAD_FOLDER, f.filename)
        f.save(path)
        saved.append(path)

        # 假设逻辑是：上传后文件会被移动到 moved 目录（这里可以根据你需求调整）
        moved_path = os.path.join(MOVED_FOLDER, f.filename)
        os.rename(path, moved_path)

        # 触发 WebSocket 推送
        socketio.emit('new_image', f"/moved/{f.filename}")

    return jsonify({'saved': saved}), 200


# 返回 moved 文件夹里的所有图片路径
@app.route('/moved', methods=['GET'])
def list_moved():
    files = []
    for fname in os.listdir(MOVED_FOLDER):
        if fname.lower().endswith(('.jpg', '.jpeg', '.png', '.gif')):
            files.append(f"/moved/{fname}")
    return jsonify(files), 200


# 让前端可以直接访问 /moved/<filename>
@app.route('/moved/<path:filename>', methods=['GET'])
def get_moved_file(filename):
    return send_from_directory(MOVED_FOLDER, filename)


# WebSocket 连接事件
@socketio.on('connect')
def handle_connect():
    print("Client connected")
    emit('message', {'msg': 'Connected to server'})


@socketio.on('disconnect')
def handle_disconnect():
    print("Client disconnected")


if __name__ == '__main__':
    # 用 socketio.run 替代 app.run
    socketio.run(app, host='0.0.0.0', port=8001, debug=True)
