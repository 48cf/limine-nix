{ config, lib, pkgs, myPkgs, ... } :

let
  cfg = config.boot.loader.limine;
  efi = config.boot.loader.efi;

in {
  options.boot.loader.limine = {
    enable = lib.mkOption {
      default = false;
      type = lib.types.bool;
      description = lib.mdDoc ''
        Whether to enable the Limine bootloader.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    boot.loader.grub.enable = lib.mkDefault false;
    system = {
      boot.loader.id = "limine";
      build.installBootLoader = pkgs.substituteAll {
        src = ./limine-install.py;
        isExecutable = true;

        nix = config.nix.package;
        python3 = (pkgs.python3.withPackages (python-packages: [python-packages.psutil]));
        efibootmgr = pkgs.efibootmgr;
        limine = myPkgs.limine;
        efiSysMountPoint = efi.efiSysMountPoint;
      };
    };
  };
}
