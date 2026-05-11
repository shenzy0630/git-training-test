#!/usr/bin/env bash
# scripts/lib/logger.sh
# 分级日志：INFO / WARN / ERROR / OK / STEP
# 同时输出到终端和日志文件
# 依赖：colors.sh 已被 source、LOG_DIR 已定义

# 防止重复加载
[[ -n "${_LOGGER_LOADED:-}" ]] && return
readonly _LOGGER_LOADED=1

# 初始化日志文件（主脚本调用一次）
logger_init() {
    mkdir -p "${LOG_DIR}"
    LOG_FILE="${LOG_DIR}/deploy-$(date +%Y%m%d-%H%M%S).log"
    # 建 latest.log 软链，方便 tail -f 看最近一次
    ln -sf "$(basename "${LOG_FILE}")" "${LOG_DIR}/latest.log"
    echo "=== 部署开始 $(date -Iseconds) ===" > "${LOG_FILE}"
}

# 内部：写带时间戳的纯文本到日志文件（无颜色）
_log_to_file() {
    if [[ -n "${LOG_FILE:-}" ]]; then
        echo "[$(date +%H:%M:%S)] $*" >> "${LOG_FILE}"
    fi
}

log_info()  { echo -e "${C_BLUE}[INFO]${C_RESET}  $*";        _log_to_file "[INFO]  $*"; }
log_warn()  { echo -e "${C_YELLOW}[WARN]${C_RESET}  $*" >&2;  _log_to_file "[WARN]  $*"; }
log_error() { echo -e "${C_RED}[ERROR]${C_RESET} $*" >&2;     _log_to_file "[ERROR] $*"; }
log_ok()    { echo -e "${C_GREEN}[ OK ]${C_RESET}  $*";       _log_to_file "[ OK ]  $*"; }

# 步骤分隔，长日志里视觉锚点
log_step() {
    echo ""
    echo -e "${C_BOLD}${C_CYAN}==> $*${C_RESET}"
    _log_to_file "==> $*"
}

# 调试日志，默认不输出到终端（可以设 LOG_DEBUG=1 打开）
log_debug() {
    if [[ "${LOG_DEBUG:-0}" == "1" ]]; then
        echo -e "${C_CYAN}[DEBUG]${C_RESET} $*" >&2
    fi
    _log_to_file "[DEBUG] $*"
}
