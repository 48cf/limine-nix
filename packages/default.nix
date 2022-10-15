{ lib, pkgs } : {
  limine = import ./limine.nix {
    inherit lib;
    inherit pkgs;

    fetchurl = pkgs.fetchurl;
    llvm = pkgs.llvmPackages_14;
  };
}
