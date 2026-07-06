#!/usr/bin/env bash
# ==============================================================================
# MyNixOS 全自动安装脚本
#
# 用途: 在 NixOS Live ISO 中运行,一键把本仓库的配置装到目标磁盘。
#
# 流程:
#   1. 交互询问(磁盘/主机名/用户名/仓库地址/文件系统)
#   2. 分区 + 格式化 + 挂载(UEFI btrfs 子卷 或 ext4)
#   3. nixos-generate-config 生成硬件配置
#   4. 克隆本仓库到目标系统的 ~/.dotfiles
#   5. 把硬件配置塞进 hosts/<主机名>/ 并生成 configuration.nix
#   6. nixos-install --flake .#<主机名>
#
# 使用:
#   sudo bash bootstrap.sh
#   (或先 chmod +x bootstrap.sh && sudo ./bootstrap.sh)
# ==============================================================================
set -Eeuo pipefail

# 脚本所在目录 = repo 根目录 (用户在 repo 中运行 bootstrap.sh)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------- 颜色与日志 ----------------------------
C_R='\033[1;31m'; C_G='\033[1;32m'; C_Y='\033[1;33m'; C_B='\033[1;36m'; C_N='\033[0m'
log()  { echo -e "${C_B}[*]${C_N} $*"; }
ok()   { echo -e "${C_G}[✓]${C_N} $*"; }
warn() { echo -e "${C_Y}[!]${C_N} $*"; }
die()  { echo -e "${C_R}[x]${C_N} $*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || die "请用 root 运行: sudo bash bootstrap.sh"

# ---------------------------- 交互询问 ----------------------------
echo -e "${C_B}==== NixOS 自动安装 ====${C_N}"

# 列出可用磁盘
log "可用磁盘:"
lsblk -dno NAME,SIZE,MODEL,TYPE | grep -E 'disk|NAME' || true
echo

DEFAULT_DISK=$(lsblk -dno NAME,TYPE | awk '$2=="disk"{print $1; exit}')
read -rp "目标磁盘 [/dev/$DEFAULT_DISK]: " DISK
DISK="${DISK:-/dev/$DEFAULT_DISK}"
[[ "$DISK" == /dev/* ]] || DISK="/dev/$DISK"

read -rp "主机名(也是 hosts/ 下的文件夹名) [nixos]: " HOSTNAME
HOSTNAME="${HOSTNAME:-nixos}"

read -rp "用户名 [alan]: " USERNAME
USERNAME="${USERNAME:-alan}"

read -rp "用户全名 [Alan]: " FULLNAME
FULLNAME="${FULLNAME:-Alan}"

read -rp "时区 [Asia/Shanghai]: " TIMEZONE
TIMEZONE="${TIMEZONE:-Asia/Shanghai}"

read -rp "仓库地址 (git URL) [https://github.com/Evergarden-Alan/MyNixOS.git]: " REPO_URL
REPO_URL="${REPO_URL:-https://github.com/Evergarden-Alan/MyNixOS.git}"
read -rp "锁定到 git ref (tag/commit/branch, 留空用默认分支) []: " REPO_REF

# ---------------------------- 网络配置 (中国大陆) ----------------------------
echo
echo -e "${C_B}==== 网络配置 ====${C_N}"
echo -e "  中国大陆访问 GitHub / cache.nixos.org 极慢或不通。"

# 1. 尝试启动本地 mihomo (仓库 assets/mihomo/ 下有内核压缩包 + geo 数据库)
MIHOMO_GZ=$(ls "$SCRIPT_DIR/assets/mihomo/mihomo-linux-amd64-v"*".gz" 2>/dev/null | head -1 || true)
if [ -n "$MIHOMO_GZ" ] && [ -f "$MIHOMO_GZ" ]; then
    log "检测到 mihomo 内核: $(basename "$MIHOMO_GZ")"

    # 订阅地址写本地 sub.env (token 不进 git)，缺则交互生成
    SUB_ENV="$SCRIPT_DIR/assets/mihomo/sub.env"
    if [ ! -f "$SUB_ENV" ]; then
        echo -e "  ${C_Y}未找到订阅配置 sub.env${C_N} (token 仅存本地, 不写入 git)"
        read -rp "  主订阅 URL []: " SUB_URL_1
        read -rp "  备订阅 URL (留空跳过) []: " SUB_URL_2
        {
            echo "# mihomo 订阅地址 (本地, 勿提交 git) —— 由 bootstrap.sh 生成"
            echo "SUB_URL_1=${SUB_URL_1}"
            [ -n "${SUB_URL_2:-}" ] && echo "SUB_URL_2=${SUB_URL_2}"
        } > "$SUB_ENV"
        chmod 600 "$SUB_ENV"
        ok "已写入 $SUB_ENV (chmod 600)"
    fi

    log "解压内核 + 下载订阅 + 启动代理 ..."
    MIHOMO_GZ="$MIHOMO_GZ" \
    DOTFILES="$SCRIPT_DIR" \
    QUIET=true \
        bash "$SCRIPT_DIR/config/scripts/start-proxy.sh" && {
        # start-proxy.sh 设置 proxy env, 在此 shell 重新声明
        export http_proxy="http://127.0.0.1:7890"
        export https_proxy="http://127.0.0.1:7890"
        export HTTP_PROXY="http://127.0.0.1:7890"
        export HTTPS_PROXY="http://127.0.0.1:7890"
        export ALL_PROXY="socks5://127.0.0.1:7890"
        echo "Defaults env_keep += \"http_proxy https_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY\"" > /etc/sudoers.d/proxy
        chmod 440 /etc/sudoers.d/proxy
        if command -v visudo >/dev/null 2>&1; then
            visudo -cf /etc/sudoers.d/proxy 2>/dev/null || warn "proxy sudoers 语法检查失败"
        fi
        git config --global http.proxy "http://127.0.0.1:7890"
        git config --global https.proxy "http://127.0.0.1:7890"
        PROXY="http://127.0.0.1:7890 (mihomo 自动)"
        ok "mihomo 代理已就绪: $PROXY"
    } || {
        warn "mihomo 启动失败，回退到手动代理"
        MIHOMO_OK=false
    }
else
    MIHOMO_OK=false
fi

# 2. 如果 mihomo 未启动，询问手动代理
if [ "${MIHOMO_OK:-false}" = false ] && [ -z "${PROXY:-}" ]; then
    echo -e "  如果你有 mihomo/v2ray/clash 在运行(如 http://127.0.0.1:7890)，填代理地址。"
    read -rp "  HTTP 代理地址 (留空跳过) []: " PROXY
    if [ -n "$PROXY" ]; then
        export http_proxy="$PROXY"
        export https_proxy="$PROXY"
        export HTTP_PROXY="$PROXY"
        export HTTPS_PROXY="$PROXY"
        export ALL_PROXY="$PROXY"
        echo "Defaults env_keep += \"http_proxy https_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY\"" > /etc/sudoers.d/proxy
        chmod 440 /etc/sudoers.d/proxy
        if command -v visudo >/dev/null 2>&1; then
            visudo -cf /etc/sudoers.d/proxy 2>/dev/null || warn "proxy sudoers 语法检查失败"
        fi
        git config --global http.proxy "$PROXY"
        git config --global https.proxy "$PROXY"
        ok "代理已设置: $PROXY (git + env + sudo)"
    else
        warn "未设置代理，GitHub / nix 下载可能极慢或失败"
    fi
fi

echo
echo "  Nix 二进制缓存镜像 (加速包的下载，可配合代理或独立使用):"
echo "    1) 不使用镜像 (默认 cache.nixos.org)"
echo "    2) TUNA   (清华——mirrors.tuna.tsinghua.edu.cn)"
echo "    3) SJTU   (上交——mirror.sjtu.edu.cn)"
echo "    4) USTC   (中科大——mirrors.ustc.edu.cn)"
PS3="  选 [1-4]: "
select _mirror in "不使用镜像" "TUNA" "SJTU" "USTC"; do
    case "$_mirror" in
        "不使用镜像") NIX_MIRROR=""; break;;
        "TUNA") NIX_MIRROR="https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"; break;;
        "SJTU") NIX_MIRROR="https://mirror.sjtu.edu.cn/nix-channels/store"; break;;
        "USTC") NIX_MIRROR="https://mirrors.ustc.edu.cn/nix-channels/store"; break;;
        *) echo "  无效: 请输入 1-4";;
    esac
done
[ -n "$NIX_MIRROR" ] && ok "Nix 镜像: $NIX_MIRROR" || ok "使用默认 cache.nixos.org"

# 立即使镜像在 ISO 上生效 (nixos-install 从当前系统读 nix.conf)
if [ -n "$NIX_MIRROR" ]; then
    mkdir -p /etc/nix
    echo "substituters = $NIX_MIRROR https://cache.nixos.org" >> /etc/nix/nix.conf
fi

PS3="文件系统 [1=btrfs(推荐) 2=ext4]: "
select _fs in "btrfs" "ext4"; do
    case "$_fs" in
        btrfs) FSTYPE=btrfs; break;;
        ext4)  FSTYPE=ext4;  break;;
        *) echo "  无效: 请输入 1 或 2";;
    esac
done

echo
echo -e "${C_Y}==== 安装模式 ====${C_N}"
echo "  1) 全新安装 —— 全盘擦除, NixOS 独占"
echo "  2) 双系统   —— 保留已有分区, 在空闲空间创建 NixOS ESP + 根分区"
PS3="选 [1-2]: "
select _mode in "全新安装" "双系统"; do
    case "$_mode" in
        "全新安装") DUALBOOT=false; break;;
        "双系统")   DUALBOOT=true;  break;;
        *) echo "  无效: 请输入 1 或 2";;
    esac
done

if $DUALBOOT; then
    log "双系统模式: 保留已有分区, 在空闲空间创建 NixOS 分区"
    # 显示当前分区布局
    parted "$DISK" unit MiB print free 2>/dev/null || true
    echo
    # 检测最大空闲空间 (按大小排序)
    FREE_LINE=$(LC_ALL=C parted "$DISK" unit MiB print free 2>/dev/null | awk '/Free Space/{gsub(/MiB/,"",$1); gsub(/MiB/,"",$2); sz=$2-$1; if(sz>max){max=sz; line=$0}}END{print line}')
    if [ -z "$FREE_LINE" ]; then
        die "未检测到空闲空间。请先在 Windows 磁盘管理中压缩卷腾出空间。"
    fi
    FREE_START=$(echo "$FREE_LINE" | awk '{gsub(/MiB/,"",$1); print int($1)}')
    FREE_END=$(echo "$FREE_LINE"   | awk '{gsub(/MiB/,"",$2); print int($2)}')
    FREE_SIZE=$((FREE_END - FREE_START))
    # 边界校验 —— 防止解析异常导致 mkpart 坐标落到已有分区上
    DISK_SIZE_MIB=$(LC_ALL=C parted "$DISK" unit MiB print 2>/dev/null | awk '/^Disk .*:/{gsub(/MiB/,"",$3); print int($3); exit}')
    [ "$FREE_START" -gt 0 ] 2>/dev/null || die "空闲空间起始解析失败 (FREE_START=$FREE_START)"
    [ "$FREE_END" -gt "$FREE_START" ] 2>/dev/null || die "空闲空间边界异常 (start=$FREE_START end=$FREE_END)"
    [ -n "$DISK_SIZE_MIB" ] && [ "$FREE_END" -le "$DISK_SIZE_MIB" ] 2>/dev/null || die "空闲空间结束 ($FREE_END) 超出盘大小 (${DISK_SIZE_MIB:-未知})"
    log "空闲空间: ${FREE_START}MiB - ${FREE_END}MiB (共 ${FREE_SIZE}MiB, 盘大小 ${DISK_SIZE_MIB:-?}MiB)"

    if [ "$FREE_SIZE" -lt 20480 ]; then
        warn "空闲空间仅 ${FREE_SIZE}MiB (<20GB), NixOS 根分区偏小"
    fi

    read -rp "  NixOS ESP 大小 (MiB, rEFInd 用) [1024]: " ESP_SIZE
    ESP_SIZE="${ESP_SIZE:-1024}"
    [ "$ESP_SIZE" -lt 256 ] && die "ESP 至少 256MiB"
    [ "$ESP_SIZE" -gt "$((FREE_SIZE - 4096))" ] && die "空闲空间不够 (ESP + 至少 4GB 根分区)"

    BOOTLOADER="refind"
    BOOTLOADER_LINE="boot.loader.refind.enable = true;"
    REFIND_EXTRA=$(cat <<'REFINDEOF'
  boot.loader.refind.extraConfig = ''
    include themes/rEFInd-minimal/theme.conf
    dont_scan_dirs EFI/Recovery,EFI/Tools,EFI/Dell,EFI/HP
    dont_scan_files fbx64.efi,mmx64.efi
  '';
REFINDEOF
)
else
    BOOTLOADER="systemd-boot"
    BOOTLOADER_LINE="boot.loader.systemd-boot.enable = true;"
    REFIND_EXTRA=""
fi

echo
echo -e "${C_Y}==== 确认 ====${C_N}"
echo "  目标盘当前布局:"
lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINTS "$DISK" 2>/dev/null || true
echo "  磁盘     : $DISK $($DUALBOOT && echo '(仅动空闲空间)' || echo '(将被完全擦除!)')"
echo "  安装模式 : $($DUALBOOT && echo '双系统 (rEFInd)' || echo '全新安装 (systemd-boot)')"
echo "  主机名   : $HOSTNAME"
echo "  用户名   : $USERNAME"
echo "  时区     : $TIMEZONE"
echo "  文件系统 : $FSTYPE"
echo "  仓库     : $REPO_URL${REPO_REF:+ @ $REPO_REF}"
echo "  代理     : ${PROXY:-无}"
echo "  Nix镜像  : ${NIX_MIRROR:-默认 cache.nixos.org}"
if $DUALBOOT; then
    read -rp "确认开始安装? 输入 YES 继续: " CONFIRM
    [ "$CONFIRM" = "YES" ] || die "已取消"
else
    DISK_BASE="$(basename "$DISK")"
    echo -e "  ${C_R}全新安装将完全擦除 $DISK 上所有数据！${C_N}"
    read -rp "确认? 输入 $DISK_BASE 继续: " CONFIRM
    [ "$CONFIRM" = "$DISK_BASE" ] || die "已取消 (输入与盘名不符)"
fi

# ---------------------------- 1. 分区 ----------------------------
PART_SUFFIX=""
[[ "$(basename "$DISK")" == *nvme* || "$(basename "$DISK")" == *mmcblk* ]] && PART_SUFFIX="p"

# 校验 $DISK 是存在的整盘 (防止误操作分区或不存在设备)
[ -b "$DISK" ] || die "设备不存在: $DISK"
DISK_TYPE="$(lsblk -ndo TYPE "$DISK" 2>/dev/null)"
[ "$DISK_TYPE" = "disk" ] || die "$DISK 不是整盘 (TYPE=${DISK_TYPE:-未知})，请用 /dev/sdX 或 /dev/nvmeXnY"

# 幂等: 清掉上次失败残留的 /mnt 挂载
umount -R /mnt 2>/dev/null || true

# 清掉目标盘上的挂载与 swap —— 否则 partprobe 可能静默失败 / 写 GPT 弄坏已挂载 FS
log "卸载 $DISK 上的挂载与 swap ..."
lsblk -nlo NAME "$DISK" | grep -E "^$(basename "$DISK")${PART_SUFFIX}[0-9]+$" | while read -r p; do
    umount -R "/dev/$p" 2>/dev/null || true
done
lsblk -nlo NAME,TYPE "$DISK" | awk '$2=="part"{print "/dev/"$1}' | while read -r d; do
    swapoff "$d" 2>/dev/null || true
done

# 轮询识别刚建的新分区 (partprobe 异步, sleep 1 不可靠) —— 返回唯一新增分区名
wait_new_part() {
    local before="$1" after new n
    for _ in $(seq 1 10); do
        partprobe "$DISK" 2>/dev/null || true
        after=$(lsblk -nlo NAME "$DISK" | grep -E "^$(basename "$DISK")${PART_SUFFIX}[0-9]+$" | sort -V || true)
        if [ -z "$before" ]; then
            new="$after"
        else
            new=$(comm -13 <(printf '%s\n' "$before") <(printf '%s\n' "$after"))
        fi
        n=$(printf '%s\n' "$new" | grep -cx .)
        [ "$n" -eq 1 ] && { printf '%s\n' "$new"; return 0; }
        sleep 1
    done
    die "新分区未识别 (partprobe 超时) — 已停止, 未格式化任何分区"
}

if $DUALBOOT; then
    log "在空闲空间创建 NixOS 分区 (保留已有分区) ..."
    ESP_SIZE_MB=$ESP_SIZE

    # 建分区前的分区名快照
    BEFORE=$(lsblk -nlo NAME "$DISK" | grep -E "^$(basename "$DISK")${PART_SUFFIX}[0-9]+$" | sort -V || true)

    parted "$DISK" mkpart "NIXOS_ESP"  fat32 ${FREE_START}MiB $((FREE_START + ESP_SIZE_MB))MiB
    ESP_PART=$(wait_new_part "$BEFORE")
    ESP="/dev/$ESP_PART"

    BEFORE=$(lsblk -nlo NAME "$DISK" | grep -E "^$(basename "$DISK")${PART_SUFFIX}[0-9]+$" | sort -V || true)
    parted "$DISK" mkpart "NIXOS_ROOT" $((FREE_START + ESP_SIZE_MB + 1))MiB ${FREE_END}MiB
    ROOT_PART=$(wait_new_part "$BEFORE")
    ROOT="/dev/$ROOT_PART"

    # 标记 ESP 类型
    sgdisk -t "$(echo "$ESP_PART" | grep -oP '\d+$'):ef00" "$DISK" >/dev/null
    partprobe "$DISK" 2>/dev/null || true; sleep 2
    ok "分区完成: ESP=$ESP / ROOT=$ROOT"
else
    log "擦除并分区 $DISK ..."
    sgdisk -Z "$DISK" >/dev/null
    sgdisk -n 1:0:+1G -t 1:ef00 -c 1:"ESP" "$DISK" >/dev/null
    sgdisk -n 2:0:0   -t 2:8300 -c 2:"NIXROOT" "$DISK" >/dev/null
    partprobe "$DISK" 2>/dev/null || true; sleep 2
    ESP="${DISK}${PART_SUFFIX}1"
    ROOT="${DISK}${PART_SUFFIX}2"
fi

# ---------------------------- 2. 格式化 ----------------------------
log "格式化 ESP (FAT32) ..."
mkfs.fat -F32 -n NIXOS_ESP "$ESP" >/dev/null

if [ "$FSTYPE" = "btrfs" ]; then
    log "格式化 btrfs 并创建子卷 ..."
    mkfs.btrfs -f -L NIXROOT "$ROOT" >/dev/null
    mount "$ROOT" /mnt
    btrfs subvolume create /mnt/@        >/dev/null
    btrfs subvolume create /mnt/@home    >/dev/null
    btrfs subvolume create /mnt/@nix     >/dev/null
    umount /mnt
    mount -o compress=zstd,subvol=@     "$ROOT" /mnt
    mkdir -p /mnt/{home,nix,boot}
    mount -o compress=zstd,subvol=@home "$ROOT" /mnt/home
    mount -o compress=zstd,noatime,subvol=@nix "$ROOT" /mnt/nix
    mount "$ESP" /mnt/boot
else
    log "格式化 ext4 ..."
    mkfs.ext4 -F -L NIXROOT "$ROOT" >/dev/null
    mount "$ROOT" /mnt
    mkdir -p /mnt/boot
    mount "$ESP" /mnt/boot
fi
ok "挂载完成:"
findmnt /mnt /mnt/boot /mnt/home /mnt/nix 2>/dev/null || findmnt /mnt /mnt/boot

# ---------------------------- 3. 生成硬件配置 ----------------------------
log "生成硬件配置 ..."
nixos-generate-config --root /mnt --dir /mnt/etc/nixos >/dev/null
HWCONF="/mnt/etc/nixos/hardware-configuration.nix"
[ -f "$HWCONF" ] || die "未生成 hardware-configuration.nix"
ok "硬件配置已生成: $HWCONF"

# ---------------------------- 4. 克隆仓库 ----------------------------
DOTFILES="/mnt/home/$USERNAME/.dotfiles"
log "克隆仓库到 $DOTFILES ..."
mkdir -p "/mnt/home/$USERNAME"
if [ -n "${REPO_REF:-}" ]; then
    git clone --branch "$REPO_REF" "$REPO_URL" "$DOTFILES" 2>/dev/null || die "克隆失败 (ref=$REPO_REF): $REPO_URL"
else
    if ! git clone "$REPO_URL" "$DOTFILES" 2>/dev/null; then
        die "克隆失败,请检查仓库地址: $REPO_URL"
    fi
fi
ok "仓库已克隆"

# ---------------------------- 5. 注册新主机 ----------------------------
HOST_DIR="$DOTFILES/hosts/$HOSTNAME"
log "注册主机 $HOSTNAME ..."
mkdir -p "$HOST_DIR"

# 拷入硬件配置
cp "$HWCONF" "$HOST_DIR/hardware-configuration.nix"

# 生成 configuration.nix(仅机器特定项)
if [ "$FSTYPE" = "btrfs" ]; then
    FSID_HINT="  fsIdentifier = \"provided\"; # btrfs (grub 需要)"
else
    FSID_HINT="  # fsIdentifier = \"provided\";"
fi

# 构造镜像/代理行供 heredoc 插入
MIRROR_LINE=""
if [ -n "$NIX_MIRROR" ]; then
    MIRROR_LINE="  nix.settings.substituters = [ \"$NIX_MIRROR\" \"https://cache.nixos.org\" ];"
fi

cat > "$HOST_DIR/configuration.nix" <<NIXHEREDOC
# 由 bootstrap.sh 自动生成 —— 仅含本机特定项
# 共享配置在 modules/ 下,请勿把通用内容写到这里
{ ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # ---- 引导 (UEFI $BOOTLOADER) ----
  $BOOTLOADER_LINE
$REFIND_EXTRA
  boot.loader.efi.canTouchEfiVariables = true;
  # 若为 BIOS 机器,改用 grub:
  # boot.loader.grub.enable = true;
  # boot.loader.grub.device = "$DISK";
$FSID_HINT

  # ---- 本机身份 ----
  networking.hostName = "$HOSTNAME";
  my.username = "$USERNAME";
  my.fullName = "$FULLNAME";
$MIRROR_LINE

  # 首次安装时的 NixOS 版本,之后请勿修改
  system.stateVersion = "25.11";

  # 按需启用硬件模块(取消注释):
  # imports 里加 ../../../modules/hardware/nvidia.nix 等
}
NIXHEREDOC
ok "configuration.nix 已生成: $HOST_DIR/configuration.nix"

# ---------------------------- 6. 安装 ----------------------------
# 确保 flake.lock 同步所有 input (首次 clone 后可能缺 matugen)
log "同步 flake.lock ..."
cd "$DOTFILES"
if nix flake lock --update-input matugen 2>/dev/null; then
    ok "flake.lock 已更新"
else
    warn "flake lock 更新失败 (网络不通或 matugen 不可达), 尝试继续 ..."
fi

log "开始 nixos-install (会下载依赖,请耐心等待) ..."
if nixos-install --root /mnt --flake ".#$HOSTNAME" --no-root-passwd; then
    ok "安装成功!"
else
    die "nixos-install 失败。可手动排查后重跑,或用 chroot 修复。"
fi

# ---------------------------- 7. 收尾 ----------------------------
log "设置 $USERNAME 的密码 ..."
for i in 1 2 3; do
    passwd --root /mnt "$USERNAME" 2>/dev/null && break
    warn "密码设置失败 (第 $i 次), 重试..."
done || warn "密码设置跳过 (最多 3 次), 请登录后手动 passwd"

chown -R 1000:1000 "/mnt/home/$USERNAME" 2>/dev/null || true

echo
ok "==== 全部完成 ===="
echo -e "  ${C_G}重启进入新系统:${C_N} umount -R /mnt && reboot"
echo -e "  ${C_B}首次登录后:${C_N} GDM 选 Niri 会话"
echo -e "  ${C_B}日常更新:${C_N} cd ~/.dotfiles && sudo nixos-rebuild switch --flake .#$HOSTNAME"
echo -e "  ${C_Y}注意:${C_N} 首次进入需手动配 ~/.secrets (claude-code token) 与 SSH 公钥"
