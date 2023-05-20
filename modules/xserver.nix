{ ... }: {
  services.xserver = {
    enable = true;
    layout = "de"; # keyboard layout
    libinput.enable = true;

    # Let lightdm handle autologin
    displayManager.lightdm = {
      enable = true;
    };

    # Start openbox after autologin
    windowManager.i3.enable = true;

    displayManager = {
      defaultSession = "none+i3";
      autoLogin = { };
    };
  };

  systemd.services."display-manager".after = [
    "network-online.target"
    "systemd-resolved.service"
  ];
}
