#!/usr/bin/env bash
# ==============================================================================
# NixOS 版 Waybar 更新检测脚本
# 检查 flake 是否有可用更新，并显示上次系统构建时间
# ==============================================================================

set -euo pipefail

CACHE_DIR="$HOME/.cache/nixos-update-check"
CACHE_FILE="$CACHE_DIR/updates.json"
LOCK_FILE="/tmp/waybar-nix-updates.lock"
CHECK_INTERVAL=3600

mkdir -p "$CACHE_DIR"

FORCE_UPDATE=0

on_sigusr1() {
    FORCE_UPDATE=1
}
trap 'on_sigusr1' SIGUSR1

format_age() {
    local seconds=$1
    [[ "$seconds" -lt 0 ]] && seconds=0

    if [[ "$seconds" -lt 60 ]]; then
        printf '刚刚'
    elif [[ "$seconds" -lt 3600 ]]; then
        printf '%d 分钟前' $((seconds / 60))
    elif [[ "$seconds" -lt 86400 ]]; then
        printf '%d 小时前' $((seconds / 3600))
    elif [[ "$seconds" -lt 2592000 ]]; then
        printf '%d 天前' $((seconds / 86400))
    elif [[ "$seconds" -lt 31536000 ]]; then
        printf '%d 个月前' $((seconds / 2592000))
    else
        printf '%d 年前' $((seconds / 31536000))
    fi
}

get_last_build_info() {
    local current_time age
    current_time=$(date +%s)

    # 检查当前系统构建时间
    if [[ -d /nix/var/nix/profiles/system ]]; then
        local build_time
        build_time=$(stat -c %Y /nix/var/nix/profiles/system 2>/dev/null || true)
        if [[ -n "$build_time" ]]; then
            age=$((current_time - build_time))
            printf '上次系统构建：%s' "$(format_age "$age")"
            return
        fi
    fi
    printf '上次系统构建：未知'
}

generate_json() {
    local count="${1:-0}"
    local last_update_info
    last_update_info=$(get_last_build_info)

    if [[ "$count" -eq 0 ]]; then
        printf '{"text": "", "alt": "updated", "tooltip": "系统已是最新\\n----------------\\n%s"}\n' "$last_update_info"
    else
        printf '{"text": "%s", "alt": "has-updates", "tooltip": "有 %s 个 flake 输入可更新\\n----------------\\n%s"}\n' "$count" "$count" "$last_update_info"
    fi
}

perform_update_check() {
    local count=0

    # 检查 flake.lock 是否有更新（需要网络）
    if command -v nix &>/dev/null && [[ -f "$HOME/.dotfiles/flake.lock" ]]; then
        local flake_dir="$HOME/.dotfiles"
        local check_output
        # 使用 flake update --dry-run 检查（如果网络不通则跳过）
        check_output=$(cd "$flake_dir" && nix flake update --dry-run 2>&1) || true
        if echo "$check_output" | grep -q "would update"; then
            count=$(echo "$check_output" | grep -c "would update" || true)
        fi
    fi

    generate_json "$count" > "$CACHE_FILE"
}

emit_cached_json() {
    if [[ -f "$CACHE_FILE" ]]; then
        # 重新生成 tooltip（时间会更新）
        local count=0
        # 从缓存提取 count
        if grep -q '"has-updates"' "$CACHE_FILE" 2>/dev/null; then
            count=$(grep -oP '(?<="text": ")[0-9]+' "$CACHE_FILE" 2>/dev/null || echo 0)
        fi
        generate_json "$count"
    else
        generate_json 0
    fi
}

run_check() {
    if [[ $FORCE_UPDATE -eq 0 ]] && [[ -f "$CACHE_FILE" ]]; then
        local current_time file_time age
        current_time=$(date +%s)
        file_time=$(stat -c %Y "$CACHE_FILE")
        age=$((current_time - file_time))

        if [[ $age -lt $((CHECK_INTERVAL - 10)) ]]; then
            emit_cached_json
            return
        fi
    fi

    FORCE_UPDATE=0
    trap '' SIGUSR1

    (
        if flock -x -n 9; then
            perform_update_check || true
        else
            flock -x -w 120 9 || true
        fi
    ) 9>"$LOCK_FILE" || true

    trap 'on_sigusr1' SIGUSR1

    if [[ -f "$CACHE_FILE" ]]; then
        emit_cached_json
    else
        generate_json 0
    fi
}

# 主循环
while true; do
    run_check
    sleep "$CHECK_INTERVAL" &
    wait $! || true
done
