{ name, device, devices }:
{ lib, pkgs, ... }: with lib;
let
  kioskUsername = "kiosk";
  browser = "firefox";
in
{
  imports = [ ./xserver.nix ];

  hardware.opengl.enable = true;

  services.xserver = {
    displayManager.autoLogin = {
      user = kioskUsername;
      enable = true;
    };

    windowManager.i3.configFile = pkgs.writeScript "autostart" ''
      exec ${pkgs."${browser}"}/bin/${browser} --kiosk ${device.url}
    '';
  };

  users.users = {
    root.password = "root";
    "${kioskUsername}" = {
      group = kioskUsername;
      password = kioskUsername;
      isNormalUser = true;
      packages = [ pkgs."${browser}" ];
    };
  };
  users.groups."${kioskUsername}" = { };
}
