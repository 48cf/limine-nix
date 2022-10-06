{ config, lib, pkgs, ... } :

{
  config._module.args = {
    myPkgs = import ../packages {};
  };

  imports = [./limine.nix];
}
