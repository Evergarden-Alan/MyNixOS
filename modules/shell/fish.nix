{ config, pkgs, ... }:

{
  # Fish Shell
  programs.fish = {
    enable = true;

    shellInit = ''
      # 禁用问候语
      set fish_greeting ""

      # 添加本地 bin 到 PATH
      set -p PATH ~/.local/bin

      # Bun
      set --export BUN_INSTALL "$HOME/.bun"
      set --export PATH $BUN_INSTALL/bin $PATH
    '';

    interactiveShellInit = ''
      # Starship 提示符
      starship init fish | source

      # Zoxide 目录跳转
      zoxide init fish --cmd cd | source

      # 加载敏感信息（不纳入版本控制）
      if test -f ~/.config/fish/secrets.fish
        source ~/.config/fish/secrets.fish
      end
    '';

    # Shell 别名
    shellAliases = {
      cat = "bat";
      ls = "eza --icons=auto";
      vim = "nvim";
      lt = "eza --icons --tree";
      fa = "fastfetch";
      reboot = "systemctl reboot";
    };

    # Shell 缩写
    shellAbbrs = {
      grub = "LANGUAGE=en_US.UTF-8 LANG=en_US.UTF-8 sudo grub-mkconfig -o /boot/grub/grub.cfg";
    };

    # 自定义函数
    functions = {
      # Yazi 文件管理器集成
      y = ''
        set tmp (mktemp -t "yazi-cwd.XXXXXX")
        yazi $argv --cwd-file="$tmp"
        if read -z cwd < "$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
          builtin cd -- "$cwd"
        end
        rm -f -- "$tmp"
      '';

      # sl 彩色输出
      sl = ''
        command sl | lolcat
      '';

      # Claude 快捷命令
      c = ''
        claude $argv
      '';
    };
  };
}
