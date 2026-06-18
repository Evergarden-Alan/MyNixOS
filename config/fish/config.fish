if status is-interactive
    # Commands to run in interactive sessions can go here
end
set fish_greeting ""
set -p PATH ~/.local/bin
starship init fish | source
zoxide init fish --cmd cd | source

# 基础 API 配置
# 注意：API Token 等敏感信息请放到 ~/.secrets 文件中（不要提交到 git）
# source ~/.secrets
set -gx ANTHROPIC_BASE_URL "https://api.deepseek.com/anthropic"
# set -gx ANTHROPIC_AUTH_TOKEN "your-token-here"  # 请在 ~/.secrets 中设置

# 建议：禁用不必要的流量以加速
set -gx CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC 1

set -gx ANTHROPIC_MODEL deepseek-v4-pro[1m]
set -gx ANTHROPIC_DEFAULT_OPUS_MODEL deepseek-v4-pro
set -gx ANTHROPIC_DEFAULT_SONNET_MODEL deepseek-v4-pro
set -gx ANTHROPIC_DEFAULT_HAIKU_MODEL deepseek-v4-flash
set -gx CLAUDE_CODE_SUBAGENT_MODEL deepseek-v4-pro
set -gx CLAUDE_CODE_DISABLE_NONSTREAMING_FALLBACK 1
set -gx CLAUDE_CODE_EFFORT_LEVEL max

# 定义 chat 模式函数
function c
	#    set -lx ANTHROPIC_MODEL deepseek-v4-flash
    claude $argv
end

# 定义 reasoner 模式函数
#function cr
#    set -lx ANTHROPIC_MODEL deepseek-v4-pro
#    claude $argv
#end

# 记得保存到函数文件或 config.fish

function z
    command zellij
end

function y
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $argv --cwd-file="$tmp"
    if read -z cwd <"$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
end

function cat
    command bat $argv
end
function ls
    command eza --icons $argv
end

function lt
    command eza --icons --tree $argv
end
# grub
abbr grub 'sudo grub-mkconfig -o /boot/grub/grub.cfg'
# 小黄鸭补帧 需要steam安装正版小黄鸭
abbr lsfg 'LSFG_PROCESS="miyu"'
# fa运行fastfetch
abbr fa fastfetch
abbr reboot 'systemctl reboot'
function sl
    command sl | lolcat
end
# NixOS 中没有 sysup，以下函数已注释
# function 滚
#     sysup
# end
# NixOS 中没有 random-anime-wallpaper-dms，以下函数已注释
# function raw
#     command ~/.local/bin/random-anime-wallpaper-dms $argv
# end

# NixOS 不使用 AUR/yay，以下函数已注释
# function 安装
#     command yay -S $argv
# end
#
# function 卸载
#     command yay -Rns $argv
# end

# Added by LM Studio CLI (lms)
# set -gx PATH $PATH $HOME/.lmstudio/bin  # 如不需要可保持注释
# End of LM Studio CLI section

set -gx PATH $HOME/.npm-global/bin $PATH

# 管理 dotfiles 的裸仓库别名
function dot
    command git --git-dir=$HOME/.dotfiles --work-tree=$HOME $argv
end




