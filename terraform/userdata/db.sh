#!/bin/bash
#
# Database Server User Data Script
# This script is executed on EC2 instance launch
#

set -euo pipfail

# Update and upgrade packages
apt-get update
apt-get install -y \
    mysql-server \
    python3 \
    python3-pip

# Configure MySQL
cat > /etc/mysql/mysql.conf.d/app.conf << 'EOF'
[mysqld]
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
port=3306

# Performance tuning
innodb_buffer_pool_size=256M
innodb_log_file_size=64M
innodb_flush_log_at_trx_commit=2
sync_binlog=0

# Query cache (MySQL 5.6 and earlier)
query_cache_type=1
query_cache_size=32M
query_cache_limit=2M

# Logging
slow_query_log=1
slow_query_log_file=/var/log/mysql/slow.log
long_query_time=2
log_queries_not_using_indexes=1
log_warnings=2

# Security
local_infile=0
skip-symbolic-links
EOF

# Create database user
mysql -u root -e "CREATE USER 'appuser'@'localhost' IDENTIFIED BY 'SecurePassword123!';"
mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'appuser'@'localhost' WITH GRANT OPTION;"
mysql -u root -e "FLUSH PRIVILEGES;"

# Create sample database and tables
mysql -u root -e "
CREATE DATABASE IF NOT EXISTS appdb;
USE appdb;

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (product_id) REFERENCES products(id)
) ENGINE=InnoDB;
"

# Setup monitoring
mkdir -p /var/log/app-database

# Create monitoring script
cat > /usr/local/bin/db-health-check.sh << 'EOF'
#!/bin/bash
# Database health check script

# Check MySQL status
if ! systemctl is-active --quiet mysql; then
    echo "FAIL: MySQL is not running"
    exit 1
fi

# Check if MySQL is listening on port 3306
if ! netstat -tlnp | grep -q ":3306"; then
    echo "FAIL: MySQL is not listening on port 3306"
    exit 1
fi

# Check database connectivity
if ! mysql -u appuser -p'SecurePassword123!' -e "SELECT 1" appdb 2>/dev/null; then
    echo "FAIL: Cannot connect to database"
    exit 1
fi

# Check for long-running queries
LONG_QUERIES=$(mysql -u appuser -p'SecurePassword123!' appdb -e "SHOW PROCESSLIST WHERE TIME > 10;" 2>/dev/null | wc -l)
if [ "$LONG_QUERIES" -gt 5 ]; then
    echo "WARN: High number of long-running queries: $LONG_QUERIES"
fi

echo "OK: Database is healthy"
exit 0
EOF

chmod +x /usr/local/bin/db-health-check.sh

# Setup systemd timer
cat > /etc/systemd timer/db-healthcheck.timer << 'EOF'
[Unit]
Description=Database Health Check Timer
Requires=db-healthcheck.service

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min
Unit=db-healthcheck.service

[Install]
WantedBy=timers.target
EOF

cat > /etc/systemd/system/db-healthcheck.service << 'EOF'
[Unit]
Description=Database Health Check Service
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/db-health-check.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Enable services
systemctl enable mysql
systemctl start mysql
systemctl status mysql
systemctl enable db-healthcheck.timer
systemctl start db-healthcheck.timer

echo "Database Server setup complete!"
