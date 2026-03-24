#!/bin/bash
#
# API Server User Data Script
# This script is executed on EC2 instance launch
#

set -euo pipfail

# Update and upgrade packages
apt-get update
apt-get install -y \
    python3 \
    python3-pip \
    nodejs \
    npm

# Create app directory
mkdir -p /var/www/api
chown -R $USER:$USER /var/www/api

# Sample API with Python Flask
cat > /var/www/api/app.py << 'EOF'
from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/health')
def health():
    return jsonify({'status': 'healthy', 'instance_id': 'unknown'})

@app.route('/')
def index():
    return jsonify({
        'message': 'API Server',
        'version': '1.0.0'
    })

@app.route('/api/users')
def users():
    return jsonify({
        'users': [
            {'id': 1, 'name': 'Alice'},
            {'id': 2, 'name': 'Bob'},
            {'id': 3, 'name': 'Charlie'}
        ]
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
EOF

chmod +x /var/www/api/app.py

# Create requirements.txt
cat > /var/www/api/requirements.txt << 'EOF'
Flask==3.0.0
gunicorn==21.2.0
EOF

# Create systemd service
cat > /etc/systemd/system/api.service << 'EOF'
[Unit]
Description=API Application
After=network.target

[Service]
Type=simple
User=$USER
Group=$USER
WorkingDirectory=/var/www/api
ExecStart=/usr/bin/python3 /var/www/api/app.py
Restart=on-failure
RestartSec=5
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

systemctl enable api.service
systemctl start api.service
systemctl status api.service

echo "API Server setup complete!"
