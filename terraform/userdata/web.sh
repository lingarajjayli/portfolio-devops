#!/bin/bash
#
# Web Server User Data Script
# This script is executed on EC2 instance launch
#

set -euo pipfail

# Update and upgrade packages
apt-get update
apt-get install -y \
    nginx \
    curl \
    unzip \
    wget

# Create app directory
mkdir -p /var/www/app
chown www-data:www-data /var/www/app

# Create sample content
cat > /var/www/app/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Web Server</title>
</head>
<body>
    <h1>Hello from Ubuntu Web Server!</h1>
    <p>This is a demo application running on a DevOps EC2 instance.</p>
    <p>Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
</body>
</html>
EOF

# Configure nginx
cat > /etc/nginx/sites-available/app << 'EOF'
server {
    listen 80;
    server_name localhost;
    root /var/www/app;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
EOF

ln -s /etc/nginx/sites-available/app /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Setup log rotation
cat > /etc/logrotate.d/app << 'EOF'
/var/log/app/*.log {
    daily
    rotate 7
    compress
    delaycompress
    notifempty
    create 640 www-data www-data
}
EOF

# Setup health check endpoint
mkdir -p /var/www/app/health
cat > /var/www/app/health/health_check.sh << 'EOF'
#!/bin/bash
# Health check endpoint
echo "healthy"
exit 0
EOF

chmod +x /var/www/app/health/health_check.sh
ln -s /var/www/app/health/health_check.sh /var/www/app/health/health_check

# Setup systemd service
cat > /etc/systemd/system/app-healthcheck.service << 'EOF'
[Unit]
Description=Health Check Service
After=network.target

[Service]
Type=simple
ExecStart=/var/www/app/health/health_check
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start services
systemctl enable nginx
systemctl start nginx
systemctl status nginx

echo "Web Server setup complete!"
