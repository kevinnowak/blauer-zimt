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
| **1 — Minimal Cinnamon system** | ▶ Next |
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

The layer boundaries (hardware / Cinnamon / common / edition) exist as ordered,
commented sections and separate package lists *inside* that single file. The seams
are real and documented; they are simply not image boundaries yet.

**Later** — split when a second consumer exists. The first genuine forcing function
is Blauer Zimt DX at Milestone 6:

```
fedora-bootc:44
      │
      ▼
blauer-zimt-base      ← hardware + Cinnamon + common
      ├─────────────┐
      ▼             ▼
blauer-zimt    blauer-zimt-dx
```

Splitting earlier buys nothing and costs a multi-image CI graph, cross-image digest
pinning and a slower local loop.

**Release channels** are tags on the same build, not parallel hierarchies:
`:testing` on every green build, `:stable` promoted after validation. Tag
conventions get designed once publishing exists (Milestone 3).

## Milestone 1 — Minimal Cinnamon system ▶

Goal: a VM that boots into a usable Cinnamon session. Nothing else — no
applications, gaming or DX tooling until this works.

- [ ] **Establish the package set empirically.** Query the base image itself
      (`dnf group list`, `dnf group info`, `dnf environment info`) rather than
      trusting tutorials — sources disagree on whether Fedora 44 exposes Cinnamon
      as the `cinnamon-desktop` group or the `cinnamon-desktop-environment`
      environment. Record which, and roughly what it drags in.
- [ ] **Install the group.** Expect `--allowerasing` for default-editor-style
      conflicts. Record *why* each erasure was accepted rather than accepting
      silently.
- [ ] **Display manager: LightDM**, matching the Fedora Cinnamon spin and Linux
      Mint, with `user-session=cinnamon`. Deliberately **not GDM**, which would
      pull GNOME in at the foundation.
- [ ] **Set the graphical target** and confirm the session actually starts.
- [ ] **Switch the VM to a graphical display.** The current `run-vm` recipe is
      headless on the serial console; Cinnamon needs a window and a virtio GPU.

Cinnamon version policy is satisfied for free: whatever Fedora 44 ships is what we
get. No independent packaging of newer upstream Cinnamon.

## Milestone 2 — Complete desktop foundation

Networking, PipeWire audio, Bluetooth, portals, Flatpak, Nemo integration,
removable media, printing, and Mint-X-Aqua defaults via the Fedora-packaged
`mint-themes` and `mint-x-icons`. The codec question (and whether RPM Fusion enters
the image at all) becomes unavoidable here — it needs its own ADR, not a quiet
package addition.

## Verification approach

Every milestone keeps the same loop, in this order, cheapest first:

```
podman build          →  does it assemble?
bootc container lint  →  is it a sane OS image?
podman run + inspect  →  did the change land where intended?
build-qcow2           →  does it become a disk?
run-vm                →  does it boot?
bootc status          →  is the deployment valid?
```

The rule that makes this work: **add one unknown at a time.** Milestone 0 booted a
near-empty image specifically so that when Cinnamon breaks, the base, the disk-image
path and the VM invocation are already known-good.

Automated VM testing (Milestone 7) grows out of this sequence rather than replacing
it.

## Open decisions

Tracked with their timing in the deferred-decisions table of
[ADR 0001](docs/adr/0001-base-image.md). The ones that will bite soonest:

- **RPM Fusion / non-free codecs** (Milestone 2/5) — currently an *unverified*
  claim that AMD VA-API H.264/HEVC needs the `-freeworld` swap on Fedora 44.
  Verify before acting; adding a non-Fedora repository warrants its own ADR.
- **Updater choice** (Milestone 4) — stock `bootc-fetch-apply-updates.timer` versus
  `uupd`, decided with rollback behaviour in mind.
- **Fedora 45** ships 2026-10-20. Under the stabilisation policy it reaches stable
  no sooner than 14 days after release and only after validation passes. This is
  the project's first real upgrade rehearsal.

## Working model

Kevin is the implementer. Claude advises, explains constructs before they are
written, reviews, and helps diagnose — it does not generate the repository. Small
steps, working intermediate states, and a verification method for every change.
