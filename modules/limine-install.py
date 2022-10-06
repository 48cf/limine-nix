#!@python3@/bin/python3 -B

import json
import os
import psutil
import re
import shutil
import subprocess
import sys
import textwrap


def get_system_path(profile = 'system', generation = None, spec = None):
  if profile == 'system':
    result = '/nix/var/nix/profiles/system'
  else:
    result = f'/nix/var/nix/profiles/system-profiles/{profile}'

  if generation is None:
    return result

  result += f'-{generation}-link'

  if spec is None:
    return result

  return os.path.join(result, 'specialisation', spec)


def get_profiles():
  if os.path.isdir("/nix/var/nix/profiles/system-profiles/"):
    return [
      path for path in os.listdir("/nix/var/nix/profiles/system-profiles/")
      if not path.endswith("-link")
    ]

  return []


def get_specialisations(profile, generation):
  spec_path = os.path.join(get_system_path(profile, generation), 'specialisation')

  if not os.path.exists(spec_path):
    return []

  return os.listdir(spec_path)


def get_generations(profile = 'system'):
  gen_list = subprocess.check_output([
    '@nix@/bin/nix-env',
    '--list-generations',
    '-p', get_system_path(profile),
    '--option', 'build-users-group', ''],
    universal_newlines=True,
  )

  gen_lines = gen_list.split('\n')
  gens = [int(line.split()[0]) for line in gen_lines[:-1]]
  gens = [(gen, get_specialisations(profile, gen)) for gen in gens]

  return gens[-@maxGenerations@:]


def copy_from_profile(profile, generation, spec, name):
  store_path = get_system_path(profile, generation, spec)
  store_file_path = os.path.realpath(f'{store_path}/{name}')
  suffix = os.path.basename(store_file_path)
  store_path = os.path.basename(os.path.dirname(store_file_path))
  dest_path = f'/limine/{store_path}-{suffix}'
  efi_dest_path = f'@efiSysMountPoint@{dest_path}'

  if not os.path.exists(efi_dest_path):
    shutil.copyfile(store_file_path, efi_dest_path)

  return dest_path


def generate_config_entry(profile, gen, spec):
  spec_name = ' (specialization {spec})' if spec else ''
  gen_path = os.readlink(get_system_path(profile, gen, spec))
  kernel_path = copy_from_profile(profile, gen, spec, 'kernel')
  initrd_path = copy_from_profile(profile, gen, spec, 'initrd')
  cmdline = f'init={gen_path}/init '

  with open(f'{gen_path}/kernel-params') as file:
    cmdline += file.read()

  return textwrap.dedent(f'''
    ::Generation {gen}{spec_name}
      PROTOCOL=linux
      CMDLINE={cmdline.strip()}
      KERNEL_PATH=boot://{kernel_path}
      MODULE_PATH=boot://{initrd_path}
  ''')


def find_mounted_device(path):
  path = os.path.abspath(path)

  while not os.path.ismount(path):
    path = os.path.dirname(path)

  devices = [x for x in psutil.disk_partitions(all=True) if x.mountpoint == path]

  assert len(devices) == 1
  return devices[0].device


def find_disk_device(part):
  part = part.removeprefix('/dev/')
  disk = os.readlink(f'/sys/class/block/{part}')
  disk = os.path.dirname(disk)

  return f'/dev/{os.path.basename(disk)}'


def main():
  if not os.path.exists('@efiSysMountPoint@/limine'):
    os.mkdir('@efiSysMountPoint@/limine')

  additional_entries = json.loads('''@additionalEntries@''')
  additional_files = json.loads('''@additionalFiles@''')
  profiles = [('system', get_generations())]

  for profile in get_profiles():
    profiles += (profile, get_generations(profile))

  config_file = textwrap.dedent('''
    TIMEOUT=5
    EDITOR_ENABLED=@enableEditor@
    GRAPHICS=yes
    DEFAULT_ENTRY=2

    # NixOS boot entries start here
  ''')

  for (profile, gens) in profiles:
    group_name = 'default profile' if profile == 'system' else f"profile '{profile}'"
    config_file += f':+NixOS {group_name}\n'

    for (gen, specs) in sorted(gens, key=lambda x: x[0], reverse=True):
      config_file += generate_config_entry(profile, gen, None)

      for spec in specs:
        config_file += generate_config_entry(profile, gen, spec)

  config_file += '\n# NixOS boot entries end here\n\n'

  for name, entry in additional_entries.items():
    indented_entry = textwrap.indent(entry, '  ')
    config_file += f':{name}\n{indented_entry}\n'

  with open('@efiSysMountPoint@/limine/limine.cfg', 'w') as file:
    file.write(config_file.strip())

  shutil.copyfile('@limine@/usr/local/share/limine/BOOTX64.EFI', '@efiSysMountPoint@/limine.efi')

  for dest_path, source_path in additional_files.items():
    efi_dest_path = f'@efiSysMountPoint@/{dest_path}'
    efi_dir_name = os.path.dirname(efi_dest_path)

    if not os.path.exists(efi_dir_name):
      os.makedirs(efi_dir_name)

    shutil.copyfile(source_path, efi_dest_path)

  efi_partition = find_mounted_device('@efiSysMountPoint@')
  efi_disk = find_disk_device(efi_partition)
  efibootmgr_output = subprocess.check_output([
    '@efibootmgr@/bin/efibootmgr',
    '-c',
    '-d', efi_disk,
    '-p', efi_partition.removeprefix(efi_disk).removeprefix('p'),
    '-l', '\limine.efi',
    '-L', 'Limine',
  ], stderr=subprocess.STDOUT, universal_newlines=True)

  for line in efibootmgr_output.split('\n'):
    if matches := re.findall(r'Boot([0-9a-fA-F]{4}) has same label Limine', line):
      subprocess.run(
        ['@efibootmgr@/bin/efibootmgr', '-b', matches[0], '-B'],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
      )


if __name__ == '__main__':
  main()
