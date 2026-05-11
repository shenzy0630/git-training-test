#!/usr/bin/env bash
# scripts/lib/utils.sh
# 通用工具函数。依赖：logger.sh 已被 source

# ---------- 版本比较 ----------
version_ge() {
    [[ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" == "$2" ]]
}

# ---------- 命令存在性 ----------
require_cmd() {
    command -v "$1" >/dev/null 2>&1 || {
        log_error "未找到命令：$1。请先安装"
        return 1
    }
}

# ---------- 带超时的端口等待 ----------
wait_for_port() {
    local host="$1" port="$2" timeout="${3:-30}"
    local elapsed=0
    while ! (exec 3<>"/dev/tcp/${host}/${port}") 2>/dev/null; do
        exec 3<&- 3>&- 2>/dev/null || true
        if (( elapsed >= timeout )); then
            log_error "等待 ${host}:${port} 超时（${timeout}s）"
            return 1
        fi
        sleep 1
        (( elapsed++ ))
    done
    exec 3<&- 3>&- 2>/dev/null || true
    return 0
}

# ---------- 带超时的 HTTP 健康检查 ----------
wait_for_http() {
    local url="$1" timeout="${2:-30}"
    local elapsed=0 code
    while true; do
        code=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 3 "${url}" 2>/dev/null || echo "000")
        if [[ "${code}" == "200" ]]; then
            return 0
        fi
        if (( elapsed >= timeout )); then
            log_error "健康检查失败 ${url}（最后 HTTP=${code}，${timeout}s 超时）"
            return 1
        fi
        sleep 2
        (( elapsed += 2 ))
    done
}

# ---------- 清理旧日志 ----------
# 保留最近 N 个日志文件，其余删除。使用 find 处理文件名更安全
cleanup_old_logs() {
    local keep="${1:-10}"
    [[ -d "${LOG_DIR}" ]] || return 0
    (cd "${LOG_DIR}" && ls -t deploy-*.log 2>/dev/null | tail -n +$((keep+1)) | xargs -r rm -f)
}

# ---------- 确认提示 ----------
confirm() {
    local prompt="${1:-确认继续?} [y/N] "
    read -r -p "${prompt}" reply
    [[ "${reply}" =~ ^[Yy]$ ]]
}
