#!/usr/bin/env bash
# ==============================================================================
# matugen-update.sh —— 用当前壁纸生成 Material You 配色
# 输出: ~/.config/waybar/colors.css
#       ~/.config/niri/colors.kdl
#       ~/.config/niri/hypr-colors.conf
# 触发: niri 启动时 / waypaper 切壁纸后 / Mod+Alt+M
# ==============================================================================
set -euo pipefail

DOTFILES="${HOME}/.dotfiles"

# 1. 确定壁纸: 命令行参数 > waypaper 当前壁纸 > 仓库默认壁纸
WALLPAPER="${1:-}"
if [[ -z "$WALLPAPER" ]]; then
    if [[ -f "${HOME}/.cache/.current_wallpaper" ]]; then
        WALLPAPER="${HOME}/.cache/.current_wallpaper"
    elif [[ -f "${DOTFILES}/images/wallpaper.png" ]]; then
        WALLPAPER="${DOTFILES}/images/wallpaper.png"
    else
        echo "[matugen-update] 无可用壁纸，跳过" >&2
        exit 0
    fi
fi

if [[ ! -f "$WALLPAPER" ]]; then
    echo "[matugen-update] 壁纸不存在: $WALLPAPER" >&2
    exit 0
fi

# 2. 检查 matugen
if ! command -v matugen >/dev/null 2>&1; then
    echo "[matugen-update] matugen 未安装，跳过" >&2
    exit 0
fi

# 3. 生成配色 (matugen 默认读 ~/.config/matugen/matugen.toml)
if ! matugen image "$WALLPAPER" 2>/dev/null; then
    echo "[matugen-update] matugen 运行失败，保持旧配色" >&2
    exit 0
fi

# 4. 通知 waybar 重载样式
pkill -SIGUSR2 waybar 2>/dev/null || true

echo "[matugen-update] 配色已生成: $WALLPAPER"
