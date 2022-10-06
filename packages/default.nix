{ pkgs? import <nixpkgs> {} } :

{
  limine = import ./limine.nix {
    inherit pkgs;

    llvm = pkgs.llvmPackages_14;
    lld = pkgs.lld_14;
  };
}
