# ~/.dotfiles/home/home.nix
{ config, pkgs, ... }:

{
  # ---------------------------------------------------
  # 基础信息配置
  # ---------------------------------------------------
  home.username = "alan";
  home.homeDirectory = "/home/alan";
  home.stateVersion = "24.05";

  # ---------------------------------------------------
  # 环境变量与路径重定向 (专为 Node.js 跨平台部署准备)
  # ---------------------------------------------------
  home.sessionVariables = {
    # 将 npm 全局安装路径重定向到用户目录，避免只读文件系统报错
    NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.npm-global";
  };

  home.sessionPath = [
    # 确保通过 npm 全局安装的工具 (如 claude-code) 可以直接在终端运行
    "${config.home.homeDirectory}/.npm-global/bin"
  ];

  # ---------------------------------------------------
  # 原生 Nix 模块：Git (极简版)
  # ---------------------------------------------------
  programs.git = {
    enable = true;
    settings.user.name = "Alan";
    settings.user.email = "ve1.11@outlook.com";
    # 代理暂时封印，需要时再打开
    # extraConfig.http.proxy = "http://127.0.0.1:7890";
    # extraConfig.https.proxy = "http://127.0.0.1:7890";
  };
  
  programs.git.lfs.enable = true;

  # ---------------------------------------------------
  # 原生 Nix 模块：Vim
  # ---------------------------------------------------
  programs.vim = {
    enable = true;
    extraConfig = ''
      set number
      set relativenumber
      set cursorline
      syntax on
      set autoindent
      set incsearch
      set hlsearch
      set ignorecase
      set smartcase
      set undofile
      silent !mkdir -p ~/.cache/vim/undo
      set undodir=~/.cache/vim/undo
      set clipboard=unnamedplus
      set mouse=a
    '';
  };

  # ---------------------------------------------------
  # 原生 Nix 模块：终端生态 (Fish 全家桶)
  # ---------------------------------------------------
  programs.fish.enable = true;
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
  };
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };
  programs.yazi = {
    enable = true;
    shellWrapperName = "y";

  };

  # ---------------------------------------------------
  # 用户级软件包
  # ---------------------------------------------------
  home.packages = with pkgs; [
    # --- 桌面核心 (Niri 必需) ---
    fuzzel
    swayosd
    cliphist
    wl-clipboard
    hyprlock
    waypaper
    awww

    # --- 终端与系统工具 ---
    alacritty
    kitty
    fastfetch
    btop
    ripgrep
    tree
    eza
    bat
    
    # --- 生产力 ---
    vscode
    #obsidian
    
    # --- 运行环境 ---
    nodejs      # 提供 node 和 npm 环境，用于后续部署 claude-code
  ];

  # ---------------------------------------------------
  # 软链接接管区 (将本地大本营的配置链接到 ~/.config)
  # ---------------------------------------------------

  # === 1. 纯 UI / 独立工具 (安全：直接软链接整个文件夹) ===
  xdg.configFile."btop".source = ../config/btop;
  xdg.configFile."fastfetch".source = ../config/fastfetch;
  xdg.configFile."fuzzel".source = ../config/fuzzel;
  xdg.configFile."kitty".source = ../config/kitty;
  xdg.configFile."waypaper".source = ../config/waypaper;
  #xdg.configFile."niri".source = ../config/niri;
  #xdg.configFile."waybar".source = ../config/waybar;

  # === 2. 已被 Nix 接管的工具 (避坑：精准软链接，防止冲突) ===
  
  # 【Starship】
  # 只要不在 programs.starship 里写 settings，HM 就不会生成这个文件，直接链过去即可
  xdg.configFile."starship.toml".source = ../config/starship.toml;

  # 【Yazi】
  # 为了保留 yazi 的终端自动 cd 魔法，我们保留程序的接管，仅软链接具体的文件和插件
  xdg.configFile."yazi/theme.toml".source = ../config/yazi/theme.toml;
  # 如果你有 lua 插件，把这两行也解开：
  # xdg.configFile."yazi/init.lua".source = ../config/yazi/init.lua;
  # xdg.configFile."yazi/plugins".source = ../config/yazi/plugins;


  # ---------------------------------------------------
  # 软链接接管区 (动态修改，即时生效版)
  # ---------------------------------------------------

  # 注意：使用 mkOutOfStoreSymlink 必须写绝对路径！
  # 我们用 ${config.home.homeDirectory} 来动态获取你的 /home/alan
  
  xdg.configFile."fish/conf.d/my_arch_config.fish".source = 
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/config/fish/config.fish";
    
  xdg.configFile."niri".source = 
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/config/niri";
    
  xdg.configFile."waybar".source = 
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/config/waybar";

   programs.home-manager.enable = true;
}
