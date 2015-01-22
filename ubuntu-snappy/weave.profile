#include <tunables/global>

profile weave (attach_disconnected) {
  capability,
  network,
  / rwkl,
  /** rwlkm,
  /** pix,

  mount,
  remount,
  umount,
  dbus,
  signal,
  ptrace,
  unix,
  change_profile -> docker_docker_*,
}
