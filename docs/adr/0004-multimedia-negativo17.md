# ADR 0004 — Multimedia stack from negativo17: hardware video codecs

- **Status:** Accepted
- **Decided:** 2026-09-17; implemented and verified 2026-09-18
- **Upstream state verified:** 2026-09-17 / 18
- **Amends:** [ADR 0001](0001-base-image.md) (resolves its "RPM Fusion / non-free
  codecs" deferred decision); one deliberate exception to CLAUDE.md §3.6

## Context

§3.3 names VA-API and hardware video acceleration among the AMD target's
priorities. ADR 0001 deferred the question with an *unverified* note that
Fedora's Mesa lacks H.264/HEVC. Verified state, September 2026:

| Fact | Source |
|---|---|
| Fedora's Mesa omits H.264, H.265/HEVC and VC-1 from VA-API and Vulkan video "since Fedora 37", chiefly affecting AMD | RPM Fusion Multimedia howto |
| In Fedora 44 the separate `mesa-va-drivers` package is gone; the (codec-stripped) VA driver lives inside `mesa-dri-drivers` | `dnf repoquery --file /usr/lib64/dri/radeonsi_drv_video.so` |
| Fedora's `ffmpeg-free` decodes `av1`, `vp9`, `mpeg2video`, `mpeg4`, `h263` — not `h264`, not `hevc` | `ffmpeg -decoders` in the image |
| Flatpak's GL runtime is built with `video_codecs: all_free` | freedesktop-sdk `elements/extensions/mesa/mesa.bst` / `mesa.yml` |
| RPM Fusion 44 ships `mesa-va-drivers-freeworld` and `mesa-vulkan-drivers-freeworld` (26.2.2); the VA package requires `mesa-filesystem = <exact Fedora version>` | RPM Fusion repodata |
| Bluefin (via `ublue-os/main` `install.sh`) enables negativo17's `fedora-multimedia`, `distro-sync`s the whole Mesa stack plus `libva`, `libheif` and Intel media packages from it, and `versionlock`s them; `packages.json` adds full `ffmpeg` and `fdk-aac` | ublue-os/main |

Who decodes what on an AMD machine running a Fedora base:

| Decoder location | AV1 / VP9 | H.264 / HEVC |
|---|---|---|
| Native app, Fedora's Mesa (+ `libva`) | hardware | software |
| Native app, third-party Mesa (RPM Fusion or negativo17) | hardware | hardware |
| Flatpak app (runtime Mesa, `all_free`) | hardware | software, regardless of the host |

The third-party route therefore serves **native** applications only. Flatpak
applications — the project's application layer (§10) — are unaffected either way.

## Decision

**Take the Mesa stack, libva, libheif and ffmpeg from negativo17's
`fedora-multimedia` repository, Bluefin's way, narrowed to the AMD target.**

- The repository definition is committed at
  `system_files/etc/yum.repos.d/fedora-multimedia.repo` with `enabled=1`,
  `priority=90` (below Fedora's default 99, so negativo17's build wins wherever
  both carry a name), `gpgcheck=1` against a **committed key**
  (`system_files/etc/pki/rpm-gpg/RPM-GPG-KEY-slaanesh`, fingerprint
  `0C5D 0F47 0484 AE2F C40A 9B65 97F3 0089 93E8 909B`, Simone Caronni, valid to
  2029-08-31), and **`skip_if_unavailable=0`**: a build without the repository
  fails rather than silently producing an image with Fedora's Mesa.
- Repository and key are `COPY`ed **before** the main `dnf install`, so priority
  decides every overlapping package at first sight. `mesa-vulkan-drivers`,
  `libva`, `libva-utils`, `ffmpeg` and `vulkan-tools` join the main install line.
- Sixteen packages are **version-locked** (`dnf5-plugins`, `dnf versionlock add`):
  the Mesa set, `libva`, `libheif`, `ffmpeg` and its seven libraries. A later dnf
  transaction in the build that would replace any of them with a Fedora build
  fails loudly instead of splitting the stack.
- The image is **audited** after every build:
  `rpm -qa --qf '%{name} %{version}-%{release} %{vendor}\n' | grep -v 'Fedora Project'`.

This was the implementer's decision. The advisor's recommendation was the first
alternative below; the decision favoured full hardware codecs and a complete
ffmpeg on the host, following the reference implementation (§4.2).

## Alternatives considered

### Fedora's Mesa only (recommended by the advisor)

`libva`, `libva-utils`, `vulkan-tools` from Fedora; AV1/VP9 in hardware on the
host and in Flatpaks, H.264/HEVC in software; measure at Milestone 9 and amend
with evidence. Consistent with §3.6, §4.1 and §21, and with the fact that the
application layer is Flatpak, where the override changes nothing. Not chosen.

### RPM Fusion `-freeworld`

Two packages rather than a repository-wide override. Rejected: the VA package
pins `mesa-filesystem` to an exact Fedora version, so every Fedora Mesa update
makes it uninstallable until RPM Fusion rebuilds — a daily image build would
fail in every such gap.

### negativo17 as an override *after* the main install

Tried first: `distro-sync` the installed Mesa set, then `install` the rest.
It fails in two ways worth recording. `distro-sync` acts only on *installed*
packages (`mesa-vulkan-drivers` was not). And Fedora's `lib*-free` ffmpeg
libraries, already chosen at the main install as the only providers of
`libavcodec.so.62` (for `wf-recorder`), stayed underneath negativo17's `ffmpeg`
binary — `h264` and `hevc` were still missing — and negativo17's libraries
declare no `Conflicts`/`Obsoletes` that would let dnf replace them. Order is the
mechanism: the repository must be visible before anything is installed.

## Consequences

### Accepted benefits

- Hardware H.264/HEVC/VC-1 decoding on the host through VA-API and Vulkan video,
  for native applications; a complete ffmpeg (`h264`, `hevc`, `av1`, `vp9` and
  the rest); parity with Bluefin's media stack.
- Mesa 26.2.3 in the image, ahead of Fedora's 26.2.2-6 at the time — the
  relationship between the two repositories' versions goes either way.

### Accepted costs

- **44 non-Fedora packages** in the image (audit of 2026-09-18): the Mesa set
  (`mesa-dri-drivers`, `mesa-filesystem`, `mesa-libEGL`, `mesa-libGL`,
  `mesa-libgbm`, `mesa-vulkan-drivers`), `libva`, `libva-utils`, `libheif`,
  `ffmpeg` with `libavcodec`, `libavformat`, `libavutil`, `libavfilter`,
  `libavdevice`, `libswresample`, `libswscale`, and 28 codec libraries they link
  against — `x264-libs`, `x265-libs`, `libde265`, `openh264` (replacing the
  Cisco-repository build), `libfdk-aac` (replacing Fedora's `fdk-aac-free`),
  `libfreeaptx`, `kvazaar-libs`, `vvenc-libs`, `vvdec-libs`, `uvg266-libs`,
  `LCEVCdec`, `davs2-libs`, `xavs2-libs`, `libxavs`, `uavs3d-libs`, `xevd-libs`,
  `xeve-libs`, `libdca`, `librtmp`, `libvo-aacenc`, `mjpegtools-libs`, `mpeghdec`,
  `svt-jpeg-xs` — plus `gstreamer1-plugins-bad` in place of Fedora's `-free` build.
- A single maintainer's repository sits beneath the graphics stack — the §3.6
  exception. Its outages fail the build by design; its version drift is not
  digest-pinned and cannot be tracked by Renovate the way the base image is.
- Every Fedora package that links libav\* or Mesa now runs on negativo17's
  builds. Flatpak applications gain nothing.
- The version lock protects consistency *within* a build, not across rebuilds:
  each rebuild takes whatever negativo17 currently ships.

### Implementation notes

- negativo17's Fedora 44 Mesa has no `mesa-va-drivers` either; the VA driver is
  in its `mesa-dri-drivers` (ublue's `--skip-unavailable` exists for this).
- Its ffmpeg libraries are packaged as `libavcodec`, `libavformat`, … — not
  `ffmpeg-libs` — and must be locked under those names.

## Verification

- Build-time: `ffmpeg -hide_banner -decoders | grep -E " (h264|hevc|av1|vp9) "`
  shows all four; `rpm -qf /usr/lib64/libavcodec.so.62` → negativo17's
  `libavcodec`; no `lib*-free` remains; `dnf versionlock list` → 16 names; the
  vendor audit above.
- VM: Sway 1.11 starts on the replaced stack; `vulkaninfo` lists lavapipe; no new
  AVC denials.
- Milestone 9, on the Radeon: `vainfo` lists H.264/HEVC profiles;
  `vulkaninfo` shows RADV with the video extensions; hardware playback measured.

## Revisit when

- builds fail on the repository's availability or a lock conflict;
- negativo17 drops or delays a package the image depends on;
- Milestone 9 measurements show the benefit is not used in practice.

## References

- [RPM Fusion — Multimedia howto](https://rpmfusion.org/Howto/Multimedia)
- [freedesktop-sdk mesa element](https://gitlab.com/freedesktop-sdk/freedesktop-sdk/-/blob/master/elements/extensions/mesa/mesa.bst) (`video_codecs: all_free`)
- [ublue-os/main `build_files/install.sh`](https://github.com/ublue-os/main/blob/main/build_files/install.sh) and `packages.json`
- [negativo17 Multimedia repository](https://negativo17.org/repos/fedora-multimedia.repo)
- [dnf5 versionlock](https://dnf5.readthedocs.io/en/latest/commands/versionlock.8.html)
- [ADR 0001](0001-base-image.md) · [ADR 0003](0003-no-weak-dependencies.md)
