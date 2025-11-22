#!/bin/bash

# Log toàn bộ quá trình setup
# Log toàn bộ quá trình
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Bắt đầu cài đặt..."

# --- THÊM ĐOẠN NÀY ĐỂ SỬA LỖI DNS ---
# Ép buộc sử dụng Google DNS ngay lập tức
echo "nameserver 8.8.8.8" > /etc/resolv.conf
# ------------------------------------

# Sau đó mới chạy các lệnh cần mạng
apt-get update
apt-get install -y python3-pip python3-venv nginx

# 2. Tạo thư mục ứng dụng
mkdir -p /opt/webapp
cd /opt/webapp

# 3. Tạo môi trường ảo (virtual environment)
python3 -m venv venv
source venv/bin/activate

# 4. Cài đặt các thư viện phụ thuộc
# Chúng ta tạo file requirements.txt dựa trên các thư viện code bạn dùng
cat <<EOF > requirements.txt
fastapi==0.104.1
uvicorn==0.24.0
boto3==1.29.6
python-dotenv==1.0.0
python-multipart==0.0.6
EOF

pip install -r requirements.txt

# 5. Tạo file main.py (Nội dung code của bạn)
cat <<EOF > main.py
import boto3
import os
import uuid
import json
import uvicorn
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from botocore.exceptions import ClientError
from decimal import Decimal
from dotenv import load_dotenv

# Load biến môi trường
load_dotenv()

app = FastAPI()

# --- CẤU HÌNH CORS ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- CẤU HÌNH AWS ---
AWS_ACCESS_KEY = os.getenv('AWS_ACCESS_KEY_ID')
AWS_SECRET_KEY = os.getenv('AWS_SECRET_ACCESS_KEY')
REGION = os.getenv('AWS_DEFAULT_REGION', 'us-east-1')
BUCKET_NAME = os.getenv('BUCKET_NAME')
QUEUE_URL = os.getenv('SQS_QUEUE_URL')
DYNAMO_TABLE_NAME = os.getenv('DYNAMO_TABLE', 'RecognitionResults')

session = boto3.Session(
    aws_access_key_id=AWS_ACCESS_KEY,
    aws_secret_access_key=AWS_SECRET_KEY,
    region_name=REGION
)

s3 = session.client('s3')
sqs = session.client('sqs')
dynamodb = session.resource('dynamodb')
table = dynamodb.Table(DYNAMO_TABLE_NAME)

# --- HELPER ---
def decimal_to_native(obj):
    if isinstance(obj, list):
        return [decimal_to_native(i) for i in obj]
    elif isinstance(obj, dict):
        return {k: decimal_to_native(v) for k, v in obj.items()}
    elif isinstance(obj, Decimal):
        return int(obj) if obj % 1 == 0 else float(obj)
    return obj

# --- API 1: UPLOAD ---
@app.post("/upload")
async def upload_image(file: UploadFile = File(...)):
    try:
        request_id = str(uuid.uuid4())
        file_key = f"{request_id}_{file.filename}"
        s3.upload_fileobj(file.file, BUCKET_NAME, file_key)
        message_body = {
            "request_id": request_id,
            "s3_bucket": BUCKET_NAME,
            "s3_key": file_key
        }
        sqs.send_message(QueueUrl=QUEUE_URL, MessageBody=json.dumps(message_body))
        return {"message": "Upload thành công, đang xử lý...", "request_id": request_id}
    except Exception as e:
        print(f"Lỗi Upload: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# --- API 2: RESULT ---
@app.get("/result/{request_id}")
async def get_result(request_id: str):
    try:
        response = table.get_item(Key={'request_id': request_id})
        if 'Item' in response:
            item = decimal_to_native(response['Item'])
            return {"status": "completed", "data": item.get('labels', []), "timestamp": item.get('processed_at')}
        else:
            return {"status": "processing"}
    except ClientError as e:
        print(f"Lỗi DynamoDB: {e}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000)
EOF

# 6. Tạo file .env chứa thông tin AWS (được truyền từ Terraform)
cat <<EOF > .env
AWS_ACCESS_KEY_ID=${aws_access_key_id}
AWS_SECRET_ACCESS_KEY=${aws_secret_access_key}
AWS_DEFAULT_REGION=${aws_default_region}
BUCKET_NAME=${s3_bucket_name}
SQS_QUEUE_URL=${sqs_queue_url}
DYNAMO_TABLE=${dynamo_table_name}
EOF

# 7. Tạo systemd service để chạy ứng dụng nền
cat <<EOF > /etc/systemd/system/webapp.service
[Unit]
Description=Uvicorn instance to serve FastAPI app
After=network.target

[Service]
User=root
Group=www-data
WorkingDirectory=/opt/webapp
Environment="PATH=/opt/webapp/venv/bin"
ExecStart=/opt/webapp/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000

[Install]
WantedBy=multi-user.target
EOF

# 8. Khởi chạy service
systemctl daemon-reload
systemctl start webapp
systemctl enable webapp

echo "Cài đặt hoàn tất!"