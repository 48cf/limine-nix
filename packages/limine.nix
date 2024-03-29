{ lib, clangStdenv, fetchurl, nasm }:

clangStdenv.mkDerivation rec {
  pname = "limine";
  version = "4.20230120.0";
  src = fetchurl {
    url = "https://github.com/limine-bootloader/limine/releases/download/v${version}/limine-${version}.tar.xz";
    sha256 = "sha256-IxNgaZUWVcjBBlGsWX9ZtF74MuYHBwdK1C4q8dL2zSI=";
  };
  nativeBuildInputs = [ nasm ];
  configureFlags = [
    "--enable-uefi-x86_64"
    "--enable-uefi-ia32"
    "--enable-bios"
  ];
  meta = with lib; {
    homepage = "https://limine-bootloader.org/";
    description = "Limine Bootloader";
    license = licenses.bsd2;
    platforms = [ "i686-linux" "x86_64-linux" ];
  };
}
