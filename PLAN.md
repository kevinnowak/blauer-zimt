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
| **1 — Minimal Sway system** | ▶ Next |
| 2 — Complete desktop foundation | Not started |
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

## Milestone 1 — Minimal Sway system ▶

Goal: a VM that boots to a greetd login and into a usable Sway session. Nothing
else — no applications, gaming or DX tooling until this works.

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
- [ ] **Login: greetd + tuigreet.** The package ships a default
      `/etc/greetd/config.toml` (running `agreety`); replace its `command` with
      `tuigreet --sessions /usr/share/wayland-sessions` so the packaged
      `sway.desktop` is offered, or `tuigreet --cmd sway` to hard-wire it.
      `systemctl enable greetd` — presets will not — and
      `systemctl set-default graphical.target`. Understand the model before
      writing it: greetd owns a VT, runs the greeter as the `greetd` user created
      by `sysusers.d`, and opens the user session through PAM so logind registers
      the seat. Name `greetd-selinux` explicitly. Labels are xattrs applied when the
      image is deployed, so `ls -Z` inside a container built on a host without
      SELinux prints `?` — ask the *policy* instead: `matchpathcon /usr/bin/greetd`
      must return a greetd or xdm domain, not `bin_t`, and
      `grep greetd /etc/selinux/targeted/contexts/files/file_contexts` must match.
- [ ] **Switch the VM to a graphical display.** `run-vm` is headless on the serial
      console; Sway needs a DRM device and a window. Add a virtio GPU with GL
      (`-device virtio-vga-gl -display gtk,gl=on`); keep the serial console for
      debugging. The host may need `qemu-system-gui`.
- [ ] **Validate the session.** In order, cheapest first:
      - greeter appears on VT1; login succeeds
      - `swaymsg -t get_version` and `swaymsg -t get_outputs` answer
      - `$mod+Return` opens foot, `$mod+d` opens wmenu — upstream's bindings, upstream's tools
      - `systemctl --user show-environment | grep WAYLAND_DISPLAY` — proves `sway-systemd` did its job
      - `loginctl show-session $XDG_SESSION_ID -p Type` reports `wayland`
      - `sudo ausearch -m AVC -ts recent` is empty
- [ ] **Record the package set and the erasures** in the Containerfile comments and
      tick this milestone.

Known pitfalls, so they are not rediscovered:

- **greetd under SELinux enforcing.** Fedora ships a policy module
  (`greetd-selinux`); it must be in the image. The VM enforces, so if login fails,
  read the AVCs (`ausearch -m AVC -ts recent`) before touching anything else.
- **`sway-systemd` hooks in through `/etc/sway/config.d/`**, which upstream's config
  includes. A personal config that drops the `include` line silently loses portal
  and PipeWire integration. Worth a note in the README once dotfiles matter.
- Sway version policy is satisfied for free: Fedora 44 ships 1.11, and that is what
  we get. No COPR, no self-built wlroots.

## Milestone 2 — Complete desktop foundation

Sway is a compositor; everything a desktop environment would have bundled is a
separate decision here. Start by reading the SIG's checklist —
`dnf group info swaywm swaywm-extended` — for anything the list below misses.
Each item is then added one at a time, with its own verification, in roughly
this order:

- **Portals** — `xdg-desktop-portal`, `-wlr` (screenshot, screencast) and `-gtk`
  (file chooser, settings). Check whether `-wlr` ships `sway-portals.conf`; portal
  selection depends on `XDG_CURRENT_DESKTOP=sway` reaching the user session.
- **Audio** — PipeWire, WirePlumber, `pipewire-pulseaudio`; `pavucontrol` for a
  mixer, `pulseaudio-utils` for the `pactl` calls in upstream's media-key bindings. VM verification needs `-audiodev` and an HDA device in `run-vm`.
- **Networking** — NetworkManager (+ `-wifi`, `-tui`); decide `nm-applet` versus
  `nmtui` only.
- **Bluetooth** — BlueZ; front-end decision deferred (ADR 0002).
- **File manager** — Thunar with gvfs, tumbler, `thunar-volman`, `udisks2`.
  Removable media is the test: attach a USB-storage drive to the VM and mount it.
- **Polkit agent** — empirical: verify which of `xfce-polkit`, `mate-polkit`,
  `lxqt-policykit` are packaged; pick one.
- **Notifications** — `mako`.
- **Lock and idle** — `swaylock`, `swayidle`; PAM for swaylock comes with the package.
- **Output management** — `kanshi`, `wlr-randr`.
- **Screenshots and clipboard** — `grim`, `slurp`, `wl-clipboard`; `brightnessctl`
  for the upstream media-key bindings.
- **Flatpak** — `flatpak` plus Flathub. `/var/lib/flatpak` is machine-local under
  bootc, so the remote is added by a one-shot unit at first boot, not at build time.
- **Autostart model** — Sway does not read `/etc/xdg/autostart` itself, but
  `sway-systemd` ships an opt-in drop-in, `95-xdg-desktop-autostart.conf`, that
  runs XDG autostart entries through systemd's generator. Evaluate it against
  plain user units under `sway-session.target`, then apply one model
  consistently (`xdg-user-dirs`, applets).
- **Fonts** — Noto or DejaVu plus emoji; without them the bar and wmenu show boxes.
- **Power** — verify whether the F44 base already carries `tuned-ppd` or
  `power-profiles-daemon`; lid and power-key handling stay with logind.
- **Printing** — CUPS, where appropriate.
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
