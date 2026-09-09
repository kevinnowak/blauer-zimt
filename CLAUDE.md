# Project Blauer Zimt

## 1. Project Overview

**Blauer Zimt** is a personal Linux operating system image intended to become my primary daily-driver operating system for both personal use and professional software engineering.

The project is inspired by:

- [Project Bluefin](https://projectbluefin.io/)
- [Universal Blue](https://universal-blue.org/)
- Fedora Atomic / bootc-based operating systems

The goal is **not** to create a fork of Bluefin with GNOME removed.

Instead:

> **Blauer Zimt is a Cinnamon-based Fedora bootc workstation that adopts Bluefin's architecture, maintenance philosophy, developer experience, automation patterns, and useful desktop-independent features where appropriate.**

The operating system should eventually require very little manual maintenance and should behave like an appliance-style Linux workstation while still providing an excellent software-development environment.

---

# 2. Core Goals

The finished system should provide:

- Fedora as the underlying Linux distribution.
- An image-based / bootc-based operating system.
- Cinnamon as the primary and only supported desktop environment.
- A desktop experience comparable to Fedora Cinnamon Spin or Linux Mint.
- Mint-X-Aqua styling by default.
- Excellent support for modern AMD-based desktop hardware.
- A good Linux gaming experience.
- Automated OCI image builds.
- Automated publishing to a container registry.
- Signed images.
- Automatic operating-system updates.
- Safe rollback capabilities.
- Automatic handling of Fedora major-version upgrades.
- A stable release stream suitable for daily use.
- A testing release stream for validating upcoming changes.
- A separate developer-focused **DX edition**.
- Reproducible local builds.
- Fast VM-based development and testing.
- Automated CI testing.
- Eventually, a bootable installer ISO suitable for installing the system on bare metal.

The system should be maintainable with as little manual intervention as reasonably possible.

---

# 3. Project Context, Hardware Target, Gaming, and Learning Model

Blauer Zimt is primarily a **personal learning project**.

It is not merely an attempt to produce a finished operating-system image as quickly as possible.

Understanding how the system works is one of the main goals of the project.

---

## 3.1 Learning Project

I am the primary developer and implementer of Blauer Zimt.

Claude Code should primarily act as:

- technical advisor
- architecture advisor
- teacher
- explainer
- reviewer
- debugging partner
- research assistant

Claude Code should **not** treat the project as something it should autonomously implement from beginning to end.

The preferred collaboration model is:

```text
Understand the problem
        ↓
Discuss possible solutions
        ↓
Explain the relevant concepts
        ↓
Recommend an approach
        ↓
I implement the change
        ↓
Claude helps review/debug it
        ↓
Continue to the next small step
```

Claude may write code, configuration, scripts, or complete implementations when I explicitly ask for them.

However, by default, Claude should favor helping me understand and implement the solution myself.

When providing implementation guidance, explain:

- what we are changing
- why it is necessary
- how it works
- why the proposed approach was chosen
- relevant alternatives
- how I can verify that it works

Do not hide important complexity behind large generated solutions when a smaller educational step would be more useful.

The goal is that I should understand the architecture and major implementation decisions of Blauer Zimt rather than merely possessing AI-generated configuration files.

---

## 3.2 Prefer Teaching Over Blind Automation

When appropriate, guide me through implementation incrementally.

Prefer:

```text
Goal
 ↓
Relevant concept
 ↓
Small implementation step
 ↓
Run/test it
 ↓
Understand result
 ↓
Next step
```

over:

```text
Generate entire subsystem
 ↓
Hope it works
```

If a command is important to understanding the project, explain what the command does rather than only providing something to copy and paste.

If I misunderstand a Linux, Fedora, bootc, container, CI, or operating-system concept, correct the misunderstanding and explain the underlying model.

Do not unnecessarily simplify explanations merely to move faster.

---

## 3.3 Target Hardware

Blauer Zimt is primarily intended for modern **AMD-based x86-64 desktop and laptop hardware**.

The expected hardware configuration is:

```text
CPU: AMD
GPU: AMD
Architecture: x86-64
```

The system should therefore prioritize excellent support for:

- modern AMD Ryzen CPUs
- AMD integrated graphics
- AMD Radeon GPUs
- AMDGPU
- Mesa
- Vulkan
- VA-API / hardware video acceleration
- modern AMD power-management functionality
- AMD firmware available through Fedora
- AMD gaming workloads

Hardware-related configuration should generally follow Fedora defaults unless there is a clear reason to change them.

---

## 3.4 NVIDIA Is Out of Scope

NVIDIA support is explicitly **not a goal of this project**.

Do not add complexity solely for:

- proprietary NVIDIA drivers
- NVIDIA kernel modules
- NVIDIA-specific repositories
- NVIDIA-specific image variants
- NVIDIA-specific boot handling
- NVIDIA-specific Secure Boot handling
- CUDA
- Optimus
- NVIDIA-specific workarounds

This is an intentional scope decision.

Reducing hardware scope allows Blauer Zimt to remain simpler and easier to understand and maintain.

If some generic functionality incidentally also works on NVIDIA hardware, that is acceptable, but NVIDIA compatibility should not influence architectural decisions unless this scope is explicitly changed later.

---

## 3.5 Gaming

Blauer Zimt should be a capable Linux gaming system in addition to being a software-development workstation.

Gaming is a supported use case, not an accidental side effect.

The system should provide a good foundation for playing Linux-native and Windows games through the modern Linux gaming ecosystem.

Relevant technologies may include:

- Steam
- Proton
- Proton-GE where appropriate
- Wine where useful
- Mesa
- Vulkan
- AMD RADV
- GameMode
- MangoHud
- Gamescope
- controller/gamepad support
- modern audio support through PipeWire

Not all of these must necessarily be installed directly into the base image.

The same software-placement principles used elsewhere in the project should apply.

For example:

- system-level GPU drivers belong in the operating-system image
- Steam may be installed through Flatpak if that provides the best overall solution
- optional gaming utilities should not unnecessarily bloat the core operating-system layer

Bluefin and related Universal Blue gaming projects may be studied for useful gaming configuration, but gaming functionality should be evaluated independently rather than copied blindly.

---

## 3.6 Gaming Hardware Philosophy

Because the target GPU platform is AMD, prefer the normal open-source Fedora graphics stack.

The expected graphics architecture should generally remain:

```text
Linux kernel
    ↓
AMDGPU
    ↓
Mesa
    ↓
RADV / Vulkan
    ↓
Steam / Proton / native games
```

Avoid unnecessary custom graphics stacks or third-party driver repositories unless there is a demonstrated need.

Prefer upstream Fedora, Mesa, kernel, and firmware improvements over local patches.

---

## 3.7 Gaming Acceptance Goal

Eventually, a stable Blauer Zimt installation should be able to:

- detect a supported AMD GPU correctly
- provide working Vulkan acceleration
- provide working hardware-accelerated graphics
- run Steam
- run native Linux games
- run compatible Windows games through Proton
- support common controllers
- provide working PipeWire audio during games
- survive normal operating-system image updates without requiring GPU-driver reinstallation

Gaming-specific automated testing may be limited, but major graphics regressions should be considered release blockers for stable builds when they affect the supported AMD hardware target.

---

# 4. Guiding Philosophy

Blauer Zimt should follow these principles.

## 4.1 Prefer upstream solutions

Prefer, in roughly this order:

1. Official Fedora packages and repositories.
2. Official bootc tooling.
3. Well-maintained Fedora / Universal Blue ecosystem tools.
4. Well-maintained third-party solutions when necessary.

Avoid maintaining custom packages when an appropriate Fedora package already exists.

Avoid manually compiling desktop components unless there is a very strong reason.

---

## 4.2 Bluefin is a reference implementation

Bluefin should be studied heavily for:

- image architecture
- update strategy
- CI/CD
- developer tooling
- container development
- Flatpak handling
- image signing
- dependency management
- testing
- release management
- useful CLI tools
- developer-experience features
- automation patterns

However, Bluefin functionality must not be copied blindly.

Every feature should be evaluated according to whether it makes sense for Blauer Zimt.

Do not inherit functionality simply because Bluefin has it.

---

## 4.3 Cinnamon is a first-class desktop

Do not treat Cinnamon as an afterthought layered on top of a GNOME workstation.

The system should be architected around Cinnamon from the beginning.

GNOME-specific configuration, extensions, branding, applications, tweaks, and workflows should not be included unless they are required dependencies of functionality that Blauer Zimt actually needs.

---

## 4.4 Keep maintenance cost low

When choosing between:

- newer software with significant custom maintenance

and

- slightly older software maintained by Fedora

prefer the Fedora-maintained solution unless there is a compelling reason not to.

The long-term maintainability of the system is more important than having every component at the absolute newest upstream version.

---

# 5. Base Operating System

Blauer Zimt should be based as directly as practical on official Fedora bootc-compatible / Atomic infrastructure.

Do not base the project on an entire Bluefin desktop image merely to remove GNOME afterward.

The preferred architecture is conceptually:

```text
Official Fedora bootc-compatible base
                │
                ▼
      Cinnamon workstation layer
                │
                ▼
       Blauer Zimt common layer
          ┌─────┴─────┐
          ▼           ▼
    Blauer Zimt   Blauer Zimt DX
```

The exact Fedora base image should be chosen according to current Fedora and bootc best practices.

Before changing the fundamental base image, investigate the current Fedora, bootc, Bluefin, and Universal Blue architecture.

Such a change should be treated as an architectural decision rather than a routine implementation detail.

---

# 6. Cinnamon Desktop

Cinnamon is the supported desktop environment.

The target experience should be close to the completeness of:

- Fedora Cinnamon Spin
- Linux Mint Cinnamon

while retaining Fedora and bootc as the operating-system foundation.

Required desktop functionality includes, at minimum:

- Cinnamon desktop
- Cinnamon session
- display manager
- Nemo
- networking
- Bluetooth
- PipeWire audio
- standard desktop portals
- power management
- removable-device support
- printing support where appropriate
- common archive and filesystem support
- Flatpak integration

The goal is a fully functional workstation rather than merely installing the `cinnamon` package.

---

# 7. Cinnamon Version Policy

"Latest Cinnamon" means:

> The newest Cinnamon version officially supported and packaged for the currently targeted Fedora release.

Do not independently package newer upstream Cinnamon versions merely because they have been released upstream.

Custom Cinnamon packaging should only be considered after an explicit architectural decision.

---

# 8. Desktop Styling

The default desktop should remain recognizably stock Cinnamon rather than becoming heavily branded.

Preferred defaults:

- Desktop environment: Cinnamon
- GTK/application theme: Mint-X-Aqua
- Icon theme: Mint-X-Aqua or the corresponding packaged Mint-X icon variant
- Window decoration: matching Mint-X styling where supported

Use Fedora-packaged Mint themes and icons whenever possible.

Do not introduce Blauer Zimt-specific colors, logos, wallpapers, themes, or other branding unless explicitly requested later.

Functional project naming inside the operating system is acceptable, but visual branding should remain minimal.

---

# 9. Editions

The project should produce two main operating-system editions.

## 9.1 Blauer Zimt

The standard workstation edition.

It should contain:

- Cinnamon desktop
- desktop essentials
- system configuration
- Flatpak support
- commonly useful workstation utilities
- automatic updates
- AMD graphics support
- gaming foundation
- container-friendly host functionality where appropriate

This should be suitable for general daily use.

---

## 9.2 Blauer Zimt DX

Blauer Zimt DX is the developer-focused edition.

It should extend the normal Blauer Zimt image rather than being maintained as a completely independent operating system.

Conceptually:

```text
Blauer Zimt DX = Blauer Zimt + Developer Experience Layer
```

Potential DX functionality includes:

- Podman
- container development
- Docker compatibility where appropriate
- development containers
- virtualization
- QEMU/KVM
- useful compiler/build dependencies
- development CLI utilities
- developer fonts
- IDE-related support
- Kubernetes tooling where useful
- Homebrew or equivalent developer tooling if it provides clear value
- other desktop-independent features inspired by Bluefin DX

DX functionality should be evaluated individually.

Do not automatically copy the complete Bluefin DX environment.

---

# 10. Software Installation Philosophy

Use different installation mechanisms for different kinds of software.

As a general guideline:

### Image / RPM layer

Use for:

- operating-system components
- hardware support
- GPU drivers and graphics stack
- Cinnamon
- core system utilities
- system services
- components required during boot
- components that need deep host integration

### Flatpak

Prefer for graphical desktop applications where Flatpak provides a good experience.

This may include applications such as Steam if Flatpak provides the best overall integration and maintenance model.

### Containers

Prefer for development services, databases, build environments, and workloads that do not need to modify the host operating system.

### Developer package manager

A developer-oriented package manager such as Homebrew may be used for CLI development tools if this follows current best practices and substantially improves the development experience.

Avoid unnecessarily layering large numbers of development tools directly into the base operating-system image.

---

# 11. Bluefin Feature Adoption

Do not interpret "inspired by Bluefin" as "copy everything Bluefin contains."

Bluefin features should be divided conceptually into:

### Adopt

Desktop-independent functionality that clearly benefits Blauer Zimt.

### Adapt

Useful functionality that needs modification to work properly with Cinnamon or the AMD-focused hardware scope.

### Reject

Functionality related specifically to:

- GNOME Shell
- GNOME extensions
- GNOME-specific tweaks
- GNOME-specific workflows
- Bluefin visual branding
- Bluefin wallpapers
- Bluefin logos
- Bluefin-specific desktop styling
- NVIDIA-specific functionality that is irrelevant to Blauer Zimt

When evaluating a significant Bluefin feature, prefer documenting which of these categories it belongs to.

---

# 12. Repository

The project lives in a GitHub repository.

GitHub should be used for:

- source control
- pull requests
- issue tracking where useful
- GitHub Actions
- release automation
- container image publishing

OCI images should preferably be published to:

```text
GitHub Container Registry (GHCR)
```

unless another registry later provides a compelling advantage.

---

# 13. Repository Structure

Keep the repository understandable.

A possible structure is:

```text
.
├── CLAUDE.md
├── README.md
├── Containerfile
├── Justfile
├── build/
├── config/
├── packages/
├── system_files/
├── flatpaks/
├── scripts/
├── tests/
├── dx/
└── .github/
    └── workflows/
```

This structure is illustrative rather than mandatory.

Prefer a clear architecture over unnecessary abstraction.

Do not introduce complex directory hierarchies unless they solve a real problem.

---

# 14. Build System

Use standard container / bootc tooling whenever possible.

Containerfile-based builds are preferred initially.

BlueBuild may be investigated but is **not a project requirement**.

Do not introduce BlueBuild simply because it appears in the resources list.

Before adopting an abstraction layer such as BlueBuild, determine whether it provides a meaningful benefit over a straightforward Containerfile-based setup.

Prefer boring and understandable build infrastructure.

---

# 15. Local Development

A major project requirement is a **tight iterative feedback loop**.

Normal development should not require installing the operating system on physical hardware.

The desired development loop is approximately:

```text
Modify source
     │
     ▼
Build OCI image locally
     │
     ▼
Run container/image validation
     │
     ▼
Build VM disk image
     │
     ▼
Boot in QEMU/KVM
     │
     ▼
Validate change
     │
     ▼
Commit / push
     │
     ▼
CI validation
```

The primary development environment will initially be an existing Linux workstation.

Use Podman and QEMU/KVM where practical.

---

# 16. VM Development Target

QCOW2 or another suitable VM disk format should be preferred for frequent development testing.

Do not rebuild an installer ISO for every normal development iteration.

The normal progression should be:

```text
OCI image
   ↓
VM image
   ↓
QEMU/KVM
   ↓
Automated VM tests
   ↓
Installer ISO
   ↓
Bare metal
```

VM testing should become increasingly automated as the project matures.

---

# 17. Installer ISO

The eventual project deliverable should include a bootable ISO that can install Blauer Zimt on bare metal.

Initially, this means an **installer ISO**, not necessarily a Linux Mint-style live desktop ISO.

Required workflow:

```text
Boot ISO
   ↓
Installer starts
   ↓
Install Blauer Zimt to disk
   ↓
Reboot
   ↓
System boots into Blauer Zimt
```

A full live desktop environment running directly from the ISO is outside the initial project scope unless explicitly added later.

---

# 18. Image Validation

Every generated bootc image should be validated using appropriate bootc validation tools.

Where supported, include:

```bash
bootc container lint
```

or its current recommended equivalent.

An image should not be published as stable if fundamental bootc validation fails.

---

# 19. Minimum Functional Acceptance Criteria

A standard Blauer Zimt image should eventually satisfy at least the following:

- OCI image builds successfully.
- bootc image validation succeeds.
- VM disk image can be generated.
- VM boots successfully.
- system reaches the graphical target.
- display manager starts.
- Cinnamon session can start.
- Nemo works.
- network connectivity works.
- PipeWire audio infrastructure is available.
- Flatpak works.
- AMD graphics drivers and Mesa are available.
- Vulkan works on supported AMD hardware.
- Steam can be installed and used through the chosen supported mechanism.
- system reports valid bootc deployment information.
- system update can be staged.
- reboot into a new deployment works.
- rollback remains possible.

Additional automated tests should be added over time.

---

# 20. Continuous Integration

GitHub Actions should automate the project pipeline.

The pipeline should eventually cover:

- validation
- image build
- bootc linting
- VM image generation where practical
- automated boot testing
- OCI publishing
- image signing
- release tagging
- testing/stable promotion
- dependency updates

Avoid making the CI architecture excessively complicated before it is needed.

Build sophistication should grow together with project maturity.

---

# 21. Image Signing and Supply-Chain Security

Published production images must be signed.

Prefer established Sigstore / Cosign mechanisms where appropriate.

Security requirements include:

- do not commit secrets
- use GitHub Actions secrets only where necessary
- minimize workflow permissions
- prefer short-lived credentials where supported
- pin important external dependencies
- pin container base images by digest where practical
- pin third-party GitHub Actions to immutable commits where practical
- automate dependency-update pull requests
- keep the build process reproducible and auditable

Renovate, Dependabot, or equivalent tooling may be used for automated dependency updates.

---

# 22. Release Channels

The project should eventually provide at least two release channels:

```text
stable
testing
```

for both editions.

Conceptually:

```text
blauer-zimt:stable
blauer-zimt:testing

blauer-zimt-dx:stable
blauer-zimt-dx:testing
```

Additional Fedora-version-specific tags may be used.

For example:

```text
blauer-zimt:44
blauer-zimt:45
```

Exact tag conventions should be designed once the first working publishing pipeline exists.

---

# 23. Stable Channel

The stable channel is the primary daily-driver release.

It should prioritize:

- reliability
- tested updates
- predictable behavior
- safe Fedora upgrades

Stable should not automatically receive every experimental change.

---

# 24. Testing Channel

The testing channel receives changes before stable.

It should be used to validate:

- package changes
- Cinnamon changes
- graphics-stack changes
- system configuration
- image architecture
- new developer tooling
- Fedora major upgrades

Important updates should spend sufficient time in testing before promotion to stable.

---

# 25. Automatic Operating-System Updates

Blauer Zimt should eventually update automatically with minimal user intervention.

The intended experience is:

```text
New signed image published
        ↓
Client discovers update
        ↓
Update is downloaded/staged
        ↓
User continues working
        ↓
Next suitable reboot
        ↓
New deployment becomes active
```

Updates must preserve bootc's rollback capabilities.

Automatic update behavior should favor reliability over immediate deployment.

---

# 26. Fedora Major-Version Upgrade Policy

Blauer Zimt should track Fedora releases automatically, but stable systems must not upgrade to a new Fedora major version immediately on Fedora release day.

A new Fedora version should first be introduced into the testing stream.

Example process:

```text
Fedora N released
        ↓
Blauer Zimt testing moves to Fedora N
        ↓
Build validation
        ↓
VM boot validation
        ↓
Cinnamon validation
        ↓
AMD graphics validation
        ↓
Upgrade-path validation
        ↓
Stabilization period
        ↓
Stable promotion
```

Target stabilization period:

> approximately 1–2 weeks after Fedora release

However, promotion must not be purely time-based.

Stable promotion requires successful validation and no known blocker issues.

A reasonable initial rule is:

> A Fedora major release may be promoted to the Blauer Zimt stable stream no sooner than 14 days after Fedora's release and only after required validation succeeds.

This policy can later be adjusted based on real-world experience.

---

# 27. Rollback

Rollback is a core feature, not an optional enhancement.

System updates must preserve the ability to boot back into a previous working deployment when possible.

Do not implement update mechanisms that bypass or undermine bootc's deployment and rollback model without a compelling architectural reason.

---

# 28. Scope

## In scope

The project may manage:

- operating-system image
- Fedora base
- Cinnamon desktop
- AMD CPU/GPU support
- Mesa and Vulkan stack
- gaming foundation
- host packages
- system services
- system defaults
- Cinnamon defaults
- Flatpak defaults
- development tooling
- update configuration
- bootc configuration
- image build infrastructure
- CI/CD
- image signing
- release channels
- VM testing
- installer media

---

## Initially out of scope

The operating-system image should not initially contain or manage:

- NVIDIA-specific support
- personal documents
- passwords
- private SSH keys
- private GPG keys
- personal credentials
- machine-specific secrets
- backups
- private source code
- large amounts of user-specific dotfile configuration
- IDE project configuration

Personal environment configuration should remain a separate concern from the operating-system image unless explicitly brought into scope later.

---

# 29. Secrets

Never bake secrets into:

- the Containerfile
- container layers
- system files
- Git history
- test images
- generated ISO files

When credentials are required during CI, use appropriate secret-management mechanisms.

---

# 30. Development Principles for Claude

When working on this repository, follow these rules.

## 30.1 I am the primary implementer

The default assumption is that **I will make the actual implementation changes**.

Claude should help me understand what to do and why.

Do not automatically take over implementation merely because a change can be generated quickly.

When appropriate:

1. explain the objective
2. explain the relevant concept
3. propose the next implementation step
4. show me how to perform it
5. explain how to validate it
6. help diagnose the result

If I explicitly ask Claude to implement something, then producing the implementation is appropriate.

---

## 30.2 Work incrementally

Prefer small, testable changes.

Do not attempt to implement several major architectural milestones at once.

A small working system that I understand is more valuable than a large untested implementation.

---

## 30.3 Maintain tight feedback loops

Every meaningful change should have a practical method of verification.

Prefer:

```text
understand
→ change
→ build
→ test
→ inspect
→ explain
→ continue
```

over implementing large speculative batches.

---

## 30.4 Explain commands and configuration

When introducing an important command, configuration file, Containerfile instruction, systemd unit, GitHub Actions construct, or bootc concept, explain its purpose.

Do not merely provide commands without context when understanding them is useful to the learning goals of the project.

Where appropriate, explain important command-line arguments individually.

---

## 30.5 Verify current upstream architecture

Fedora, bootc, Universal Blue, and Bluefin evolve quickly.

Before making decisions that depend on their current architecture, verify the current official documentation and repositories.

Do not rely solely on remembered historical architecture.

This especially applies to:

- Fedora base-image choices
- bootc tooling
- Bluefin image structure
- update mechanisms
- Universal Blue infrastructure
- ISO generation
- image signing
- major-version upgrade handling
- Fedora graphics stack
- Linux gaming tooling

---

## 30.6 Prefer primary sources

When researching implementation details, prefer:

1. Fedora documentation
2. bootc documentation
3. Universal Blue repositories/documentation
4. Bluefin repositories/documentation
5. relevant upstream project documentation

Use third-party articles mainly as secondary context.

---

## 30.7 Explain major architectural decisions

Before introducing a significant architectural dependency or changing a fundamental approach, explain:

- the problem
- available alternatives
- proposed solution
- advantages
- disadvantages
- maintenance implications

Examples include:

- changing the Fedora base image
- adopting BlueBuild
- introducing a custom package repository
- replacing the updater
- changing the image hierarchy
- changing release channels
- modifying the graphics stack
- introducing non-Fedora gaming repositories

---

## 30.8 Avoid premature abstraction

Do not create frameworks or complicated abstractions merely because they might become useful later.

Prefer straightforward:

- Containerfiles
- shell scripts
- configuration files
- Justfile recipes
- GitHub Actions

until repetition or complexity justifies something more sophisticated.

---

## 30.9 Separate responsibilities

Keep clear boundaries between:

```text
Fedora base
hardware support
Cinnamon desktop configuration
Blauer Zimt common functionality
gaming functionality
DX functionality
Flatpak applications
system configuration
CI/CD
testing
installation media
```

Do not allow DX-specific or gaming-specific requirements to unnecessarily complicate the core operating-system architecture.

---

## 30.10 Avoid unnecessary GNOME coupling

Cinnamon may naturally depend on some GNOME/GTK libraries.

That is acceptable.

However, do not introduce GNOME Shell, GNOME extensions, GNOME Tweaks, GNOME-specific desktop configuration, or GNOME-specific workflows unless explicitly necessary.

---

## 30.11 Avoid NVIDIA complexity

Do not introduce NVIDIA-specific packages, configuration, CI variants, documentation, workarounds, or architectural abstractions unless the project scope is explicitly changed.

Assume AMD graphics when reasoning about the intended bare-metal system.

---

## 30.12 Preserve upgradeability

When making system modifications, always consider whether the change:

- survives future image rebuilds
- works across Fedora releases
- can be tested
- can be rolled back
- introduces long-term maintenance burden

Avoid fragile hacks inside the immutable/image-based operating system.

---

## 30.13 Keep documentation current

When architecture changes, update relevant documentation in the same change whenever practical.

Do not allow important architecture decisions to exist only in implementation code.

---

# 31. Initial Milestones

Development should roughly progress through the following milestones.

## Milestone 0 — Architecture and Repository Foundation

Goals:

- understand the relevant bootc architecture
- decide initial Fedora base
- establish repository structure
- create minimal Containerfile
- establish local build process
- document architectural decisions

Deliverable:

A minimal bootc-compatible container image that builds successfully.

---

## Milestone 1 — Minimal Cinnamon System

Goals:

- install Cinnamon
- configure graphical boot
- configure login/session
- establish required Cinnamon dependencies
- generate a VM image

Deliverable:

A VM that boots into a usable Cinnamon session.

Do not add extensive application, gaming, or DX tooling before this works.

---

## Milestone 2 — Complete Desktop Foundation

Goals:

- networking
- audio
- Bluetooth
- Flatpak
- Nemo
- portals
- removable media
- desktop integration
- Mint-X-Aqua defaults

Deliverable:

A VM suitable for basic everyday desktop use.

---

## Milestone 3 — OCI Publishing

Goals:

- GitHub Actions image builds
- GHCR publishing
- image signing
- automated validation

Deliverable:

A signed Blauer Zimt image available from the registry.

---

## Milestone 4 — Update System

Goals:

- automatic update discovery
- deployment staging
- reboot activation
- rollback validation

Deliverable:

A VM can automatically move from one published Blauer Zimt image to another safely.

---

## Milestone 5 — Workstation and Gaming Foundation

Goals:

- establish Flatpak application list
- add useful desktop-independent Bluefin functionality
- add workstation CLI utilities
- verify AMD graphics stack
- verify Vulkan
- establish Steam installation strategy
- establish basic gaming utilities where appropriate

Deliverable:

A polished standard Blauer Zimt workstation capable of normal desktop use and Linux gaming on supported AMD hardware.

---

## Milestone 6 — Blauer Zimt DX

Goals:

- derive DX from standard edition
- development containers
- virtualization
- development CLI tooling
- developer workflow enhancements

Deliverable:

A development-focused Blauer Zimt DX image.

---

## Milestone 7 — Automated VM Testing

Goals:

- automatic VM creation
- automatic boot validation
- service validation
- Cinnamon session validation where practical
- upgrade-path testing

Deliverable:

CI catches major operating-system regressions before publishing/promoting stable images.

---

## Milestone 8 — Installer ISO

Goals:

- generate installer media
- boot on VM
- install Blauer Zimt
- reboot into installed system

Deliverable:

A working Blauer Zimt installer ISO.

---

## Milestone 9 — Bare-Metal AMD Validation

Goals:

- install on target AMD hardware
- validate AMDGPU
- validate Mesa/Vulkan
- validate hardware acceleration
- validate audio
- validate suspend/resume
- validate gaming
- validate system updates and rollback

Deliverable:

Blauer Zimt operates reliably as a daily driver on the intended AMD system.

---

## Milestone 10 — Stable and Testing Streams

Goals:

- testing channel
- stable channel
- promotion workflow
- release policy

Deliverable:

A safe mechanism for daily-driver releases.

---

## Milestone 11 — Fedora Major Upgrade Automation

Goals:

- detect upcoming Fedora releases
- build testing images
- validate upgrade path
- enforce stabilization period
- promote new Fedora base to stable

Deliverable:

Blauer Zimt follows Fedora major releases with minimal manual maintenance.

---

# 32. Definition of Success

Blauer Zimt should eventually allow the following workflow:

```text
I develop and understand a change
        ↓
Test locally
        ↓
Commit and push to GitHub
        ↓
CI validates and builds image
        ↓
Signed OCI image is published
        ↓
Testing systems receive update
        ↓
Automated/manual validation succeeds
        ↓
Image promoted to stable
        ↓
Daily-driver machine stages update
        ↓
Reboot
        ↓
Updated system
```

The system should provide:

```text
Daily personal workstation
+
Software engineering workstation
+
AMD Linux gaming system
```

without requiring three different operating-system setups.

The user should normally not need to manually reinstall the operating system or perform traditional distribution upgrades.

When Fedora releases a new major version, Blauer Zimt should eventually move to it through the same image update mechanism after a controlled stabilization period.

Equally important:

> By developing Blauer Zimt, I should gain a practical understanding of Fedora, Linux system architecture, containers, bootc, image-based operating systems, systemd, CI/CD, Linux desktop integration, graphics stacks, and software-distribution concepts.

The knowledge gained from building the system is itself a primary project outcome.

---

# 33. Non-Goals

Blauer Zimt is not intended to become:

- a general-purpose Linux distribution for everyone
- a replacement for Fedora
- a Cinnamon fork
- a Bluefin fork
- a heavily customized themed desktop
- a collection of unsupported bleeding-edge packages
- an NVIDIA-focused distribution
- a multi-vendor GPU compatibility project
- a traditional mutable Linux installation managed through manual package upgrades
- a project primarily implemented autonomously by Claude Code

It is primarily a highly automated personal AMD-focused workstation image and a practical learning project.

Architecture should therefore prioritize:

- understandability
- maintainability
- reliability
- educational value
- usefulness on the intended hardware

over supporting every possible configuration.

---

# 34. Existing Reference Project

The following project attempted something related:

https://github.com/Danathar/cinnamon-ublue

It may be inspected for:

- lessons learned
- package requirements
- Cinnamon-specific integration issues
- useful implementation ideas

However:

> Blauer Zimt should be designed independently.

Do not copy the architecture blindly.

If something from that repository is adopted, understand why it works and verify whether it remains appropriate with current Fedora / bootc architecture.

---

# 35. Resources

Primary references:

- https://bootc.dev/
- https://docs.fedoraproject.org/en-US/bootc/getting-started/
- https://github.com/bootc-dev/bootc
- https://github.com/ublue-os/bluefin
- https://github.com/ublue-os/main
- https://github.com/ublue-os/image-template
- https://universal-blue.org/
- https://projectbluefin.io/
- https://docs.projectbluefin.io/
- https://fedoraproject.org/spins/cinnamon/

Additional resources:

- https://blue-build.org/
- https://github.com/Danathar/cinnamon-ublue

Relevant Red Hat image-mode documentation:

- https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/using_image_mode_for_rhel_to_build_deploy_and_manage_operating_systems/deploying-the-rhel-bootc-images
- https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/10/html/using_image_mode_for_rhel_to_build_deploy_and_manage_operating_systems/generating-a-custom-minimal-base-image

---

# 36. First Task

Do not start by building the complete operating system.

Do not generate the entire repository architecture without first helping me understand the initial decisions.

The first task should be:

> Investigate and explain the current Fedora and bootc base-image options suitable for building a Cinnamon-oriented, AMD-targeted workstation. Compare the realistic options, recommend one, and explain the reasoning.

After we decide on the base together:

> Help me create the smallest possible bootc-compatible image derived from it and establish a reproducible local build process.

I should perform the implementation with Claude's guidance unless I explicitly ask Claude to implement a particular part.

After the minimal image works, proceed toward the first minimal Cinnamon VM.

Always optimize for:

```text
understanding
+
small steps
+
short feedback loops
+
working intermediate states
```