#!/usr/bin/env bash
# scripts/lib/preflight.sh
# 部署前置检查。依赖：logger.sh、utils.sh 已被 source，deploy.conf 已 source

# 所有检查汇总入口
run_preflight() {
    log_step "运行部署前置检查"
    local failed=0

    check_commands       || failed=1
    check_docker_daemon  || failed=1
    check_docker_version || failed=1
    check_disk_space     || failed=1
    check_required_files || failed=1
    check_port_available || failed=1

    if (( failed )); then
        log_error "预检失败，部署中止"
        return 1
    fi
    log_ok "所有预检通过"
    return 0
}

# 1. 必需命令
check_commands() {
    log_info "检查必需命令"
    local cmds=(docker curl jq git)
    local failed=0
    for c in "${cmds[@]}"; do
        require_cmd "$c" || failed=1
    done
    if (( failed )); then
        return 1
    fi
    log_ok "命令齐全：${cmds[*]}"
}

# 2. Docker daemon 在运行吗
check_docker_daemon() {
    log_info "检查 Docker daemon"
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker daemon 未运行或无权限"
        log_error "修复：sudo systemctl start docker  或  将当前用户加入 docker 组"
        return 1
    fi
    log_ok "Docker daemon 正常"
}

# 3. Docker 版本 >= REQUIRED_DOCKER_VERSION
check_docker_version() {
    log_info "检查 Docker 版本"
    local current
    current=$(docker version --format '{{.Server.Version}}' 2>/dev/null | cut -d- -f1)
    if ! version_ge "${current}" "${REQUIRED_DOCKER_VERSION}"; then
        log_error "Docker 版本 ${current} < 要求的 ${REQUIRED_DOCKER_VERSION}"
        return 1
    fi
    log_ok "Docker ${current} >= ${REQUIRED_DOCKER_VERSION}"
}

# 4. 磁盘空间 >= MIN_DISK_GB
check_disk_space() {
    log_info "检查磁盘空间"
    local avail_gb
    avail_gb=$(df -BG "${PROJECT_ROOT}" | awk 'NR==2 {gsub("G",""); print $4}')
    if (( avail_gb < MIN_DISK_GB )); then
        log_error "可用磁盘 ${avail_gb}GB < 要求的 ${MIN_DISK_GB}GB"
        log_error "修复：docker system prune -af  清理旧镜像"
        return 1
    fi
    log_ok "可用磁盘 ${avail_gb}GB（需要 ${MIN_DISK_GB}GB）"
}

# 5. 必需文件存在
check_required_files() {
    log_info "检查项目文件"
    local files=("${COMPOSE_FILE:-docker-compose.yml}" "Dockerfile")
    local missing=()
    for f in "${files[@]}"; do
        [[ -f "${PROJECT_ROOT}/${f}" ]] || missing+=("${f}")
    done
    if (( ${#missing[@]} > 0 )); then
        log_error "缺少文件：${missing[*]}"
        return 1
    fi
    log_ok "项目文件齐全"
}

# 6. 端口未被占用（当前服务运行除外）
check_port_available() {
    log_info "检查端口 ${SERVICE_PORT}"
    # 允许被自己的容器占用——update 场景下旧容器还在
    local occupant
    occupant=$(ss -ltnp 2>/dev/null | awk -v p=":${SERVICE_PORT}" '$4 ~ p {print $6}')
    if [[ -n "${occupant}" ]] && [[ "${occupant}" != *"${PROJECT_NAME}"* ]]; then
        log_error "端口 ${SERVICE_PORT} 被占用：${occupant}"
        return 1
    fi
    log_ok "端口 ${SERVICE_PORT} 可用"
}