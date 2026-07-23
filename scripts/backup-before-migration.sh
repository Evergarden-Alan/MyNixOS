#!/usr/bin/env bash
# NixOS 迁移前的数据备份脚本

set -euo pipefail

# 配置
BACKUP_BASE="${BACKUP_BASE:-$HOME/nixos-backup}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$BACKUP_BASE/$TIMESTAMP"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否为 root
if [[ $EUID -eq 0 ]]; then
   log_error "请不要以 root 身份运行此脚本"
   exit 1
fi

# 创建备份目录
log_info "创建备份目录: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"/{home,system,keys,browser,config}

# 1. 备份家目录关键数据
log_info "备份家目录关键文件..."
rsync -av --progress \
    --exclude='.cache' \
    --exclude='.local/share/Trash' \
    --exclude='*.log' \
    --exclude='node_modules' \
    --exclude='.npm' \
    --exclude='.cargo/registry' \
    --exclude='.cargo/git' \
    "$HOME/Documents" \
    "$HOME/Pictures" \
    "$HOME/Videos" \
    "$HOME/Music" \
    "$HOME/Downloads" \
    "$HOME/Projects" \
    "$BACKUP_DIR/home/" || log_warn "部分家目录文件备份失败"

# 2. 备份 SSH 密钥
if [[ -d "$HOME/.ssh" ]]; then
    log_info "备份 SSH 密钥..."
    cp -r "$HOME/.ssh" "$BACKUP_DIR/keys/"
    chmod 700 "$BACKUP_DIR/keys/.ssh"
    chmod 600 "$BACKUP_DIR/keys/.ssh/"*
else
    log_warn "未找到 SSH 目录"
fi

# 3. 备份 GPG 密钥
if command -v gpg &> /dev/null; then
    log_info "备份 GPG 密钥..."
    gpg --export --armor > "$BACKUP_DIR/keys/gpg-public.asc" || log_warn "GPG 公钥导出失败"
    gpg --export-secret-keys --armor > "$BACKUP_DIR/keys/gpg-private.asc" || log_warn "GPG 私钥导出失败"
    gpg --export-ownertrust > "$BACKUP_DIR/keys/gpg-ownertrust.txt" || log_warn "GPG 信任度导出失败"
else
    log_warn "未安装 GPG"
fi

# 4. 备份配置文件
log_info "备份配置文件..."
for config_dir in .config .local/share; do
    if [[ -d "$HOME/$config_dir" ]]; then
        rsync -av --progress \
            --exclude='Trash' \
            --exclude='recently-used.xbel' \
            "$HOME/$config_dir" \
            "$BACKUP_DIR/config/" || log_warn "$config_dir 备份部分失败"
    fi
done

# 5. 备份浏览器数据提示
log_warn "请手动导出浏览器书签和密码："
log_warn "  Firefox: about:preferences#sync"
log_warn "  Chromium: chrome://settings/passwords"
echo ""
read -p "按 Enter 继续..."

# 6. 备份系统信息
log_info "收集系统信息..."
{
    echo "=== 系统信息 ==="
    uname -a
    echo ""

    echo "=== CPU 信息 ==="
    lscpu | grep "Model name"
    echo ""

    echo "=== GPU 信息 ==="
    lspci | grep VGA
    echo ""

    echo "=== 磁盘分区 ==="
    lsblk -f
    echo ""

    echo "=== 挂载点 ==="
    cat /etc/fstab
    echo ""

    echo "=== 网络接口 ==="
    ip link show
    echo ""

    echo "=== 已安装包 (已在 docs/arch_packages.txt) ==="
    echo "参见项目 docs/ 目录"

} > "$BACKUP_DIR/system/system-info.txt"

sudo fdisk -l > "$BACKUP_DIR/system/fdisk.txt" 2>/dev/null || log_warn "fdisk 信息收集需要 sudo 权限"

# 7. 创建备份清单
log_info "创建备份清单..."
{
    echo "备份时间: $TIMESTAMP"
    echo "备份位置: $BACKUP_DIR"
    echo ""
    echo "=== 备份内容 ==="
    du -sh "$BACKUP_DIR"/*
    echo ""
    echo "=== 文件列表 ==="
    find "$BACKUP_DIR" -type f | sed "s|$BACKUP_DIR/||"
} > "$BACKUP_DIR/MANIFEST.txt"

# 8. 计算总大小
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)

log_info "备份完成！"
echo ""
echo "================================"
echo "备份位置: $BACKUP_DIR"
echo "备份大小: $TOTAL_SIZE"
echo "================================"
echo ""
log_info "请检查备份内容是否完整"
log_info "建议将备份复制到外部存储设备"
echo ""
log_warn "重要提醒："
log_warn "1. 手动导出浏览器书签和密码"
log_warn "2. 记录所有重要的账号密码"
log_warn "3. 确保备份可访问（外部硬盘/云存储）"
log_warn "4. 验证 SSH 和 GPG 密钥是否完整"
echo ""
read -p "按 Enter 退出..."
