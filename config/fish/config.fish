if status is-interactive
    # Commands to run in interactive sessions can go here
end
set fish_greeting ""
set -p PATH ~/.local/bin
starship init fish | source
zoxide init fish --cmd cd | source

# 基础 API 配置
set -gx ANTHROPIC_BASE_URL "https://api.deepseek.com/anthropic"
set -gx ANTHROPIC_AUTH_TOKEN sk-ff2afb3ae42a42d99d7a84e26e5c8df4

# 建议：禁用不必要的流量以加速
set -gx CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC 1


set -gx ANTHROPIC_MODEL deepseek-v4-pro[1m] 
set -gx ANTHROPIC_DEFAULT_OPUS_MODEL deepseek-v4-pro
set -gx ANTHROPIC_DEFAULT_SONNET_MODEL deepseek-v4-pro
set -gx ANTHROPIC_DEFAULT_HAIKU_MODEL deepseek-v4-flash
set -gx CLAUDE_CODE_SUBAGENT_MODEL deepseek-v4-pro
set -gx CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC 1
set -gx CLAUDE_CODE_DISABLE_NONSTREAMING_FALLBACK 1
set -gx CLAUDE_CODE_EFFORT_LEVEL max

 # 定义 chat 模式函数
function c
    #    set -lx ANTHROPIC_MODEL deepseek-v4-flash
    claude $argv
end


# 111
function y
	set tmp (mktemp -t "yazi-cwd.XXXXXX")
	yazi $argv --cwd-file="$tmp"
	if read -z cwd < "$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
		builtin cd -- "$cwd"
	end
	rm -f -- "$tmp"
end

function cat 
	command bat $argv
end
function ls
	command eza --icons=auto $argv
end
function vim
	command nvim $argv
end
function lt
end

function lt
	command eza --icons --tree $argv
end
# grub
abbr grub 'LANGUAGE=en_US.UTF-8 LANG=en_US.UTF-8 sudo grub-mkconfig -o /boot/grub/grub.cfg'
# 小黄鸭补帧 需要steam安装正版小黄鸭
abbr lsfg 'LSFG_PROCESS="miyu"'
# fa运行fastfetch
abbr fa fastfetch
abbr reboot 'systemctl reboot'
function sl 
	command sl | lolcat	
end
function 滚
	sysup 
end
function raw
	command ~/.local/bin/random-anime-wallpaper-dms $argv
end

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
