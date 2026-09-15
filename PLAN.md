# Blauer Zimt — Working Plan

The living roadmap: where the project is and what happens next. Decision
*rationale* lives in [`docs/adr/`](docs/adr/), build instructions in the
[README](README.md).

> **Maintenance:** this file is updated as work completes, not afterwards. When a
> step is finished, tick its box and update the status table in the same change.

## Where we are

| Milestone | State |
|---|---|
| **0 — Architecture and repository foundation** | ✅ Complete (2026-09-09) |
| **1 — Minimal Sway system** | ✅ Complete (2026-09-11) |
| **2 — Complete desktop foundation** | ▶ Next |
| 3 — OCI publishing | Not started |
| 4 — Update system | Not started |
| 5 — Workstation and gaming foundation | Not started |
| 6 — Blauer Zimt DX | Not started |
| 7 — Automated VM testing | Not started |
| 8 — Installer ISO | Not started |
| 9 — Bare-metal AMD validation | Not started |
| 10 — Stable and testing streams | Not started |
| 11 — Fedora major upgrade automation | Not started |

**Desktop:** Sway with upstream configuration, decided 2026-09-11 before any desktop
package was installed — [ADR 0002](docs/adr/0002-desktop-sway.md). The Cinnamon plan
was replaced, not built on; the base image is unaffected.

## Milestone 0 — Architecture and repository foundation ✅

Completed 2026-09-09.

- [x] Research current Fedora bootc / Atomic / Universal Blue architecture
- [x] Choose and record the base image — [ADR 0001](docs/adr/0001-base-image.md)
- [x] Host toolchain: podman (rootful), qemu, OVMF, just, skopeo
- [x] `Containerfile` deriving from `fedora-bootc:44`, digest-pinned
- [x] `bootc container lint` passing as the final layer — 13 passed / 1 skipped
- [x] `Justfile` with `build`, `build-qcow2`, `run-vm`, `clean`
- [x] QCOW2 disk image generated
- [x] VM boots through UEFI and logs in
- [x] `bootc status` reports a valid deployment
- [x] `README.md`, `PLAN.md` and ADR 0001 written
- [x] Commit the foundation to git

## Image hierarchy

Build the hierarchy conceptually now, physically later.

**Now** — one repository, one `Containerfile`, one image:

```
quay.io/fedora/fedora-bootc:44   (digest-pinned)
              │
              ▼
      blauer-zimt:44
```

The layer boundaries (hardware / Sway / common / edition) exist as ordered,
commented sections and separate package lists *inside* that single file. The seams
are real and documented; they are simply not image boundaries yet.

**Later** — split when a second consumer exists. The first genuine forcing function
is Blauer Zimt DX at Milestone 6:

```
fedora-bootc:44
      │
      ▼
blauer-zimt-base      ← hardware + Sway + common
      ├─────────────┐
      ▼             ▼
blauer-zimt    blauer-zimt-dx
```

Splitting earlier buys nothing and costs a multi-image CI graph, cross-image digest
pinning and a slower local loop.

**Release channels** are tags on the same build, not parallel hierarchies:
`:testing` on every green build, `:stable` promoted after validation. Tag
conventions get designed once publishing exists (Milestone 3).

## Milestone 1 — Minimal Sway system ✅

Completed 2026-09-11. A VM boots to a greetd login and into a usable Sway session
— Wayland session type, `sway-systemd` environment, Xwayland, upstream keybindings —
with nothing else installed.

The rule from Milestone 0 still governs: **one unknown at a time.** The base, the
disk-image path and the VM invocation are known-good; this milestone adds the
compositor, the login path and a graphical VM display, in that order.

- [x] **Establish the package set empirically.** Queried 2026-09-11 from a
      throwaway container of the built image. Findings:
      - `sway-config` providers: `-upstream` and `-minimal` are built from `sway`
        1.11-3 itself; `-fedora` is the SIG's separate package (0.4.3).
      - `sway-config-upstream` **requires** `sway`, `swaybg`, `sway-wallpapers`,
        `mesa-dri-drivers`, `xorg-x11-server-Xwayland`, `polkit`. It only
        **recommends** `foot`, `wmenu`, `sway-systemd`, `swaylock`, `swayidle`,
        `grim` (and `qt5`/`qt6-qtwayland` if Qt is present). It owns
        `/etc/sway/config` and `/usr/share/wayland-sessions/sway.desktop`.
      - `sway` itself requires libraries only — wlroots **0.19**, `libxcb` (so
        Xwayland support is compiled in) — plus `sway-config`; recommends nothing.
      - Effective dnf config: `install_weak_deps = 1`. Recommends get installed
        unless we say otherwise.
      - Comps groups are **`swaywm`** and **`swaywm-extended`**, not `sway-desktop`.
        Contents unread; they are Milestone 2's checklist.
      - The base lacks Mesa (DRI and Vulkan), Xwayland, PipeWire and WirePlumber.
        It has NetworkManager 1.56, polkit 127, and Adwaita Sans/Mono fonts.
      - `sway-systemd` ships `/etc/sway/config.d/10-systemd-{session,cgroups}.conf`
        (picked up by upstream's `include`), `sway-session.target`, and two
        **opt-in** drop-ins under `/usr/share/sway-systemd/`:
        `95-xdg-desktop-autostart.conf` (XDG autostart through systemd) and
        `95-system-keyboard-config.conf`. It costs Python 3 plus five Python
        libraries; the cgroup assignment script is the Python part.
      - `greetd` ships `/etc/greetd/config.toml`, `greetd.service`, two PAM files,
        `sysusers.d` and `tmpfiles.d` entries (the bootc-friendly way to own a user
        and `/var/lib/greetd`), and the fallback greeter `agreety`. Its SELinux
        policy is a separate subpackage, **`greetd-selinux`** — missed by the file
        query, caught by the install diff in step 2. `tuigreet` is one binary,
        configured by flags.
- [x] **Install Sway.** Built 2026-09-11 with every direct dependency named —
      the config provider explicitly, or the resolver may choose `-fedora`:
      `mesa-dri-drivers sway sway-config-upstream sway-systemd foot wmenu greetd tuigreet`.
      Build and `bootc container lint` passed; **no `--allowerasing`** was needed.
      `rpm -qa` diff against the base: **542 → 814 packages, 272 new, 0 removed**,
      for 8 named. Roughly half are hard transitive requirements (Mesa + LLVM,
      wlroots, X11 and Wayland libraries, fcft/fontconfig and Noto Sans, Python for
      `sway-systemd`). The rest arrived through **Recommends** — including things
      Milestone 2 was going to add deliberately, and things nobody asked for:
      - `greetd-selinux` (welcome), `swaylock`, `swayidle`, `grim`, `mesa-vulkan-drivers`
        + `vulkan-loader` — the deferred Vulkan decision was overridden by a weak dep.
      - the whole PipeWire stack with WirePlumber, PulseAudio and JACK compatibility,
        Bluetooth and libcamera plugins, and `rtkit`.
      - `xdg-desktop-portal` + `xdg-desktop-portal-gtk` (but **not** `-wlr`), and with
        them GTK 3, Adwaita icons and cursors, dconf, at-spi, `geoclue2`, `upower`.
      - `localsearch` (a file-indexing daemon with user units) and its extractor
        chain: poppler, exiv2, libgsf, gstreamer, libavcodec, libheif — and via
        libavcodec, `intel-mediasdk` on an AMD-only image.
      - `emacs-filesystem`, via `desktop-file-utils`.
      This diff is the evidence behind [ADR 0003](docs/adr/0003-no-weak-dependencies.md).
- [x] **Turn weak dependencies off** — [ADR 0003](docs/adr/0003-no-weak-dependencies.md).
      Drop-in at `/etc/dnf/libdnf5.conf.d/blauer-zimt.conf`, written before the
      install line; `greetd-selinux` named. Rebuilt 2026-09-11:
      `install_weak_deps = 0`; `matchpathcon /usr/bin/greetd` →
      `xdm_exec_t` (greetd is confined like any display manager);
      **542 → 680 packages, 138 hard arrivals for 9 named, 134 kept out** versus the
      weak-deps build — the PipeWire stack, portals, `localsearch` and its codec
      chain, `swaylock`/`swayidle`/`grim`, `mesa-vulkan-drivers`, `dbus-tools`.
      Still present as *hard* requirements, worth knowing: GTK 3 with Adwaita icons
      and cursors and its image-loader chain (almost certainly Xwayland →
      `libdecor` → GTK plugin, soname-linked; verify with
      `rpm -q --whatrequires 'libgtk-3.so.0()(64bit)'`), Noto Sans via fontconfig,
      `vulkan-loader` via wlroots, and the SELinux Python tooling via `greetd-selinux`.
- [x] **Login: greetd + tuigreet.** Done 2026-09-11. `system_files/etc/greetd/config.toml`
      (`tuigreet --sessions /usr/share/wayland-sessions`) `COPY`ed after the install
      line; `systemctl enable greetd.service`. What the packages taught us:
      `greetd.service`'s `[Install]` is **only `Alias=display-manager.service`**,
      which `graphical.target` `Wants=`; the base already defaults to
      `graphical.target`, so no `set-default`; `preset: disabled` confirmed the
      explicit enable was required; the unit restarts 5× in 30 s, then fails.
      Verified on a headless boot: `greetd.service` active; the greeter is **not
      in the service cgroup** — `pam_systemd` (via `/etc/pam.d/greetd-greeter`)
      moves it into a logind session, and `loginctl` shows it: session `c1`, user
      `greetd`, class `greeter`, `seat0`, `tty1`, with `tuigreet --sessions …`
      alive. No AVC denials from greetd or tuigreet.
- [x] **Switch the VM to a graphical display.** `run-vm` was headless on the
      serial console; Sway needs a DRM device and a window. Two lessons from the
      first attempt (2026-09-11): q35 has **no USB bus** until a controller is
      added (`-device qemu-xhci` before `-device usb-tablet`); and
      `-device virtio-vga-gl -display gtk,gl=on` **hung QEMU 8.2.2 on the host**
      (Mint/X11, two AMD GPUs) while it held the X input grab — the desktop looked
      frozen, but a text VT and `pkill qemu-system-x86_64` would have recovered it.
      No kernel, amdgpu or Xorg error was logged; host OpenGL was never required.
      Current invocation: `-device virtio-vga` (2D) and `-display gtk` without GL;
      the guest renders Sway in software (wlroots falls back to pixman). Keep the
      serial console for debugging. virgl is a later optimisation, to be retried
      with `-display sdl,gl=on` or a newer QEMU, with the recovery path known.
      Third lesson, same day: **`output/OVMF_VARS.fd` is the VM's NVRAM.** On the
      first boot of a disk, shim's fallback loader writes a "Fedora" boot entry
      keyed by the ESP's partition GUID; a rebuilt disk has new GUIDs, the entry
      goes stale, and OVMF drops into the UEFI shell (`bcfg boot dump -v` shows
      it; `FS0:\EFI\BOOT\BOOTX64.EFI` boots by hand). A disk and its NVRAM belong
      together: `build-qcow2` resets the VARS file, `run-vm` keeps it between boots
      of the same disk. Also: virtio-vga's EDID follows the GTK window size, so the
      preferred mode was 640×480; pin it with `xres`/`yres` on the device.
      Result: window, getty for a second, tuigreet, login, Sway on `Virtual-1`.
- [x] **Validate the session.** 2026-09-11, over the serial console while Sway was
      on screen — one `systemd --user` per user, shared by every session, and
      `swaymsg -s /run/user/1000/sway-ipc.*.sock …` reaches the compositor from
      outside it:
      - greeter on VT1, login, Sway on screen; the greeter session `c1` is torn
        down and session `2` (`seat0`, `tty1`, class `user`) takes its place
      - `loginctl show-session 2 -p Type` → **`Type=wayland`** (tuigreet took it
        from `sway.desktop`)
      - `systemctl --user show-environment` → **`WAYLAND_DISPLAY=wayland-1`,
        `XDG_CURRENT_DESKTOP=sway`** — `sway-systemd` works; Milestone 2's
        portals and PipeWire have what they need
      - `swaymsg -t get_outputs` → `Virtual-1`, 26 EDID modes; current mode
        640×480 until `xres`/`yres` are pinned (step 4)
      - `DISPLAY=:0 xprop -root` → `_NET_SUPPORTING_WM_CHECK` — **Xwayland starts
        lazily and answers**, which satisfies §19's X11 criterion for free
      - `journalctl -b --grep=AVC` → nothing but the `bootupctl` noise already
        recorded; no denial from greetd, tuigreet or Sway
      - `$mod+Return` opens foot, `$mod+d` opens wmenu — confirmed by eye
- [x] **Record the package set and the erasures.** No erasures were needed; the
      rationale for every named package is in the Containerfile's section comments.

Known pitfalls, so they are not rediscovered:

- **greetd under SELinux enforcing.** Fedora ships a policy module
  (`greetd-selinux`); it must be in the image. The VM enforces, so if login fails,
  read the AVCs (`journalctl -b --grep=AVC`) before touching anything else.
- **`sway-systemd` hooks in through `/etc/sway/config.d/`**, which upstream's config
  includes. A personal config that drops the `include` line silently loses portal
  and PipeWire integration. Worth a note in the README once dotfiles matter.
- Sway version policy is satisfied for free: Fedora 44 ships 1.11, and that is what
  we get. No COPR, no self-built wlroots.

## Milestone 2 — Complete desktop foundation ▶

Loop hygiene first, two Justfile one-liners left over from Milestone 1 — done
2026-09-11, commit `7e18398`:

- [x] `build-qcow2` ends with `cp /usr/share/OVMF/OVMF_VARS_4M.fd output/OVMF_VARS.fd`
      — a new disk gets fresh NVRAM, so no more UEFI shell after a rebuild.
- [x] The `run-vm` comment no longer says "headless": it opens a window, and the
      serial console in the terminal is for debugging.

Sway is a compositor; everything a desktop environment would have bundled is a
separate decision here.

**Step 0 — the SIG's checklist, read 2026-09-11** (`dnf group info swaywm
swaywm-extended`). `swaywm`: mandatory `sway swaybg swayidle swaylock`; default
`dunst foot grim polkit slurp tuned-ppd tuned-switcher waybar xdg-desktop-portal-wlr
xorg-x11-server-Xwayland`. `swaywm-extended`: mandatory `sway-config-fedora`;
default Thunar + gvfs + gvfs-smb + thunar-archive-plugin + xarchiver, blueman,
kanshi, wlr-randr, wl-clipboard, network-manager-applet + six NetworkManager VPN
plugins, pavucontrol, pulseaudio-utils, playerctl, lxqt-policykit,
gnome-keyring-pam, pinentry-gnome3, system-config-printer, sddm +
sddm-wayland-sway, bolt, fprintd-pam, git-core, imv, mpv, wev, wlsunset,
xdg-desktop-portal-gtk. Neither group carries PipeWire, Wi-Fi, BlueZ, CUPS, fonts
or Flatpak — the spin takes those from Fedora's generic groups, so at each
generic component below the matching group (`multimedia`,
`networkmanager-submodules`, `printing`, `fonts`, `hardware-support`) is the
checklist. Rejected from their list: `sway-config-fedora`, SDDM (ADR 0002),
`waybar` (upstream's bar is swaybar). Deferred: `bolt`, `fprintd-pam` (laptop
hardware, M9), `imv`, `mpv` (applications, M5), `git-core` (DX).

Each item is added one at a time, with its own verification, in this order —
audio before portals, because the portal's screencast runs over PipeWire:

- ✅ **Audio** — done 2026-09-11. Verified in the VM: `wpctl status` lists the HDA
  codec as sink and source, `pactl info` reports `PulseAudio (on PipeWire 1.6.8)`
  with `alsa_output.pci-0000_00_04.0.analog-stereo` as default sink, and
  `speaker-test` was audible on the host. Queried first: `pipewire` hard-requires `rtkit` and the
  virtual `pipewire-session-manager` (name `wireplumber` explicitly, as with
  `sway-config`); it recommends only the libcamera plugin. User units:
  `pipewire.socket` (pipewire), `pipewire-pulse.socket` (`pipewire-pulseaudio`),
  `wireplumber.service` (`WantedBy=pipewire.service`); Fedora's
  `90-default-user.preset` enables all three, applied at install by
  `systemctl --global preset` → symlinks under `/etc/systemd/user/`. Set:
  `pipewire pipewire-pulseaudio pipewire-alsa pipewire-utils wireplumber alsa-ucm
  alsa-utils pavucontrol pulseaudio-utils` (check whether pavucontrol pulls GTK 4).
  The `multimedia` group's remainder is GStreamer codecs (codec ADR), AirPlay,
  PackageKit and an Intel VA driver — not taken. VM: `-audiodev pa,id=snd0
  -device ich9-intel-hda -device hda-duplex,audiodev=snd0`. Verify: preset
  symlinks at build time; `wpctl status`, `pactl info`, `speaker-test` in the VM.
- ✅ **Portals** — done 2026-09-11. Verified in the VM: `busctl --user introspect`
  lists FileChooser, ScreenCast, Screenshot and Settings; `ScreenCast.AvailableSourceTypes`
  = 1; all three portal services D-Bus-activated by the first call. Versions:
  xdg-desktop-portal 1.22.1, -wlr 0.8.4, -gtk 1.15.3. `session.sh:39` is an
  unconditional `export XDG_CURRENT_DESKTOP=sway` — confirmed in the source.
  Queried first: `xdg-desktop-portal` hard-requires `geoclue2`
  (Location) and `fuse3` (document portal); `-wlr` hard-requires `grim` and
  recommends `(slurp or wofi or bemenu)` for its screencast picker; `-gtk`
  requires `gsettings-desktop-schemas`. All three are D-Bus-activated user
  services, started by the first client. Backend selection needs a
  `<desktop>-portals.conf`; Fedora ships `wlroots-portals.conf`, but it routes
  Settings to `darkman` (not shipped) and the user manager's
  `XDG_CURRENT_DESKTOP` is `sway` (Sway's own process carries `sway:wlroots` —
  `sway-systemd` rewrites it; confirm with a grep of `session.sh`). Legacy
  `UseIn=gnome` in `gtk.portal` means no config = no file chooser. Decision:
  ship `system_files/usr/share/xdg-desktop-portal/sway-portals.conf` —
  `default=gtk`, Screenshot and ScreenCast to `wlr`, Settings stays with gtk
  (gsettings-driven). Set: `xdg-desktop-portal xdg-desktop-portal-wlr
  xdg-desktop-portal-gtk grim slurp`; `COPY system_files/ /` replaces the
  single-file copy. Verify: `busctl --user introspect` shows Screenshot,
  ScreenCast, FileChooser, Settings; `ScreenCast.AvailableSourceTypes` = 1.
- ✅ **File manager** — done 2026-09-12. Queried: Thunar hard-requires `gvfs` and
  `tumbler`; `gvfs` hard-requires `udisks2` and `polkit` (both in the base); the
  Thunar family recommends nothing; `xarchiver` recommends its back ends
  (`bzip2 xz unzip` are in the base, `zip` and `xdg-utils` were not). gvfs daemons
  are D-Bus-activated user services. Set: `Thunar thunar-volman
  thunar-archive-plugin xarchiver zip xdg-utils gvfs gvfs-mtp gvfs-smb gvfs-fuse`
  (`-gphoto2`, `-archive` optional; `-afc -afp -nfs -goa` out). `run-vm` now
  attaches a 64 MiB FAT image as `usb-storage` on the xHCI bus. Verified: click in
  Thunar mounts it at `/run/media/kevin/BZTEST` (vfat, no prompt — udisks2's
  `allow_active` rule), `gio mount -l` agrees, both gvfs services running, 0 AVCs.
- ✅ **Notifications** — done 2026-09-12: **mako** (wlroots convention; dunst
  was the SIG's pick, equally viable). Queried: mako requires `dbus`, `systemd`;
  recommends `jq`, which `makoctl` needs for `list`/`invoke`/`menu`. D-Bus
  activation (`fr.emersion.mako.service` → `mako.service`) — no `exec` line.
  Set: `mako libnotify jq` (`notify-send` is in libnotify). Verified in the VM:
  mako `inactive` → `notify-send` → bubble on screen → `active`, bus name
  `org.freedesktop.Notifications` owned by mako under `user@1000.service`;
  `makoctl list` renders the notification (via jq), `rc=0`.
- ✅ **Lock and idle** — done 2026-09-13; all three checks passed in the VM. Queried 2026-09-12: `swaylock` and `swayidle` have no
  package dependencies and recommend nothing; swaylock ships `/etc/pam.d/swaylock`;
  upstream's `/etc/sway/config` lines 36–39 carry the commented `swayidle -w
  timeout … before-sleep …` recipe for dotfiles to enable. Set: `swaylock swayidle`.
  Plus `org.freedesktop.impl.portal.Inhibit=none` in `sway-portals.conf`
  (xdg-desktop-portal-gtk issue 465: its Inhibit needs GNOME's session manager;
  `none` lets Wayland apps fall back to Sway's idle-inhibit protocol). Verify:
  `swaylock -f` locks and the password unlocks (PAM); `swayidle -w timeout 5 …`
  locks after five idle seconds; the Inhibit interface is absent from the portal
  frontend. The positive inhibit test needs a video player — Milestone 5.
- ✅ **Output management** — done 2026-09-13: `wlr-randr --mode 1024x768` and a kanshi profile with `1280x1024` both applied in the VM. Queried: `kanshi` and `wlr-randr` have no
  dependencies and recommend nothing; kanshi ships `kanshi.service`
  (`WantedBy=graphical-session.target`, `PartOf=graphical-session.target`), so a
  dotfile enables it as a user unit. Set: `kanshi wlr-randr`. Verified: wlr-randr
  lists the output; kanshi's unit starts, matches a profile and applies it. Found
  on the way — **the VM's display size**: QEMU feeds the GTK window size back to
  the guest as the EDID's preferred mode (kernel: `1920x979` after maximizing),
  but **wlroots does not re-read modes of a connected output**, so Sway keeps the
  mode list from its start, where the preferred mode is 640×480 — GTK's initial
  window size at kernel-probe time. `xres/yres` cannot add a mode to QEMU's fixed
  EDID catalogue (no 1600×900, no 1280×800 in it), so the M1 "pin" never pinned.
  Custom modes are reverted on the resulting hotplug. Use *listed* modes
  (`wlr-randr --output Virtual-1 --mode 1024x768`). To try later, in the Justfile:
  `-display sdl`, whose window is created from the guest's first scanout.
- ✅ **Screenshots and clipboard** — done 2026-09-13. `grim` and `slurp` came with
  the portal step. Queried: `wl-clipboard` recommends `mailcap` (`/etc/mime.types`,
  for typing copied data) and `xdg-utils`; `brightnessctl` requires `systemd >= 243`
  and ships no udev rule — it uses logind's `SetBrightness`, so the active user
  needs no group or rule; `wev` needs nothing. Set: `wl-clipboard mailcap
  brightnessctl wev`. Verified in the VM: `wl-copy`/`wl-paste` round trip, `grim`
  full-screen PNG, `grim -g "$(slurp)"` region capture, `brightnessctl --list`
  reaches devices through logind.
- ✅ **Polkit agent** — done 2026-09-14: unit active after login, agent running, `pkexec true` shows the dialog (`rc=0`; cancel → `rc=127`). **`xfce-polkit`** (GTK 3, requires only
  `polkit`). Fedora packages five agents: `xfce-polkit`, `mate-polkit`, `lxpolkit`
  (GTK), `lxqt-policykit`, `polkit-kde` (Qt). Its autostart entry carries
  `OnlyShowIn=XFCE;`, so the XDG generator would skip it under Sway → the image
  ships `system_files/usr/lib/systemd/user/xfce-polkit.service`
  (`WantedBy=sway-session.target`, `PartOf=graphical-session.target`), enabled
  with `systemctl --global enable`. Verify: unit active after login, `pgrep
  xfce-polkit`, and `pkexec true` from foot shows the password dialog (`rc=0`;
  cancel → `rc=126`).
- ✅ **Networking** — done 2026-09-15: `connected`/`full`, Wi-Fi radio `enabled`
  with `WIFI-HW missing` (VM), supplicant and regdb present, nm-applet running
  from `app-nm-applet@autostart.service`. Also observed: geoclue2's demo agent
  autostarts (the Location portal needs an agent; fine) — check
  `ls /etc/xdg/autostart/` after every package addition. Queried: Base has NetworkManager 1.56 and `-tui`;
  Fedora's `networkmanager-submodules` group adds `-wifi`, `-bluetooth`, `-wwan`,
  `wpa_supplicant`, `dnsmasq`. `NetworkManager-wifi` hard-requires
  `(wpa_supplicant or iwd)` — a rich "either", so the supplicant is named — and
  `wireless-regdb`. `network-manager-applet` hard-requires `nm-connection-editor`
  and `libappindicator-gtk3` (its tray item); its autostart entry is
  `NotShowIn=KDE;GNOME;` → **rule 1**, first customer. Set: `NetworkManager-wifi
  wpa_supplicant network-manager-applet`. Out until needed: `-wwan`, `-bluetooth`
  (revisit at Bluetooth), `dnsmasq`, VPN plugins (WireGuard is native). Verify:
  `nmcli general` connected, Wi-Fi radio enabled, `app-nm-applet@autostart.service`
  active, icon in swaybar's tray.
- **Bluetooth** — BlueZ; `blueman` is the SIG's front-end. Decide at the step.
- **Flatpak** — `flatpak` plus Flathub. `/var/lib/flatpak` is machine-local under
  bootc, so the remote is added by a one-shot unit at first boot, not at build time.
- ✅ **Autostart model** — decided and verified 2026-09-14 (`sway-xdg-autostart.target`
  and `xdg-desktop-autostart.target` active after login), with the polkit agent
  as first customer. Rule 1: XDG autostart entries run through systemd —
  `/etc/sway/config.d/95-xdg-desktop-autostart.conf` symlinked from
  sway-systemd's opt-in drop-in, which waits for a tray (`wait-sni-ready`,
  25 s, then gives up and *skips* autostart) and starts `sway-xdg-autostart.target`
  → `xdg-desktop-autostart.target` → `app-<name>@autostart.service` per entry,
  honouring `OnlyShowIn`/`NotShowIn`. Rule 2: session infrastructure whose entry
  is restricted to another desktop gets an explicit user unit in the image,
  wanted by `sway-session.target`. Later customers: `nm-applet`, `blueman`,
  `xdg-user-dirs` (rule 1, check their entries), gnome-keyring (likely rule 2).
- **Fonts** — Noto Sans is already in (hard requirement); add emoji and a
  monospace; check the `fonts` group.
- **Power** — `tuned-ppd` (the SIG's choice; answers the open question),
  `tuned-switcher` optional; lid and power-key handling stay with logind.
- **Secrets** — `gnome-keyring-pam`, `pinentry-gnome3`; verify how the PAM stack
  picks up `pam_gnome_keyring` under greetd.
- **Printing** — CUPS, `system-config-printer`; check the `printing` group.
- **Ecosystem tools batch** — `wlsunset`, `playerctl`, `wev` and similar small
  tools a personal config may call (§6.1); decide as a set at the end.
- **Console noise** — without `auditd`, the kernel prints every audit record
  (each `sudo`) to the serial console. Fedora desktops boot with `quiet`; for a
  bootc image kernel arguments belong in `/usr/lib/bootc/kargs.d/*.toml`. Small,
  and a good first use of that mechanism.
- **Codecs** — the RPM Fusion question becomes unavoidable here. It needs its own
  ADR, not a quiet package addition.

## Verification approach

Every milestone keeps the same loop, in this order, cheapest first:

```
podman build          →  does it assemble?
bootc container lint  →  is it a sane OS image?
podman run + inspect  →  did the change land where intended?
build-qcow2           →  does it become a disk?
run-vm                →  does it boot?
bootc status          →  is the deployment valid?
swaymsg               →  is the session alive?
```

The rule that makes this work: **add one unknown at a time.** Milestone 0 booted a
near-empty image specifically so that when Sway breaks, the base, the disk-image
path and the VM invocation are already known-good.

Sway's headless backend (`WLR_BACKENDS=headless WLR_LIBINPUT_NO_DEVICES=1 sway`)
lets the session-level checks run without a GPU or a window. That is the seed of
Milestone 7's automated session validation rather than something to build later.

## Open decisions

Tracked with their timing in the deferred-decisions tables of
[ADR 0001](docs/adr/0001-base-image.md) and
[ADR 0002](docs/adr/0002-desktop-sway.md). The ones that will bite soonest:

- **Weak dependencies** — decided 2026-09-11, off image-wide;
  [ADR 0003](docs/adr/0003-no-weak-dependencies.md). Its cost lands on every
  Milestone 2 item: companions are named, not assumed.
- **bootupd AVC denials** (development VM; Milestone 4) — every boot logs three
  denials (`read`, `open`, `getattr`) for `bootupctl` on `/boot/bootupd-state.json`.
  Full record: `scontext=bootupd_t`, `tcontext=unlabeled_t`, **`permissive=1`** —
  the `bootupd_t` domain is permissive in Fedora's policy, so the access succeeded
  and bootupd works. The file is *unlabeled* because it is written by `bootc
  install` inside the disk-image builder on our host, which has no SELinux; a
  build on an SELinux host, or a bare-metal install, would label it. Unrelated to
  the desktop. At Milestone 4 confirm `bootupctl status` works and decide whether
  the VM build path needs a `restorecon`; at Milestone 9 confirm the file is
  labelled on real hardware.
- **Polkit agent and autostart model** (Milestone 2) — the two places where a
  hand-assembled Sway desktop most often ends up subtly broken.
- **RPM Fusion / non-free codecs** (Milestone 2/5) — still an *unverified* claim that
  AMD VA-API H.264/HEVC needs the `-freeworld` swap on Fedora 44. Verify before
  acting; adding a non-Fedora repository warrants its own ADR.
- **Updater choice** (Milestone 4) — stock `bootc-fetch-apply-updates.timer` versus
  `uupd`, decided with rollback behaviour in mind.
- **Fedora 45** ships 2026-10-20. Under the stabilisation policy it reaches stable
  no sooner than 14 days after release and only after validation passes. This is
  the project's first real upgrade rehearsal — and it brings Sway 1.12.

## Working model

Kevin is the implementer. Claude advises, explains constructs before they are
written, reviews, and helps diagnose — it does not generate the repository. Small
steps, working intermediate states, and a verification method for every change.
