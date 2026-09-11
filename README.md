# Blauer Zimt

A Sway-based Fedora [bootc](https://bootc.dev/) workstation image, targeting
modern AMD desktop hardware.

Blauer Zimt adopts the architecture, maintenance philosophy and automation patterns
of [Project Bluefin](https://projectbluefin.io/) without deriving from it. The base
is Fedora's own bootc image, and Sway is a first-class desktop from the first layer
rather than a replacement for GNOME. The Sway configuration is upstream's, not the
Fedora Sway Spin's.

## Status

**Milestone 0 — Architecture and repository foundation.** Complete.

The image builds, passes `bootc container lint`, produces a QCOW2 disk image, and
boots in QEMU/KVM to a valid `bootc status`. It deliberately contains no desktop,
no Flatpaks, no CI and no signing yet.

Next: **Milestone 1** — a VM that boots into a usable Sway session.

## Architecture

```
quay.io/fedora/fedora-bootc:44      official Fedora bootc base, digest-pinned
              │
              ▼
     localhost/blauer-zimt:44
```

See [ADR 0001](docs/adr/0001-base-image.md) for why this base was chosen, which
alternatives were rejected, and what that costs us. [ADR 0002](docs/adr/0002-desktop-sway.md)
records the desktop decision — Sway with upstream configuration — and what changes
above the base as a result.

The layer boundaries (hardware / Sway / common / edition) currently live as
commented sections inside a single `Containerfile`. They become separate images
only when Blauer Zimt DX gives them a second consumer (Milestone 6).

## Requirements

Any Linux host with:

| Tool | Why |
|---|---|
| `podman` | builds the OCI image and runs the disk-image builder |
| `qemu-system-x86` + `ovmf` | boots the result; OVMF supplies UEFI firmware |
| `just` | task runner for the recipes below |
| `skopeo` | optional — resolves base image digests without pulling |

On a Debian/Ubuntu-family host:

```bash
sudo apt install podman just skopeo qemu-system-x86 ovmf
```

**Podman must be used rootful.** `bootc-image-builder` bind-mounts
`/var/lib/containers/storage`, which is the *rootful* store; a rootless build
lands in `~/.local/share/containers/storage` where the builder cannot see it.
Podman records the absolute store path inside the store itself, so the rootless
one cannot simply be remounted elsewhere. Every recipe here uses `sudo podman`
for that reason.

## Quick start

Create your local deployment config — this defines the login account injected
into the disk image, and is **not** committed:

```bash
cp config.toml.example config.toml
```

Edit it to set a throwaway password and your SSH public key. Then:

```bash
just build
```

```bash
just build-qcow2
```

```bash
just run-vm
```

The VM boots headless on the serial console. `Ctrl-A` then `X` quits;
`Ctrl-A` then `C` reaches the QEMU monitor. SSH is forwarded to host port 2222:

```bash
ssh -p 2222 <user>@localhost
```

Verify the running system with `sudo bootc status`. It should report
`localhost/blauer-zimt:44` and the digest of the image you just built.

## Repository layout

```
Containerfile              the image definition
Justfile                   local build / disk-image / VM recipes
config.toml.example        template for the local deployment config
docs/adr/                  architecture decision records
```

## Notes worth knowing

**Credentials belong to the deployment, not the image.** A bootc image contains
no user accounts by design — the same bytes deploy everywhere. Identity is
injected per deployment: `config.toml` for disk images, Anaconda for bare metal,
cloud-init in a cloud. `config.toml` stores the password *unencrypted*, so it is
gitignored and should only ever hold a throwaway.

**`--rootfs` is mandatory for this base.** `fedora-bootc` declares no default root
filesystem (`bootc install print-configuration` returns `root-fs-type: null`), so
the builder refuses to guess. The recipes pass `xfs`. This governs only the
development VM — bare-metal installs choose their own filesystem at install time.

**The disk-image builder is frozen.** `quay.io/centos-bootc/bootc-image-builder`
was archived on 2026-06-18 and superseded by `ghcr.io/osbuild/image-builder`. The
container still works and remains the documented path; migration is tracked in
ADR 0001. Its CentOS lineage does not affect the output — it supplies partitioning
and filesystem scaffolding, while everything OS-specific is done by
`bootc install to-filesystem` running from inside the Fedora image itself.

**Building on a host without SELinux works.** The builder warns that this is "less
well tested", but the resulting guest boots with SELinux fully active.
