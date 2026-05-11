#!/usr/bin/env bash
# scripts/rollback.sh — 回滚到上一次部署的镜像
#
# 用法：./scripts/rollback.sh [--force]
#   --force  不提示直接回滚（CI/自动化场景）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "${SCRIPT_DIR}/config/deploy.conf"
source "${SCRIPT_DIR}/lib/colors.sh"
source "${SCRIPT_DIR}/lib/logger.sh"
source "${SCRIPT_DIR}/lib/utils.sh"

FORCE=0
[[ "${1:-}" == "--force" ]] && FORCE=1

logger_init
log_step "准备回滚 ${PROJECT_NAME}"

# 1. 找上次的镜像
BACKUP_FILE="${BACKUP_DIR}/last-image.txt"
if [[ ! -f "${BACKUP_FILE}" ]]; then
    log_error "找不到备份记录：${BACKUP_FILE}"
    log_error "这是第一次部署吗？回滚需要至少一次成功部署作为参考点"
    exit 1
fi
TARGET_IMAGE="$(cat "${BACKUP_FILE}")"
log_info "上次的镜像：${TARGET_IMAGE}"

# 2. 确认镜像还在本机
if ! docker image inspect "${TARGET_IMAGE}" >/dev/null 2>&1; then
    log_error "镜像 ${TARGET_IMAGE} 不在本机。可能已被 docker system prune 清理"
    log_error "修复：docker pull ${TARGET_IMAGE}  后再运行本脚本"
    exit 1
fi

# 3. 确认
if (( ! FORCE )); then
    confirm "即将把 ${PROJECT_NAME} 回滚到 ${TARGET_IMAGE}，继续?" || {
        log_warn "用户取消"
        exit 0
    }
fi

# 4. 重新启动旧镜像
log_step "切换到旧镜像并重启"
export IMAGE_TAG="${TARGET_IMAGE##*:}"        # 从 "img:tag" 里取 "tag"
export IMAGE_NAME="${TARGET_IMAGE%:*}"

docker compose \
    -p "${COMPOSE_PROJECT_NAME}" \
    -f "${COMPOSE_FILE:-${PROJECT_ROOT}/docker-compose.yml}" \
    up -d --remove-orphans

# 5. 等健康
wait_for_port localhost "${SERVICE_PORT}" 30
wait_for_http "${HEALTHCHECK_URL}" "${HEALTHCHECK_TIMEOUT}"

log_ok "回滚完成：当前镜像 ${TARGET_IMAGE}"