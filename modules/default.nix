{ inputs, lib, config, pkgs, ... }: {
  imports = [
    ./kiosk.nix
  ];

  #services.getty.autologinUser = lib.mkForce "root";
  services.openssh.enable = true;
  networking.useDHCP = true;
  documentation.man.enable = false;

  boot.initrd.availableKernelModules = [ "uhci_hcd" "ehci_pci" "ahci" "usbhid" ];
  boot.initrd.kernelModules = [ "radeon" ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  boot.initrd.supportedFilesystems = lib.mkForce [ ];
  boot.supportedFilesystems = lib.mkForce [ ];
}
