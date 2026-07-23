#!/usr/bin/env bash
# NixOS 安装后的数据恢复脚本

set -euo pipefail

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

# 检查参数
if [[ $# -lt 1 ]]; then
    log_error "用法: $0 <备份目录路径>"
    echo "示例: $0 /mnt/backup/20260723_143022"
    exit 1
fi

BACKUP_DIR="$1"

# 检查备份目录
if [[ ! -d "$BACKUP_DIR" ]]; then
    log_error "备份目录不存在: $BACKUP_DIR"
    exit 1
fi

log_info "从备份恢复数据: $BACKUP_DIR"
echo ""

# 1. 恢复 SSH 密钥
if [[ -d "$BACKUP_DIR/keys/.ssh" ]]; then
    log_info "恢复 SSH 密钥..."
    mkdir -p "$HOME/.ssh"
    cp -r "$BACKUP_DIR/keys/.ssh/"* "$HOME/.ssh/"
    chmod 700 "$HOME/.ssh"
    chmod 600 "$HOME/.ssh/id_"* 2>/dev/null || true
    chmod 644 "$HOME/.ssh/"*.pub 2>/dev/null || true
    chmod 644 "$HOME/.ssh/known_hosts" 2>/dev/null || true
    chmod 600 "$HOME/.ssh/config" 2>/dev/null || true
    log_info "SSH 密钥已恢复"
else
    log_warn "未找到 SSH 密钥备份"
fi

# 2. 恢复 GPG 密钥
if [[ -f "$BACKUP_DIR/keys/gpg-private.asc" ]]; then
    log_info "恢复 GPG 密钥..."
    gpg --import "$BACKUP_DIR/keys/gpg-public.asc" 2>/dev/null || log_warn "GPG 公钥导入失败"
    gpg --import "$BACKUP_DIR/keys/gpg-private.asc" 2>/dev/null || log_warn "GPG 私钥导入失败"
    if [[ -f "$BACKUP_DIR/keys/gpg-ownertrust.txt" ]]; then
        gpg --import-ownertrust "$BACKUP_DIR/keys/gpg-ownertrust.txt" 2>/dev/null || log_warn "GPG 信任度导入失败"
    fi
    log_info "GPG 密钥已恢复"
else
    log_warn "未找到 GPG 密钥备份"
fi

# 3. 恢复家目录数据（交互式）
echo ""
log_info "准备恢复家目录数据..."
log_warn "这将复制以下目录到当前用户家目录："
ls -1 "$BACKUP_DIR/home/" 2>/dev/null || log_warn "未找到家目录备份"
echo ""
read -p "是否继续？(y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "恢复家目录数据..."
    rsync -av --progress "$BACKUP_DIR/home/"* "$HOME/" || log_warn "部分文件恢复失败"
    log_info "家目录数据已恢复"
else
    log_warn "跳过家目录数据恢复"
fi

# 4. 恢复配置文件（可选）
echo ""
log_info "准备恢复配置文件..."
log_warn "注意：NixOS 配置已由 home-manager 管理"
log_warn "恢复旧配置可能导致冲突"
echo ""
read -p "是否恢复旧的配置文件？(y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [[ -d "$BACKUP_DIR/config/.config" ]]; then
        log_info "恢复 .config 目录..."
        rsync -av --progress "$BACKUP_DIR/config/.config/" "$HOME/.config/" || log_warn "部分配置恢复失败"
    fi
    if [[ -d "$BACKUP_DIR/config/.local" ]]; then
        log_info "恢复 .local 目录..."
        rsync -av --progress "$BACKUP_DIR/config/.local/" "$HOME/.local/" || log_warn "部分配置恢复失败"
    fi
    log_info "配置文件已恢复"
else
    log_warn "跳过配置文件恢复"
fi

# 5. 创建敏感信息配置提醒
echo ""
log_warn "=========================================="
log_warn "重要：创建敏感信息配置文件"
log_warn "=========================================="
echo ""
log_info "创建 ~/.config/fish/secrets.fish 并添加："
echo ""
cat <<'EOF'
set -gx ANTHROPIC_AUTH_TOKEN "your-token-here"
set -gx ANTHROPIC_BASE_URL "https://api.deepseek.com/anthropic"
set -gx ANTHROPIC_MODEL deepseek-v4-pro
set -gx ANTHROPIC_DEFAULT_OPUS_MODEL deepseek-v4-pro
set -gx ANTHROPIC_DEFAULT_SONNET_MODEL deepseek-v4-pro
set -gx ANTHROPIC_DEFAULT_HAIKU_MODEL deepseek-v4-flash
set -gx CLAUDE_CODE_SUBAGENT_MODEL deepseek-v4-pro
set -gx CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC 1
set -gx CLAUDE_CODE_DISABLE_NONSTREAMING_FALLBACK 1
set -gx CLAUDE_CODE_EFFORT_LEVEL max
EOF
echo ""

# 6. 权限修复
log_info "修复文件权限..."
chmod 700 "$HOME" 2>/dev/null || true
find "$HOME" -type d -exec chmod 755 {} \; 2>/dev/null || log_warn "部分目录权限设置失败"
find "$HOME" -type f -exec chmod 644 {} \; 2>/dev/null || log_warn "部分文件权限设置失败"

# 7. 完成总结
echo ""
log_info "=========================================="
log_info "恢复完成！"
log_info "=========================================="
echo ""
log_info "已完成："
echo "  ✓ SSH 密钥"
echo "  ✓ GPG 密钥"
echo "  ✓ 家目录数据"
echo "  ✓ 配置文件（如选择）"
echo ""
log_warn "还需要手动完成："
echo "  • 创建 ~/.config/fish/secrets.fish"
echo "  • 导入浏览器书签和密码"
echo "  • 登录各类账号"
echo "  • 配置开发环境特定设置"
echo "  • 测试所有关键功能"
echo ""
log_info "提示：运行 'home-manager switch --flake /etc/nixos#alan' 应用配置"
