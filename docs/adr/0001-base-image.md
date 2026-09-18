# ADR 0001 — Base image: `quay.io/fedora/fedora-bootc`

- **Status:** Accepted — amended 2026-09-11 by [ADR 0002](0002-desktop-sway.md):
  the target desktop changed from Cinnamon to Sway. The base-image decision and
  its reasoning are unaffected; the Cinnamon references below are the context as
  it stood when the decision was made.
- **Decided:** 2026-09-09
- **Upstream state verified:** 2026-09-09

## Context

Blauer Zimt is a Cinnamon-based Fedora bootc workstation for modern AMD hardware.
Before any code existed, one decision governed everything downstream: which
image-mode base to derive from.

The constraints were set in advance:

- base as directly as practical on official Fedora bootc / Atomic infrastructure
- explicitly **not** "Bluefin with GNOME removed"
- Cinnamon as a first-class desktop, not a late substitution
- AMD-only hardware scope; NVIDIA out of scope
- low long-term maintenance, and maximum educational value

Fedora, bootc and Universal Blue all moved during 2026, so the options were
checked against primary sources rather than recalled.

### Upstream state at the time of the decision

| Fact | Value |
|---|---|
| Current Fedora | 44, released 2026-04-28 |
| Next Fedora | 45, scheduled 2026-10-20 |
| Official bootc base | `quay.io/fedora/fedora-bootc`, tags 42–46 + rawhide, rebuilt daily |
| Base image tiers | `minimal` → `minimal-plus` → `standard`; `standard` is what `fedora-bootc` publishes |
| Fedora Image Mode Phase 2 | development pipeline by F44, production pipeline by F45 |

Three findings decided the matter:

1. **There is no Cinnamon Atomic Desktop.** Fedora 44 ships Silverblue, Kinoite,
   Sway Atomic, Budgie Atomic and COSMIC Atomic. No official Fedora Cinnamon
   image-mode image exists to derive from.
2. **Bluefin is Silverblue all the way down.** Its Containerfile reads
   `FROM ghcr.io/ublue-os/silverblue-main`. Everything Cinnamon-related would be
   subtraction.
3. **The `fedora-ostree-desktops` images are still self-described "Experimental
   ostree container images"** and are not yet bootc-native. Fedora's own Image Mode
   initiative plans to replace them.

## Decision

**Build from `quay.io/fedora/fedora-bootc:44`, pinned by digest.**

```
FROM quay.io/fedora/fedora-bootc:44@sha256:1bc549cb2909ebd1bb69e05088797dd602eee691f7deaa40f5b9914c3ce84b36
```

The pinned digest is the **OCI image index**, not a single-architecture manifest,
so the pin stays architecture-portable. The floating `:44` tag moves daily and will
be tracked by Renovate once CI exists.

Start on **44** rather than 45. Being on a proven stable base while Fedora 45 ships
on 2026-10-20 turns the project's first major-version bump into a controlled
rehearsal of the upgrade policy instead of a moving target.

## Alternatives considered

### `ghcr.io/ublue-os/base-main` — Universal Blue's DE-less base

Fedora Atomic base plus RPM Fusion, non-free codecs and automatic updates. The
fastest route to a working desktop, and what the `Danathar/cinnamon-ublue`
reference project used.

Rejected: it places a third party *below* our lowest layer. Universal Blue trimmed
its intermediate images in September/October 2025 (the `sway`, `budgie` and
`cosmic` variants were removed outright) and is mid-restructure with completion
expected October 2026 — the same month Fedora 45 lands. It is also transitively
rooted in the experimental ostree images. Finally, it is faster precisely because
someone else already made the decisions this project exists to understand.

### `quay.io/fedora-ostree-desktops/base-atomic` — Fedora's DE-less Atomic base

Official Fedora, desktop-shaped defaults already present.

Rejected: self-described experimental, ostree-native rather than bootc-native, and
scheduled for replacement under Image Mode Phase 2. Adopting it means adopting a
migration we can simply skip.

### Derive from Bluefin

Rejected by project scope and confirmed by its Containerfile. See above.

## Consequences

### Accepted benefits

- Most upstream option available; no third-party trust or availability risk.
- No GNOME lineage, so Cinnamon is first-class structurally rather than by policy.
- Small, comprehensible surface: every package present is either from the base tier
  or something deliberately added.
- Simple Fedora major-version upgrades — bump one tag and one digest.
- Upgrade risk is Fedora's release cadence alone, not Fedora's *plus* a third
  party's rebase timing.

### Accepted costs

- We assemble the desktop ourselves: display manager, session, portals, PipeWire,
  Flatpak wiring and codecs are all our work.
- No RPM Fusion, no non-free codecs and no updater are preconfigured.
- More Milestone 1–2 effort than starting from a desktop image would require.

## Implementation notes

Discovered while bringing up the first image; recorded so they need not be
rediscovered.

- **`--rootfs` is mandatory for this base.** `/usr/lib/bootc/install/` is empty and
  `bootc install print-configuration` returns `"root-fs-type": null`. Fedora leaves
  disk layout to the deployer, and the builder refuses to guess. We pass `xfs`,
  which affects the development VM only — bare-metal installs choose at install
  time. `btrfs` has a known open issue with this builder and `fedora-bootc`.
- **Do not change `ID` or `VERSION_ID` in `os-release`.** `dnf`'s `$releasever`,
  RPM macros and third-party repository definitions all resolve through them. Only
  presentation fields (`NAME`, `PRETTY_NAME`, `VARIANT`, `VARIANT_ID`) are altered.
- **The disk-image builder is frozen.** `quay.io/centos-bootc/bootc-image-builder`
  was archived 2026-06-18 and last built that day. That version has **no `--pull`
  and no `--local` flag** — it reads the mounted container store unconditionally —
  and no `--config` flag, so `config.toml` must be mounted at exactly
  `/config.toml`. Its `WorkingDir` is `/output`.
- **The builder's CentOS lineage does not affect the output.** It supplies
  partitioning, filesystem and loop-device scaffolding; everything OS-specific is
  performed by `bootc install to-filesystem` run from inside the target Fedora
  image.
- **Podman must be rootful**, because the builder mounts `/var/lib/containers/storage`
  and podman records the store's absolute path inside the store itself.
- **Building on a host without SELinux works.** The builder warns it is "less well
  tested"; the resulting guest boots with SELinux fully active and enforcing.
- `bootc container lint` reports 13 checks passed, 1 skipped for this image.

## Deferred decisions

| Decision | When | Note |
|---|---|---|
| RPM Fusion / non-free codecs | Resolved 2026-09-18 | Verified: Fedora's Mesa omits H.264/HEVC/VC-1. Decided in [ADR 0004](0004-multimedia-negativo17.md): negativo17's `fedora-multimedia` (Bluefin's route), not RPM Fusion. |
| Updater: `bootc-fetch-apply-updates.timer` vs `uupd` | Milestone 4 | `uupd` also covers Flatpak/Distrobox/Homebrew; the stock timer rolls forward again after a manual rollback. |
| Migrate to `ghcr.io/osbuild/image-builder` | Milestone 3, or on breakage | Actively maintained, Fedora 44-based, same volume contract. Its bootc path (`--bootc-ref`) is not yet documented, and its README still redirects bootc users to `bootc-image-builder`. |
| Image signing (cosign / sigstore) | Milestone 3 | |
| Root filesystem for bare metal | Milestone 8/9 | `xfs` here is a development-VM choice only; `btrfs` remains open and would need testing. |
| Default hostname | Milestone 2 | Currently inherits `fedora` from the base. Machine-local state, so arguably a deployment concern. |
| Secure Boot / "sealed" images | Future | UKI + composefs + fs-verity test images exist but are unofficial and not signed with Fedora keys. |

## References

- [Fedora bootc base images](https://gitlab.com/fedora/bootc/base-images)
- [Fedora Image Mode Phase 2 initiative](https://fedoraproject.org/wiki/Initiatives/Fedora_bootc)
- [What's new for Fedora Atomic Desktops in Fedora 44](https://fedoramagazine.org/whats-new-fedora-atomic-desktops-in-fedora-linux-44/)
- [Building your own Atomic (bootc) Desktop](https://fedoramagazine.org/building-your-own-atomic-bootc-desktop/)
- [bootc build guidance](https://bootc.dev/bootc/building/guidance.html)
- [bootc-image-builder deprecation notice](https://osbuild.org/docs/bootc/deprecation-notice/)
- [ublue-os/main](https://github.com/ublue-os/main) · [ublue-os/bluefin](https://github.com/ublue-os/bluefin)
