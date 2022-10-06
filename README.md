# limine-nix

A Limine package for Nix OS that allows you to use Limine as the bootloader.

Currently only supports UEFI firmware on x86_64 platform, BIOS and AArch64 support is going to be added soon.

# Installation and usage

First, you will have to import the package as a tarball in your configuration.nix:

```nix
{
  imports = [
    # ...

    (fetchTarball "https://github.com/czapek1337/limine-nix/tarball/master")
  ];
}
```

And now you can enable the `boot.loader.limine.enable` option:

```nix
{
    # ...
    boot.loader.limine.enable = true;
    # ...
}
```
