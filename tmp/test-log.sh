#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$(realpath "$0")")/../vision-toolkit"   # 切到项目根
source scripts/config/deploy.conf
source scripts/lib/colors.sh
source scripts/lib/logger.sh

logger_init
log_step "测试日志库"
log_info "普通信息"
log_warn "警告消息"
log_error "错误消息（写到 stderr）"
log_ok   "成功"
echo "日志文件：${LOG_FILE}"