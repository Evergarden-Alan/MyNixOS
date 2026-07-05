#!/usr/bin/env bash
# ==============================================================================
# NixOS Command Center - 常用维护指令集
# 从 waybar 的 custom/actions 模块触发
# ==============================================================================

set -euo pipefail

report_error() {
    local error_msg="$1"
    echo "错误：$error_msg" >&2
    command -v notify-send >/dev/null 2>&1 && \
        notify-send -u critical -a "Command Center" "指令异常" "$error_msg" || true
}

# 基础依赖检测
if ! command -v kitty >/dev/null 2>&1; then
    report_error "未找到 kitty 终端，请先安装。"
    exit 1
fi

OPTIONS_ARR=()

# === NixOS 系统管理命令 ===

# 系统更新
OPTIONS_ARR+=("更新系统 (nixos-rebuild switch)")

# Flake 更新
if [[ -f "$HOME/.dotfiles/flake.nix" ]]; then
    OPTIONS_ARR+=("更新 Flake 依赖 (nix flake update)")
fi

# 垃圾回收
OPTIONS_ARR+=("清理系统 (nix-collect-garbage -d)")

# 显示当前系统代际
OPTIONS_ARR+=("显示系统代际 (nixos-rebuild list-generations)")

# === 网络与蓝牙 ===

# 网络工具
if systemctl is-active --quiet NetworkManager; then
    OPTIONS_ARR+=("联网工具 (nmtui)")
fi

# 蓝牙工具
if [[ -d /sys/class/bluetooth ]] && [[ -n "$(ls -A /sys/class/bluetooth 2>/dev/null || true)" ]]; then
    if command -v blueman-manager >/dev/null 2>&1; then
        OPTIONS_ARR+=("蓝牙工具 (blueman-manager)")
    else
        OPTIONS_ARR+=("蓝牙工具 (bluetoothctl)")
    fi
fi

# Fuzzel 菜单
SELECTED=$(printf "%s\n" "${OPTIONS_ARR[@]}" | fuzzel --dmenu \
    -p "NixOS 指令 > " \
    --placeholder "命令可手动运行" \
    --placeholder-color 80808099 || true)

if [[ -z "$SELECTED" ]]; then
    exit 0
fi

case "$SELECTED" in
    "更新系统 (nixos-rebuild switch)")
        kitty --single-instance --class command-center --title "系统更新" \
            bash -c "sudo nixos-rebuild switch --flake ~/.dotfiles#$(hostname); echo; echo '按任意键退出...'; read -n 1 -s -r"
        ;;
    "更新 Flake 依赖 (nix flake update)")
        kitty --single-instance --class command-center --title "Flake 更新" \
            bash -c "cd ~/.dotfiles && nix flake update; echo; echo '按任意键退出...'; read -n 1 -s -r"
        ;;
    "清理系统 (nix-collect-garbage -d)")
        kitty --single-instance --class command-center --title "系统清理" \
            bash -c "sudo nix-collect-garbage -d; echo; echo '按任意键退出...'; read -n 1 -s -r"
        ;;
    "显示系统代际 (nixos-rebuild list-generations)")
        kitty --single-instance --class command-center --title "系统代际" \
            bash -c "sudo nixos-rebuild list-generations; echo; echo '按任意键退出...'; read -n 1 -s -r"
        ;;
    "联网工具 (nmtui)"|"联网工具 (impala)")
        kitty --single-instance --class command-center --title "联网工具" bash -c "nmtui"
        ;;
    "蓝牙工具 (blueman-manager)"|"蓝牙工具 (bluetoothctl)"|"蓝牙工具 (blueberry)")
        if command -v blueman-manager >/dev/null 2>&1; then
            blueman-manager &
        elif command -v bluetoothctl >/dev/null 2>&1; then
            kitty --single-instance --class command-center --title "蓝牙工具" bash -c "bluetoothctl"
        fi
        ;;
    *)
        report_error "未知的选项: $SELECTED"
        exit 1
        ;;
esac
