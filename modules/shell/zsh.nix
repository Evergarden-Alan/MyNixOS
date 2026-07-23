{ config, pkgs, ... }:

{
  # Zsh Shell（备用）
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    initContent = ''
      # Starship 提示符
      eval "$(starship init zsh)"

      # Zoxide 目录跳转
      eval "$(zoxide init zsh)"
    '';

    shellAliases = {
      cat = "bat";
      ls = "eza --icons=auto";
      vim = "nvim";
      ll = "eza -l --icons=auto";
      la = "eza -la --icons=auto";
    };
  };
}
