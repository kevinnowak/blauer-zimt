# ADR 0003 — Weak dependencies are not installed

- **Status:** Accepted
- **Decided:** 2026-09-11

## Context

RPM packages declare dependencies at two strengths. `Requires` is hard: the
package cannot function without it, and dnf always installs it. `Recommends` (and
its inverse, `Supplements`) is weak: the package works without it but is "nicer"
with it. dnf follows weak dependencies when `install_weak_deps` is true, which is
Fedora's default and what the `fedora-bootc` base ships (verified with
`dnf --dump-main-config`).

The first desktop install of Milestone 1 named eight packages:

```
mesa-dri-drivers sway sway-config-upstream sway-systemd foot wmenu greetd tuigreet
```

The image grew from 542 to 814 packages. About half of the 272 arrivals are hard
transitive requirements — Mesa and LLVM, wlroots, Wayland and X11 libraries,
fontconfig, Python for `sway-systemd`. The other half arrived through weak
dependencies, chaining several levels deep. Among them:

- the entire PipeWire stack with WirePlumber, PulseAudio and JACK compatibility,
  Bluetooth and libcamera plugins, and `rtkit` — before Milestone 2 asked for audio;
- `xdg-desktop-portal` and `xdg-desktop-portal-gtk` (but not `-wlr`), and through
  them GTK 3, Adwaita icons and cursors, dconf, at-spi, `geoclue2`, `upower`;
- `localsearch`, a file-indexing daemon with systemd user units that would run
  in every session, plus its extractor chain: poppler, exiv2, libgsf, gstreamer,
  libavcodec, libheif — and via libavcodec, `intel-mediasdk` on an AMD-only image;
- `mesa-vulkan-drivers` and `vulkan-loader`, overriding a decision to defer Vulkan
  until it can be verified on real hardware;
- `emacs-filesystem`, via `desktop-file-utils`.

ADR 0001 lists as an accepted benefit of the chosen base: *every package present
is either from the base tier or something deliberately added.* With weak
dependencies on, that is not true of anything built on top of it, and the set
changes silently whenever a Fedora packager edits a `Recommends` line.

## Decision

**`install_weak_deps=False`, image-wide, from the first layer that installs
anything.**

Set as a dnf5 drop-in so that it applies to every `dnf` invocation in every
layer, including future DX layers, without being repeated on each command line:

```
# /etc/dnf/libdnf5.conf.d/blauer-zimt.conf
[main]
install_weak_deps=False
```

dnf5 reads `/usr/share/dnf5/libdnf.conf.d/*.conf`, then `/etc/dnf/libdnf5.conf.d/*.conf`,
then `/etc/dnf/dnf.conf`, last one wins. The base sets the option nowhere, so the
drop-in decides.

Consequently, **every companion package is named in the Containerfile.** A package
that a feature needs is a dependency of *Blauer Zimt*, whether or not Fedora's
packager marked it hard or weak. The base image's own contents are unaffected;
they were resolved when Fedora built it.

## Alternatives considered

### Keep Fedora's default

The image behaves like a normal Fedora installation; companions arrive
automatically and things tend to "just work". Rejected: roughly 130 packages
present that nobody decided on, unrequested daemons, silent drift, and a direct
contradiction of ADR 0001's stated benefit. It also defeats the learning purpose —
Milestone 2 would find PipeWire already installed and never learn what needs it.

### `--setopt=install_weak_deps=False` on each `dnf` command

Same effect, no file. Rejected: it must be repeated on every install line in
every layer, one omission silently reverts the policy, and the policy is not
discoverable by inspecting the image.

## Consequences

### Accepted benefits

- Every package in the image is either in the base or named in the Containerfile.
- Rebuilds are reproducible in composition, not only in digest.
- Smaller image, no surprise services, no foreign-vendor codec libraries.
- Each missing companion is discovered when its feature is exercised, understood,
  and named — the loop the project is built around.

### Accepted costs

- Companions must be found by hand. Known candidates from the Milestone 1 diff,
  to be named when their feature is needed:
  `greetd-selinux` (named at once), `xdg-desktop-portal` and `-gtk`, `pipewire`,
  `pipewire-pulseaudio`, `pipewire-alsa`, `wireplumber`, `mesa-vulkan-drivers`,
  `swaylock`, `swayidle`, `grim`, `upower`, `rtkit`, `dbus-tools`, `xdg-utils`.
  (`adwaita-cursor-theme`, `default-fonts-core-sans` and `vulkan-loader` turned out
  to be hard requirements and need no naming.)
- Conditional weak dependencies stop applying too: `sway-config-upstream`'s
  `(qt6-qtwayland if qt6-qtbase-gui)` will not fire, so any future Qt application
  needs `qt6-qtwayland` named alongside it.
- Some breakage is subtle rather than loud — a missing file-chooser portal shows
  as a dialog that never opens. The candidate list above is the first place to look.

## Verification

Inside the rebuilt image:

```
dnf --dump-main-config | grep install_weak_deps    # → install_weak_deps = 0
rpm -qa | wc -l                                      # well below 814
```

and, on every later package change, an `rpm -qa` diff against the previous build
so that nothing arrives unnoticed.

Measured on 2026-09-11, same package line plus `greetd-selinux`: 814 → 680
packages; 134 kept out; 138 hard arrivals for 9 named packages.

## References

- [dnf5.conf(5)](https://dnf5.readthedocs.io/en/latest/dnf5.conf.5.html) — drop-in directories, `install_weak_deps`
- [ADR 0001 — Base image](0001-base-image.md), "Accepted benefits"
- [ADR 0002 — Desktop: Sway](0002-desktop-sway.md), deferred decisions
