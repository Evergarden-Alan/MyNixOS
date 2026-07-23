{ config, pkgs, ... }:

{
  # 编程语言和工具
  home.packages = with pkgs; [
    # Node.js
    nodejs
    # npm 通常随 nodejs 一起安装

    # Python
    python3
    python3Packages.pip

    # 其他工具
    bun  # JavaScript 运行时
  ];
}
