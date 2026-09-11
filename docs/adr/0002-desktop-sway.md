# ADR 0002 — Desktop: Sway with upstream configuration

- **Status:** Accepted
- **Decided:** 2026-09-11
- **Upstream state verified:** 2026-09-11
- **Amends:** [ADR 0001](0001-base-image.md) — context only; its decision stands

## Context

Blauer Zimt was specified as a Cinnamon workstation with Mint-X-Aqua styling, and
ADR 0001 chose its base image on that assumption. Before any desktop package was
installed, the target desktop changed: Blauer Zimt is now a **Sway** workstation.

Two things motivated the change. Sway is the desktop Kevin wants to live in. And
Fedora's own Sway offering — the Sway Spin and Sway Atomic — ships the Fedora Sway
SIG's configuration (bar, terminal, launcher, lock screen, display manager) rather
than upstream Sway's, and that configuration is specifically *not* wanted. The
requirement is therefore not "Sway" but "stock upstream Sway on a Fedora bootc base".

Everything else in the project charter is unchanged: official Fedora, bootc-native,
AMD-only hardware scope, no fork of a larger image, minimal branding, maximum
educational value.

### Upstream state at the time of the decision

Checked on packages.fedoraproject.org.

| Fact | Value |
|---|---|
| Sway in Fedora 44 | `sway` 1.11-3.fc44 (rawhide: 1.12-2.fc45) |
| `sway` source package produces | `sway`, `sway-config-upstream`, `sway-config-minimal`, `sway-wallpapers` |
| `sway-config-upstream` | "Upstream configuration for Sway. Includes all important dependencies for a typical desktop system with minimal or no divergence from the upstream." |
| `sway-config-fedora` | **Separate** source package, 0.4.3-3.fc44 — "Fedora Sway Spin configuration for Sway"; upstream `gitlab.com/fedora/sigs/sway/sway-config-fedora`; related `sddm-wayland-sway`, `initial-setup-gui-wayland-sway` |
| `sway-systemd` | 0.4.1-4.fc44 — environment propagation into the systemd user session, `sway-session.target`, application scopes; upstream `github.com/alebastr/sway-systemd` |
| greetd family | `greetd` (with a `greetd-selinux` policy subpackage), `tuigreet`, `gtkgreet` packaged; `regreet` and `wlgreet` are **not** |
| Spin identity | `fedora-release-sway` exists and must not be installed |
| Fedora Sway Atomic | `quay.io/fedora-ostree-desktops/sway-atomic` — same experimental ostree lineage ADR 0001 rejected |

Two findings decided the matter:

1. **"Stock Sway" is a Fedora package.** The `sway` package requires a virtual
   `sway-config`, and Fedora provides three implementations: `-upstream`, `-minimal`
   and `-fedora`. Choosing `sway-config-upstream` gives upstream's `/etc/sway/config`
   with no compiling and no third-party repository. §4.1 and §7 apply verbatim.
2. **Fedora Sway Atomic is the wrong starting point twice over.** It is built from
   the experimental `fedora-ostree-desktops` lineage, and it bakes in exactly the
   `sway-config-fedora` + SDDM setup this decision exists to avoid. Deriving from it
   would mean subtracting — the "Bluefin minus GNOME" pattern with different nouns.

## Decision

- **Sway from Fedora packages, with `sway-config-upstream` named explicitly.** The
   resolver picks *some* provider of `sway-config` when only `sway` is requested; it
   must never be left to choose.
- **Wayland only.** No Xorg server in the image. `xorg-x11-server-Xwayland` is
   installed for compatibility — Steam, Proton and most games run through it — but
   must not shape the session architecture.
- **Login through `greetd` with the `tuigreet` greeter.** A Wayland-native login
   daemon that owns a VT, runs the greeter as its own unprivileged user, and hands
   the session to logind through PAM. No Qt, no GTK, nothing to theme.
- **`sway-systemd` for the systemd user session.** It propagates `WAYLAND_DISPLAY`,
   `XDG_CURRENT_DESKTOP` and friends into `systemctl --user`, which is what lets
   portals, PipeWire and any user service find the compositor. It hooks in through
   `/etc/sway/config.d/`, which upstream's config includes by default.
- **Tools in the image, configuration in dotfiles.** A bootc image is immutable and
   layering is discouraged, so every tool a personal Sway config may reference lives
   in the image. The image's own `/etc/sway/config` stays upstream's. Personal
   configuration is out of scope (§28).
- **Stock appearance.** No GTK, icon or cursor theme defaults; no wallpaper beyond
   `sway-wallpapers`, which upstream's config references. Mint-X-Aqua is dropped
   with Cinnamon.
- **Thunar as the file manager**, with gvfs for removable media and trash.
- **The base image is unchanged.** See the re-validation below.

## Alternatives considered

### Keep Cinnamon

The original plan. Rejected by preference, not by defect: nothing found during
Milestone 0 argued against Cinnamon. The switch is cheap now precisely because ADR
0001 kept the desktop out of the base — it costs a Containerfile section and this
document, not a re-architecture.

### Derive from Fedora Sway Atomic

Official Fedora, Sway already present, kickstart and comps group already curated.

Rejected: experimental ostree-native lineage scheduled for replacement (ADR 0001's
second finding applies unchanged); ships `sway-config-fedora`, SDDM and
`fedora-release-sway`, all of which would have to be removed; and removing them
still leaves the SIG's package choices as the implicit design. Its kickstart and
the comps `sway-desktop` group remain useful as a *checklist* of what a complete
Fedora Sway desktop contains.

### `sway-config-fedora` on our own base

The Spin's configuration on top of `fedora-bootc`.

Rejected: it is the configuration this decision exists to avoid, and it pulls the
`sddm-wayland-sway` chain with it. The same applies to the `sway-desktop` package
group, which depends on it.

### Session start: SDDM, gtkgreet, or no display manager

- **SDDM** (`sddm-wayland-sway`) — the Spin's choice. Rejected: a Qt display manager
  in an otherwise Qt-free base, for a single login prompt.
- **greetd + gtkgreet** — graphical, but the greeter needs its own compositor
  (`cage`) to draw in. Rejected for now as one more moving part; trivially
  revisitable since the daemon is the same.
- **No display manager** — upstream's own recommendation: log in on a TTY and
  `exec sway` from the shell profile. Rejected: session start would then depend on
  per-user shell configuration, which the image does not own, so "boots into Sway"
  could not be an image property or a CI assertion.

### Other wlroots compositors (Hyprland, river, …)

Not evaluated. The decision is Sway specifically; the project is not a compositor
comparison. §33 applies.

## Consequences

### Accepted benefits

- Wayland-native from the first layer: no X11 session, no xsettings daemon, no
  compositor-under-a-compositor.
- No GNOME session lineage at all; the remaining GTK dependencies are libraries.
- Sway's headless backend (`WLR_BACKENDS=headless`) makes session-level validation
  practical in CI without a GPU — Milestone 7 gets easier than it would have been.
- The tools/config split fits bootc's immutability instead of fighting it.
- Small, legible surface: every desktop component is a deliberate choice recorded
  in §6.

### Accepted costs

- **DE → WM.** Cinnamon bundled roughly fifteen integrated decisions. They are now
  ours, individually: login, session wiring, bar, launcher, terminal, notifications,
  lock, idle, power, output management, screenshots, clipboard, polkit agent, file
  manager, removable media, autostart. Milestone 2 grows accordingly.
- **X11 → Wayland.** Steam and Proton run under Xwayland (well-trodden on AMD, but a
  second display server to keep working). Screen sharing needs PipeWire plus
  `xdg-desktop-portal-wlr`. GTK theming happens through gsettings and the settings
  portal, Qt through `qtwayland`. HDR support in Sway 1.11 is **unverified** and must
  not be promised; VRR (`output * adaptive_sync on`) is established.
- **No `/etc/xdg/autostart` processing.** Fedora packages that rely on it
  (`nm-applet`, `blueman-applet`, `xdg-user-dirs`) need systemd user units bound to
  `graphical-session.target`, or explicit `exec` lines.
- **Flatpak remotes live in `/var`.** `/var/lib/flatpak` is machine-local under bootc
  and not part of the image contract; Flathub is added by a one-shot unit at first
  boot, not at build time.
- **greetd under SELinux enforcing.** Fedora ships a policy module, `greetd-selinux`,
  which must be in the image. The development VM enforces, so `ausearch -m AVC` is
  still the first thing to check when login fails.
- §8's premise — a recognisable, Mint-like desktop — is gone. The default look is
  whatever upstream Sway looks like.

## Re-validation of ADR 0001

ADR 0001 chose `fedora-bootc:44` on three axes: official Fedora over a third party
below the lowest layer; bootc-native over the experimental ostree images; adding
what is needed over deriving from something larger and subtracting. None of the
three depends on which desktop sits on top, and for Sway the third points harder,
because the nearest official Sway image bakes in the configuration we least want.
The decision, the digest pin and every implementation note in ADR 0001 stand.

## Deferred decisions

| Decision | When | Note |
|---|---|---|
| What `sway-config-upstream` actually pulls in | ~~Milestone 1~~ Resolved 2026-09-11 | Requires `sway`, `swaybg`, `sway-wallpapers`, `mesa-dri-drivers`, Xwayland, `polkit`; merely *recommends* `foot`, `wmenu`, `sway-systemd`, `swaylock`, `swayidle`, `grim`. No font. Details in PLAN.md, Milestone 1. |
| Polkit authentication agent | Milestone 2 | Candidates `xfce-polkit`, `mate-polkit`, `lxqt-policykit`; verify which are packaged. Mounting removable media in an active local session needs none. |
| Notification daemon | Milestone 2 | `mako` is the wlroots-ecosystem default; `SwayNotificationCenter` is the GTK alternative. |
| Bluetooth front-end | Milestone 2 | `bluetoothctl` only, or `blueman`. |
| Power daemon | Milestone 2 | Verify whether the F44 base uses `tuned-ppd` or `power-profiles-daemon`; Fedora Workstation moved to `tuned-ppd` in F41. |
| Autostart model | Milestone 2 | systemd user units under `sway-session.target` versus `exec` lines in `/etc/sway/config.d/`. `sway-systemd` ships an opt-in `95-xdg-desktop-autostart.conf` for XDG autostart through systemd. |
| Bar and status | Milestone 2 / 5 | Stock `swaybar` first. `waybar` only if a tray or richer status is wanted. |
| Secret service / keyring | Milestone 2 / 5 | `gnome-keyring` if a Flatpak browser or similar needs it. |
| `steam-devices` udev rules | Milestone 5 | Flatpak Steam needs host-side rules for controllers. |
| HDR / VRR expectations | Milestone 5 / 9 | VRR is settled; HDR in Sway 1.11 is not. Validate on the AMD target. |
| Weak dependencies (`install_weak_deps`) | Resolved 2026-09-11 | Off, image-wide — [ADR 0003](0003-no-weak-dependencies.md). The first install had brought 272 packages for 8 named. |
| Graphical greeter | Open | `gtkgreet` + `cage` if a TUI login proves unwelcome; same daemon, different greeter. |

## References

- [Sway](https://swaywm.org/) · [Sway wiki](https://github.com/swaywm/sway/wiki) · [wlroots](https://gitlab.freedesktop.org/wlroots/wlroots)
- [greetd](https://sr.ht/~kennylevinsen/greetd/) · [sway-systemd](https://github.com/alebastr/sway-systemd) · [xdg-desktop-portal-wlr](https://github.com/emersion/xdg-desktop-portal-wlr)
- [Fedora Sway SIG](https://gitlab.com/fedora/sigs/sway) · [Fedora Sway Spin](https://fedoraproject.org/spins/sway/) · [Fedora Sway Atomic](https://fedoraproject.org/atomic-desktops/sway/)
- Fedora packages: [sway](https://packages.fedoraproject.org/pkgs/sway/sway/) · [sway-config-upstream](https://packages.fedoraproject.org/pkgs/sway/sway-config-upstream/) · [sway-config-fedora](https://packages.fedoraproject.org/pkgs/sway-config-fedora/sway-config-fedora/) · [sway-systemd](https://packages.fedoraproject.org/pkgs/sway-systemd/sway-systemd/)
- [ADR 0001 — Base image](0001-base-image.md)
