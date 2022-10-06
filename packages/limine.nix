{ pkgs, llvm, lld } :

pkgs.stdenv.mkDerivation rec {
  name = "limine";
  version = "4.20221006.1";
  src = fetchTarball {
    url = "https://github.com/limine-bootloader/limine/releases/download/v${version}/limine-${version}.tar.xz";
    sha256 = "1mrmc45icspd07y90b3kylkxpm4p25fnj1lq9h1gkwdbdwmzllbm";
  };
  nativeBuildInputs = [
    pkgs.autoconf
    pkgs.automake
    pkgs.nasm
    llvm.bintools
    llvm.clang
    lld
  ];
  configurePhase = ''
    ./configure --enable-uefi-x86_64
  '';
  installPhase = ''
    make DESTDIR=$out install
  '';
}
