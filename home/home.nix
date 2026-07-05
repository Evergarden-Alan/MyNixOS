# ~/.dotfiles/home/home.nix
{ config, pkgs, lib, inputs, myUsername, ... }:

{
  # ---------------------------------------------------
  # 基础信息配置
  # ---------------------------------------------------
  home.username = myUsername;
  home.homeDirectory = "/home/${myUsername}";
  home.stateVersion = "25.05";

  # ---------------------------------------------------
  # 环境变量与路径
  # ---------------------------------------------------
  home.sessionVariables = {
    NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.npm-global";
  };
  home.sessionPath = [
    "${config.home.homeDirectory}/.npm-global/bin"
  ];

  # ---------------------------------------------------
  # Git
  # ---------------------------------------------------
  programs.git = {
    enable = true;
    settings.user.name = "Alan";
    settings.user.email = "ve1.11@outlook.com";
  };
  programs.git.lfs.enable = true;

  # ---------------------------------------------------
  # Vim
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
  # 终端生态 (Fish 全家桶)
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
    swaylock        # hyprlock 的 fallback
    swaybg          # 壁纸 (nixpkgs 中 swww 已损坏，上游改名 awww 但 nixpkgs 未跟进)
    waypaper
    waybar
    cava

    # --- 通知与输入 (fcitx5 本体由 i18n.inputMethod 系统级提供) ---
    mako
    libnotify
    fcitx5-gtk
    polkit_gnome

    # --- 系统工具 ---
    brightnessctl
    ddcutil
    playerctl
    pavucontrol
    wlogout
    hyprpicker
    networkmanagerapplet

    # --- 截图与录屏 ---
    grim
    slurp
    wf-recorder
    wl-screenrec
    ffmpeg
    satty           # 截图编辑器 (power-screenshot.sh 用)
    swappy          # 截图编辑器备选

    # --- 终端与系统工具 ---
    alacritty
    kitty
    fastfetch
    btop
    ripgrep
    tree
    eza
    bat
    zellij
    pulseaudio-utils
    fzf
    jq
    file

    # --- 蓝牙与显示 ---
    blueman
    wlsunset
    xorg.xhost
    xorg.xprop      # niri-force-kill-window 用

    # --- 网络/下载 (f.fish waifu 抓图用) ---
    curl

    # --- 声音主题 (截图/错误音效，脚本通过 find 在 nix store 定位) ---
    sound-theme-freedesktop

    # --- 字体 (nerdfonts 已在 modules/desktop.nix fonts.packages 中，此处只补未在那里的) ---
    lxgw-wenkai

    # --- 娱乐 ---
    sl
    lolcat

    # --- 生产力 ---
    vscode

    # --- 运行环境 ---
    nodejs

    # --- Matugen (Material You 配色生成) ---
    inputs.matugen.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # ---------------------------------------------------
  # polkit 认证代理 (systemd user service，供 niri 启动)
  # ---------------------------------------------------
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    Unit = {
      Description = "polkit-gnome-authentication-agent-1";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # ---------------------------------------------------
  # 软链接接管区
  # ---------------------------------------------------

  # === 1. 纯 UI / 独立工具 (Nix Store 软链接) ===
  xdg.configFile."btop".source = ../config/btop;
  xdg.configFile."fastfetch".source = ../config/fastfetch;
  xdg.configFile."fuzzel".source = ../config/fuzzel;
  xdg.configFile."kitty".source = ../config/kitty;
  xdg.configFile."waypaper".source = ../config/waypaper;
  xdg.configFile."matugen".source = ../config/matugen;

  # === 2. 已被 Nix 接管的工具 (精准软链接) ===
  xdg.configFile."starship.toml".source = ../config/starship.toml;
  xdg.configFile."yazi/theme.toml".source = ../config/yazi/theme.toml;

  # === 3. 即时生效区 (mkOutOfStoreSymlink，编辑后无需 rebuild) ===
  xdg.configFile."fish/conf.d/my_arch_config.fish".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/config/fish/config.fish";
  xdg.configFile."niri".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/config/niri";
  xdg.configFile."waybar".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/config/waybar";
  xdg.configFile."scripts".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/config/scripts";

  # ---------------------------------------------------
  # 让脚本可执行 (mkOutOfStoreSymlink 不保留 +x)
  # ---------------------------------------------------
  home.activation.makeScriptsExecutable = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD chmod +x \
      ${config.home.homeDirectory}/.dotfiles/config/niri/scripts/* \
      ${config.home.homeDirectory}/.dotfiles/config/waybar/scripts/* \
      ${config.home.homeDirectory}/.dotfiles/config/scripts/* \
      2>/dev/null || true
  '';

  programs.home-manager.enable = true;
}
