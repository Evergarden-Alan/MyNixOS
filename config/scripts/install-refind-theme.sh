#!/usr/bin/env bash
# ==============================================================================
# install-refind-theme.sh —— 给 rEFInd 装 NixOS 引导主题
#
# 用途: NixOS 装好后 (双系统模式, boot.loader.refind.enable=true), sudo 跑本脚本,
#       把主题放到 ESP 的 EFI/refind/themes/ 并在 refind.conf 追加 include。
#
# Win11 + NixOS 双系统: rEFInd 自动扫描 ESP 上所有 EFI 引导项, 按 os_*.png
#   匹配图标。选 rEFInd-minimal (自带 os_nixos.png + os_win.png) 即完美覆盖。
#
# ⚠️ NixOS 由 boot.loader.refind 管理 refind.conf, nixos-rebuild 会重新生成
#    refind.conf, 抹掉本脚本追加的 include 行。要持久化, 把脚本结尾打印的
#    extraConfig 行加到 hosts/<主机名>/configuration.nix。
#
# 用法:
#   sudo bash config/scripts/install-refind-theme.sh              # 默认 minimal
#   sudo bash config/scripts/install-refind-theme.sh minimal      # 显式指定
#   主题可选: minimal (推荐) | dawn | sublime
# ==============================================================================
set -Eeuo pipefail

C_R='\033[1;31m'; C_G='\033[1;32m'; C_Y='\033[1;33m'; C_B='\033[1;36m'; C_N='\033[0m'
log()  { echo -e "${C_B}[*]${C_N} $*"; }
ok()   { echo -e "${C_G}[✓]${C_N} $*"; }
warn() { echo -e "${C_Y}[!]${C_N} $*"; }
die()  { echo -e "${C_R}[x]${C_N} $*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || die "请用 root 运行: sudo bash install-refind-theme.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ---- 主题表 ----
declare -A T_URL=(
  [minimal]="https://github.com/evanpurkhiser/rEFInd-minimal.git"
  [dawn]="https://github.com/ajlende/rEFInd-dawn.git"
  [sublime]="https://github.com/senpaiSubby/refind-sublime.git"
)
declare -A T_DIR=(
  [minimal]="rEFInd-minimal"
  [dawn]="rEFInd-dawn"
  [sublime]="refind-sublime"
)
# 是否自带 os_nixos.png (NixOS 项图标)
declare -A T_NIXOS=(
  [minimal]=1 [dawn]=0 [sublime]=0
)

THEME="${1:-minimal}"
[ -n "${T_URL[$THEME]:-}" ] || die "未知主题: $THEME (可选: minimal dawn sublime)"
if [ "${T_NIXOS[$THEME]}" != 1 ]; then
    warn "$THEME 不含 os_nixos.png, NixOS 引导项会显示默认图标 (推荐 minimal)"
fi
THEME_URL="${T_URL[$THEME]}"
THEME_DIR="${T_DIR[$THEME]}"

# ---- 1. 找 rEFInd 目录 (ESP/EFI/refind) ----
REFIND_DIR=""
for esp in /boot /efi /boot/efi; do
    [ -d "$esp/EFI/refind" ] && { REFIND_DIR="$esp/EFI/refind"; break; }
done
# 兜底: 扫所有挂载的 vfat 里含 EFI/refind 的
if [ -z "$REFIND_DIR" ]; then
    while read -r _dev mp fstype _rest; do
        [ "$fstype" = "vfat" ] || continue
        if [ -d "$mp/EFI/refind" ]; then REFIND_DIR="$mp/EFI/refind"; break; fi
    done < /proc/mounts
fi
[ -n "$REFIND_DIR" ] || die "未找到 EFI/refind 目录。NixOS 是否已装 rEFInd (boot.loader.refind.enable=true)?"
CONF="$REFIND_DIR/refind.conf"
[ -f "$CONF" ] || die "未找到 refind.conf: $CONF"
ok "rEFInd 目录: $REFIND_DIR"

command -v git >/dev/null 2>&1 || die "缺少 git"

# ---- 2. clone 主题到临时目录再拷进 ESP (ESP 多为 vfat, 不宜直接 git clone) ----
THEMES_DIR="$REFIND_DIR/themes"
DEST="$THEMES_DIR/$THEME_DIR"
mkdir -p "$THEMES_DIR"

if [ -d "$DEST" ]; then
    BACKUP="$DEST.bak.$(date +%s)"
    warn "旧主题已存在, 备份到 $BACKUP"
    mv "$DEST" "$BACKUP"
fi

LOCAL_THEME="$REPO_ROOT/assets/refind/$THEME_DIR"
if [ -d "$LOCAL_THEME" ] && [ -f "$LOCAL_THEME/theme.conf" ]; then
    log "用本地主题副本: $LOCAL_THEME"
    cp -r "$LOCAL_THEME" "$DEST"
else
    TMP="$(mktemp -d)"
    trap 'rm -rf "$TMP"' EXIT
    log "本地无副本, clone: $THEME_URL"
    git clone --depth 1 "$THEME_URL" "$TMP/$THEME_DIR" || die "clone 失败: $THEME_URL"
    rm -rf "$TMP/$THEME_DIR/.git"
    cp -r "$TMP/$THEME_DIR" "$DEST"
fi
ok "主题就位: $DEST"

# ---- 3. 在 refind.conf 追加 include (幂等) ----
INCLUDE_LINE="include themes/$THEME_DIR/theme.conf"
if grep -qF "$INCLUDE_LINE" "$CONF" 2>/dev/null; then
    ok "refind.conf 已含 include, 跳过"
else
    BACKUP_CONF="$CONF.bak.$(date +%s)"
    cp -a "$CONF" "$BACKUP_CONF"
    log "备份 refind.conf -> $BACKUP_CONF"
    printf '\n# === 主题 (install-refind-theme.sh 添加) ===\n%s\n' "$INCLUDE_LINE" >> "$CONF"
    ok "已追加: $INCLUDE_LINE"
fi

# ---- 4. NixOS 持久化提示 ----
echo
echo -e "${C_Y}==== NixOS 持久化 (重要) ====${C_N}"
echo -e "  nixos-rebuild 会重新生成 refind.conf, 抹掉上面的 include 行。"
echo -e "  把下面这行加到 hosts/<主机名>/configuration.nix 的 refind 段:"
echo -e "    ${C_G}boot.loader.refind.extraConfig = \"include themes/$THEME_DIR/theme.conf\";${C_N}"
echo -e "  主题文件 ($DEST) 不受 rebuild 影响, 只需 include 行持久。"
echo

# ---- 5. 检查 UEFI 启动顺序 (双 ESP: rEFInd 须排第一, 否则开机直进 Win11) ----
if command -v efibootmgr >/dev/null 2>&1; then
    echo -e "${C_B}==== UEFI 启动顺序 ====${C_N}"
    REFIND_ENTRY=$(efibootmgr 2>/dev/null | grep -iE 'refind' | head -1 || true)
    [ -z "$REFIND_ENTRY" ] && REFIND_ENTRY=$(efibootmgr 2>/dev/null | grep -iE 'nixos' | head -1 || true)
    OLD_ORDER=$(efibootmgr 2>/dev/null | awk -F'[: ]+' '/^BootOrder/{print $2}' || true)
    FIRST_BOOT=$(echo "$OLD_ORDER" | cut -d, -f1 || true)
    if [ -n "$REFIND_ENTRY" ]; then
        REFIND_NUM=$(echo "$REFIND_ENTRY" | grep -oE 'Boot[0-9A-Fa-f]+' | head -1 | sed 's/Boot//' || true)
        echo "  $REFIND_ENTRY"
        echo "  BootOrder: ${OLD_ORDER:-未知}"
        if [ -n "$REFIND_NUM" ] && [ "$REFIND_NUM" = "$FIRST_BOOT" ]; then
            ok "rEFInd ($REFIND_NUM) 已是第一启动项"
        else
            warn "rEFInd (${REFIND_NUM:-未找到}) 不是第一 (当前第一: ${FIRST_BOOT:-未知}), 开机可能直进 Win11"
            if [ -n "$REFIND_NUM" ] && [ -n "$OLD_ORDER" ]; then
                NEW_ORDER="$REFIND_NUM,$(echo "$OLD_ORDER" | tr ',' '\n' | grep -v "^$REFIND_NUM\$" | paste -sd, || true)"
                read -rp "  把 rEFInd 设为第一启动项? [y/N] " ANS || ANS=N
                if [ "${ANS:-N}" = y ] || [ "${ANS:-N}" = Y ]; then
                    efibootmgr -o "$NEW_ORDER" >/dev/null 2>&1 && ok "已设: $NEW_ORDER" || warn "设置失败, 手动: sudo efibootmgr -o $NEW_ORDER"
                else
                    echo -e "  手动命令: ${C_G}sudo efibootmgr -o $NEW_ORDER${C_N}"
                fi
            fi
        fi
    else
        warn "efibootmgr 中未见 rEFInd/NixOS 条目 (可能 removable 模式), 请进 BIOS Setup 设 rEFInd 第一"
    fi
else
    warn "无 efibootmgr, 跳过启动顺序检查 (进 BIOS Setup 设 rEFInd 第一)"
fi

echo
ok "完成。重启进 rEFInd 即见主题。"
echo -e "  ${C_B}提示:${C_N} rEFInd 自动扫描 Win11 + NixOS, 图标按 os_nixos/os_win 自动匹配。"
