#!/usr/bin/env bash
# ==============================================================================
# start-proxy.sh —— 解压 mihomo 内核 + 下载订阅 + 启动代理
#
# 前提: assets/mihomo/ 下有:
#   mihomo-linux-amd64-v*.gz   内核压缩包
#   country.mmdb / geoip.metadb / geosite.dat  路由数据库
#
# 用法 (bootstrap.sh 通过 bash 子进程调用):
#   bash config/scripts/start-proxy.sh
#
# 启动后代理地址: http://127.0.0.1:7890  (mixed-port)
# ==============================================================================
set -Eeuo pipefail

# ===== 配置 =====
MIXED_PORT="${MIXED_PORT:-7890}"
MIHOMO_DIR="${MIHOMO_DIR:-/tmp/mihomo-run}"
MIHOMO_BIN="$MIHOMO_DIR/mihomo"
CONFIG_FILE="$MIHOMO_DIR/config.yaml"
PID_FILE="$MIHOMO_DIR/mihomo.pid"

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"

# 订阅地址 —— 从本地 env 文件读 (token 不进 git)，参考 sub.env.example
# env 路径可用 MIHOMO_SUB_ENV 覆盖，默认 $DOTFILES/assets/mihomo/sub.env
SUB_ENV="${MIHOMO_SUB_ENV:-$DOTFILES/assets/mihomo/sub.env}"
[ -z "${QUIET:-}" ] && QUIET="false" || true

log()   { [ "$QUIET" = "true" ] || echo -e "\033[1;36m[*]\033[0m $*"; }
ok()    { [ "$QUIET" = "true" ] || echo -e "\033[1;32m[✓]\033[0m $*"; }
warn()  { [ "$QUIET" = "true" ] || echo -e "\033[1;33m[!]\033[0m $*" >&2; }

# ===== 下载工具 =====
download() {
    local url="$1" out="$2"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL --connect-timeout 10 --max-time 30 -o "$out" "$url"
    elif command -v wget >/dev/null 2>&1; then
        wget -q --timeout=10 --tries=1 -O "$out" "$url"
    else
        return 1
    fi
}

# ===== 1. 找 .gz 并解压 =====
prepare_mihomo_bin() {
    # 查找压缩包
    local gz=""
    if [ -n "${MIHOMO_GZ:-}" ] && [ -f "$MIHOMO_GZ" ]; then
        gz="$MIHOMO_GZ"
    else
        for candidate in \
            "$DOTFILES/assets/mihomo/mihomo-linux-amd64-v"*".gz" \
            "$DOTFILES/assets/mihomo/mihomo-linux-amd64-"*".gz"; do
            [ -f "$candidate" ] && { gz="$candidate"; break; }
        done
    fi

    [ -n "$gz" ] || { warn "未找到 mihomo .gz 压缩包"; return 1; }
    log "解压 mihomo: $(basename "$gz")"

    mkdir -p "$MIHOMO_DIR"

    # 如果已解压且版本相同则跳过
    if [ -x "$MIHOMO_BIN" ]; then
        # 验证已有的二进制是否完整 (防止上次残留损坏)
        if "$MIHOMO_BIN" --version >/dev/null 2>&1; then
            ok "mihomo 已解压, 跳过"
            return 0
        else
            warn "mihomo 缓存损坏, 重新解压"
            rm -f "$MIHOMO_BIN"
        fi
    fi

    gunzip -c "$gz" > "$MIHOMO_BIN.tmp" || { rm -f "$MIHOMO_BIN.tmp"; warn "解压失败 (.gz 损坏或磁盘满)"; return 1; }
    mv "$MIHOMO_BIN.tmp" "$MIHOMO_BIN"
    chmod +x "$MIHOMO_BIN"
    ok "mihomo 解压完成 ($(du -h "$MIHOMO_BIN" | cut -f1))"
}

# ===== 2. 复制 geo 数据库 =====
prepare_geo_data() {
    log "准备 geo 路由数据库 ..."
    local src="$DOTFILES/assets/mihomo"
    for f in geoip.metadb geosite.dat country.mmdb; do
        if [ -f "$src/$f" ]; then
            cp -f "$src/$f" "$MIHOMO_DIR/$f"
        else
            warn "缺少 geo 数据库: $f (路由规则可能失效)"
        fi
    done
    ok "geo 数据库已就绪"
}

# ===== 3. 下载订阅配置 (主优先，备兜底，不合并) =====
download_subs() {
    local sub1="/tmp/mihomo-sub-1.yaml" sub2="/tmp/mihomo-sub-2.yaml"
    local chosen=""

    # 从本地 env 文件读订阅地址 (token 不进 git)，参考 sub.env.example
    if [ -f "$SUB_ENV" ]; then
        set -a; . "$SUB_ENV"; set +a
    else
        warn "未找到订阅配置: $SUB_ENV"
        warn "请复制 assets/mihomo/sub.env.example 为 sub.env 并填入订阅地址"
        return 1
    fi
    [ -n "${SUB_URL_1:-}${SUB_URL_2:-}" ] || { warn "sub.env 未定义 SUB_URL_1 / SUB_URL_2"; return 1; }

    if [ -n "${SUB_URL_1:-}" ]; then
        log "下载订阅 主 ..."
        if download "$SUB_URL_1" "$sub1"; then
            if grep -q 'proxies:' "$sub1" 2>/dev/null; then
                chosen="$sub1"
                ok "主订阅可用 ($(wc -l < "$sub1") 行)"
            else
                warn "主订阅格式无效 (无 proxies: 段)"
            fi
        else
            warn "主订阅下载失败"
        fi
    fi

    if [ -z "$chosen" ] && [ -n "${SUB_URL_2:-}" ]; then
        log "尝试订阅 备 ..."
        if download "$SUB_URL_2" "$sub2"; then
            if grep -q 'proxies:' "$sub2" 2>/dev/null; then
                chosen="$sub2"
                ok "备订阅可用 ($(wc -l < "$sub2") 行)"
            else
                warn "备订阅格式无效 (无 proxies: 段)"
            fi
        else
            warn "备订阅下载失败"
        fi
    fi

    [ -n "$chosen" ] || { warn "两份订阅均不可用"; return 1; }

    # 直接用选中的订阅,在其内容之后追加端口/geo 设置 (后写覆盖先写)
    log "生成配置 (使用订阅: $(basename "$chosen")) ..."
    {
        echo "# === mihomo 配置 (start-proxy.sh 自动生成) === "
        cat "$chosen"
        echo ""
        echo "# --- 本地覆盖 ---"
        echo "mixed-port: $MIXED_PORT"
        echo "allow-lan: false"
        echo "log-level: warning"
        echo "ipv6: false"
        echo "geodata-mode: true"
        echo "external-controller: 127.0.0.1:9090"
    } > "$CONFIG_FILE"

    ok "配置已生成: $CONFIG_FILE ($(wc -l < "$CONFIG_FILE") 行)"
}

# ===== 4. 启动 mihomo =====
start_mihomo() {
    log "启动 mihomo (mixed-port=$MIXED_PORT) ..."

    # 清理旧进程 (验证 PID 对应的可执行文件确实是 mihomo)
    if [ -f "$PID_FILE" ]; then
        local old; old=$(cat "$PID_FILE" 2>/dev/null || true)
        if [ -n "$old" ] && kill -0 "$old" 2>/dev/null; then
            local old_exe; old_exe=$(readlink -f "/proc/$old/exe" 2>/dev/null || true)
            if [ "$old_exe" = "$MIHOMO_BIN" ]; then
                kill "$old" 2>/dev/null || true
                sleep 0.2
            fi
        fi
        rm -f "$PID_FILE"
    fi

    cd "$MIHOMO_DIR"
    nohup "$MIHOMO_BIN" -d "$MIHOMO_DIR" -f "$CONFIG_FILE" > "$MIHOMO_DIR/mihomo.log" 2>&1 &
    local pid=$!
    echo "$pid" > "$PID_FILE"

    # 等待端口就绪
    local waited=0
    while [ $waited -lt 15 ]; do
        # 检查进程存活
        kill -0 "$pid" 2>/dev/null || {
            warn "mihomo 进程异常退出 (日志):"
            tail -20 "$MIHOMO_DIR/mihomo.log" >&2
            return 1
        }
        # 检查端口 (ss → netstat → /proc/net/tcp 三重降级)
        # 注意: 不用 grep -q (会过早关闭管道触发 SIGPIPE, 配合 pipefail 导致误判)
        if ss -tlnp 2>/dev/null | grep ":$MIXED_PORT " >/dev/null || \
           netstat -tlnp 2>/dev/null | grep ":$MIXED_PORT " >/dev/null || \
           cat /proc/net/tcp 2>/dev/null | awk 'NR>1{print $2}' | grep ":$(printf '%04X' "$MIXED_PORT")\$" >/dev/null 2>/dev/null; then
            ok "mihomo 已就绪 (pid=$pid, port=$MIXED_PORT)"
            return 0
        fi
        sleep 1
        waited=$((waited + 1))
    done
    warn "端口 $MIXED_PORT 超时未就绪"
    tail -20 "$MIHOMO_DIR/mihomo.log" >&2
    return 1
}

# ===== 5. 导出代理变量 =====
export_proxy_env() {
    export http_proxy="http://127.0.0.1:$MIXED_PORT"
    export https_proxy="http://127.0.0.1:$MIXED_PORT"
    export HTTP_PROXY="http://127.0.0.1:$MIXED_PORT"
    export HTTPS_PROXY="http://127.0.0.1:$MIXED_PORT"
    export ALL_PROXY="socks5://127.0.0.1:$MIXED_PORT"
}

# ===== 主流程 =====
main() {
    prepare_mihomo_bin || return 1
    prepare_geo_data || return 1
    download_subs || return 1
    start_mihomo || return 1
    export_proxy_env
    ok "代理已就绪: http://127.0.0.1:$MIXED_PORT"
    return 0
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main
fi
