{ lib, pkgs } : {
  limine = import ./limine.nix {
    inherit lib;

    clangStdenv = pkgs.clangStdenv;
    fetchurl = pkgs.fetchurl;
    nasm = pkgs.nasm;
  };
}
