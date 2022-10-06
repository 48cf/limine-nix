{ config, lib, pkgs, ... } :

let
  myPkgs = import ../packages {};

in {
  config._module.args = {
    myPkgs = myPkgs;
    limine = myPkgs.limine;
  };

  imports = [./limine.nix];
}
