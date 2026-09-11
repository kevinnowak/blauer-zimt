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

- [ ] **Establish the package set empirically.** Query the base image, not
      tutorials, with `sudo podman run --rm quay.io/fedora/fedora-bootc:44 dnf …`:
      - `repoquery --whatprovides sway-config` — expect `-upstream`, `-minimal`, `-fedora`
      - `repoquery --requires sway-config-upstream` — what "typical desktop" means concretely
      - `repoquery --requires sway` — whether Xwayland, `sway-systemd` or a font come along
      - `group info sway-desktop` — **reference only**; the group pulls `sway-config-fedora` and SDDM
      - `rpm -q mesa-dri-drivers mesa-vulkan-drivers xorg-x11-server-Xwayland` — what the base lacks
      Record the answers here; they decide the next step.
- [ ] **Install Sway.** `sway sway-config-upstream sway-systemd` — the config
      provider **named explicitly**, or the resolver may choose `-fedora`. Add
      Xwayland, Mesa (DRI + Vulkan) and one font family if the queries show them
      missing. Never `fedora-release-sway`, `sway-config-fedora`, `sddm-wayland-sway`
      or the `sway-desktop` group. Record *why* each `--allowerasing` erasure, if any,
      was accepted.
- [ ] **Login: greetd + tuigreet.** `/etc/greetd/config.toml` with
      `command = "tuigreet --cmd sway"` (or `--sessions /usr/share/wayland-sessions`
      to pick up the packaged session file), `systemctl enable greetd` — presets will
      not — and `systemctl set-default graphical.target`. Understand the model
      before writing it: greetd owns a VT, runs the greeter as the `greetd` user, and
      opens the user session through PAM so logind registers the seat.
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

- **greetd under SELinux enforcing** is a reported source of denials. The VM
  enforces. If login fails, read the AVCs before touching anything else.
- **`sway-systemd` hooks in through `/etc/sway/config.d/`**, which upstream's config
  includes. A personal config that drops the `include` line silently loses portal
  and PipeWire integration. Worth a note in the README once dotfiles matter.
- Sway version policy is satisfied for free: Fedora 44 ships 1.11, and that is what
  we get. No COPR, no self-built wlroots.

## Milestone 2 — Complete desktop foundation

Sway is a compositor; everything a desktop environment would have bundled is a
separate decision here. Each item below is added one at a time, with its own
verification, in roughly this order:

- **Portals** — `xdg-desktop-portal`, `-wlr` (screenshot, screencast) and `-gtk`
  (file chooser, settings). Check whether `-wlr` ships `sway-portals.conf`; portal
  selection depends on `XDG_CURRENT_DESKTOP=sway` reaching the user session.
- **Audio** — PipeWire, WirePlumber, `pipewire-pulseaudio`; `pavucontrol` for a
  mixer. VM verification needs `-audiodev` and an HDA device in `run-vm`.
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
- **Autostart model** — Sway does not read `/etc/xdg/autostart`. Decide between
  systemd user units under `sway-session.target` and `exec` lines in
  `/etc/sway/config.d/`, then apply it consistently (`xdg-user-dirs`, applets).
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

- **What `sway-config-upstream` pulls in** (Milestone 1) — decides how much of the
  desktop is already implied by the config package. Query, don't assume.
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
