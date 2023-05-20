{ lib, pkgs, ... }: with lib;
let
  devices = {
    display_raum3 = {
      url = "https://hass.ctdo.de/display-raum-3/default_view";
      serial = "141134940400155";
    };
    display_raum2 = {
      url = "https://hass.ctdo.de/";
      serial = "150442586900203";
    };
    display_raum4 = {
      url = "https://hass.ctdo.de/";
      serial = "141134940400164";
    };
    debug = {
      url = "https://hass.ctdo.de/";
      serial = "unknown";
    };
  };
in
{
  specialisation = mapAttrs'
    (name: device: nameValuePair (name) ({
      configuration = {
        imports = [
          (import ./kiosk_config.nix { inherit name device devices; })
        ];
      };
    }))
    devices;

  system.activationScripts = mapAttrs'
    # We need to run as last script. Lets hope zzz_ as prefix is enough
    (name: device: nameValuePair ("zzz_" + name) ({
      text = mkDefault ''
        SERIAL=$(cat /sys/class/dmi/id/board_serial 2>/dev/null || echo unknown)
        if [ "$SERIAL" = "${device.serial}" -a -z $SWITCHING ]; then
           export SWITCHING=true
           echo ${device.serial}
           systemConfig="$systemConfig/specialisation/${name}"
           $systemConfig/activate
        fi
      '';
    }))
    devices;

}
