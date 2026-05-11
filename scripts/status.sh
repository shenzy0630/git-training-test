#!/usr/bin/env bash
# scripts/status.sh — 查看 vision-toolkit 部署状态
#
# 用法：./scripts/status.sh [--json]
#   --json   以 JSON 格式输出（方便接监控）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "${SCRIPT_DIR}/config/deploy.conf"
source "${SCRIPT_DIR}/lib/colors.sh"
source "${SCRIPT_DIR}/lib/logger.sh"

JSON=0
[[ "${1:-}" == "--json" ]] && JSON=1

# 采集容器信息
container_id=$(docker ps \
    --filter "label=com.docker.compose.project=${COMPOSE_PROJECT_NAME}" \
    --format '{{.ID}}' | head -1 || true)

if [[ -z "${container_id}" ]]; then
    if (( JSON )); then
        printf '{"status":"down","container":null}\n'
    else
        echo -e "${C_RED}● ${PROJECT_NAME} 未运行${C_RESET}"
    fi
    exit 3   # systemd 惯例：3=inactive
fi

image=$(docker inspect --format '{{.Config.Image}}' "${container_id}")
started=$(docker inspect --format '{{.State.StartedAt}}' "${container_id}")
health=$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}n/a{{end}}' "${container_id}")
http_code=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 3 "${HEALTHCHECK_URL}" || echo "000")

if (( JSON )); then
    jq -n \
        --arg id "${container_id}" \
        --arg image "${image}" \
        --arg started "${started}" \
        --arg health "${health}" \
        --arg http "${http_code}" \
        '{status:"up", container:$id, image:$image, started_at:$started, docker_health:$health, http_code:$http}'
else
    echo -e "${C_GREEN}● ${PROJECT_NAME} 运行中${C_RESET}"
    printf "  %-16s %s\n" "容器 ID:"    "${container_id}"
    printf "  %-16s %s\n" "镜像:"        "${image}"
    printf "  %-16s %s\n" "启动时间:"    "${started}"
    printf "  %-16s %s\n" "Docker 健康:" "${health}"
    printf "  %-16s %s\n" "HTTP 探测:"   "${http_code} (${HEALTHCHECK_URL})"
    echo ""
    echo "最近 10 行日志："
    docker logs --tail 10 "${container_id}" 2>&1 | sed 's/^/  /'
fi