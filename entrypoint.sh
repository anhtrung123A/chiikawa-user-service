#!/bin/bash
set -e

# Xóa pid cũ (phòng server crash không restart lại được)
rm -f /app/tmp/pids/server.pid

# Chạy migrate (nếu có DB)
echo "===> Running migrations..."
bundle exec rails db:migrate 2>/dev/null || echo "No migrations to run"

# Tiếp tục thực thi CMD trong Dockerfile (rails server)
exec "$@"