{ config, lib, pkgs, myPkgs, limine, ... } :

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

    enableEditor = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = lib.mdDoc ''
        Whether to allow editing the boot entries before booting them.
        It is recommended to set this to false, as it allows gaining root
        access by passing `init=/bin/sh` as a kernel parameter.
      '';
    };

    maxGenerations = lib.mkOption {
      default = null;
      example = 50;
      type = lib.types.nullOr lib.types.int;
      description = lib.mdDoc ''
        Maximum number of latest generations in the boot menu.
        Useful to prevent boot partition of running out of disk space.

        `null` means no limit i.e. all generations that were not
        garbage collected yet.
      '';
    };

    additionalEntries = lib.mkOption {
      default = {};
      type = lib.types.attrsOf lib.types.str;
      example = lib.literalExpression ''
        { "memtest86" = '''
          PROTOCOL=chainload
          IMAGE_PATH=boot:///efi/memtest86/memtest86.efi
        '''; }
      '';
      description = lib.mdDoc ''
        Any additional entries you want added to the Limine boot menu. Each attribute denotes
        the display name of the boot entry, which need be formatted according to the Limine
        documentation which you can find [here](https://github.com/limine-bootloader/limine/blob/trunk/CONFIG.md).
      '';
    };

    additionalFiles = lib.mkOption {
      default = {};
      type = lib.types.attrsOf lib.types.path;
      example = lib.literalExpression ''
        { "efi/memtest86/memtest86.efi" = "${pkgs.memtest86-efi}/BOOTX64.efi"; }
      '';
      description = lib.mdDoc ''
        A set of files to be copied to {file}`/boot`. Each attribute name denotes the
        destination file name in {file}`/boot`, while the corresponding attribute value
        specifies the source file.
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
        limine = limine;
        efiSysMountPoint = efi.efiSysMountPoint;
        canTouchEfiVariables = efi.canTouchEfiVariables;
        maxGenerations = if cfg.maxGenerations == null then 0 else cfg.maxGenerations;
        timeout = if config.boot.loader.timeout != null then config.boot.loader.timeout else "10";
        enableEditor = if cfg.enableEditor then "yes" else "no";
        additionalEntries = builtins.replaceStrings ["\\n"] ["\\\\n"] (builtins.toJSON cfg.additionalEntries);
        additionalFiles = builtins.replaceStrings ["\\n"] ["\\\\n"] (builtins.toJSON cfg.additionalFiles);
      };
    };
  };
}
