from flask import Flask, request, jsonify
import os

app = Flask(__name__)
UPLOAD_FOLDER = 'uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

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

    return jsonify({'saved': saved}), 200

if __name__ == '__main__':
    # 在开发机器上监听所有接口，以便真机能访问
    app.run(host='0.0.0.0', port=8001, debug=True)