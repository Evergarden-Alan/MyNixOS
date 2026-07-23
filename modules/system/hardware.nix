{ config, pkgs, ... }:

{
  # CPU 微码更新
  hardware.cpu.intel.updateMicrocode = true;
  # hardware.cpu.amd.updateMicrocode = true;  # AMD CPU 时改用这行

  # OpenGL/Vulkan 支持
  hardware.graphics = {
    enable = true;
    enable32Bit = true;  # 32位应用支持（游戏需要）
    extraPackages = with pkgs; [
      intel-media-driver  # Intel VAAPI
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
      intel-compute-runtime  # OpenCL
    ];
  };

  # NVIDIA 驱动（如果有独显）
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = true;  # 使用开源内核模块
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # 蓝牙
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
      };
    };
  };

  # 声音系统 - PipeWire
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # 电源管理
  powerManagement = {
    enable = true;
    powertop.enable = true;
  };
  services.power-profiles-daemon.enable = true;

  # Intel 低功耗模式守护进程
  services.thermald.enable = true;
}
