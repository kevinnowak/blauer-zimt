# Blauer Zimt — minimal bootc image (Milestone 0)
#
# The §5 layer boundaries (hardware / Sway / common / edition) live as
# commented sections in this single file until Milestone 6 gives us a second
# consumer worth splitting for.

FROM quay.io/fedora/fedora-bootc:44@sha256:1bc549cb2909ebd1bb69e05088797dd602eee691f7deaa40f5b9914c3ce84b36

# --- Identity -------------------------------------------------------------
# Presentation fields only. ID and VERSION_ID stay fedora/44: dnf's
# $releasever, RPM macros and third-party repos all resolve through them.
RUN sed -i \
        -e 's/^NAME=.*/NAME="Blauer Zimt"/' \
        -e 's/^PRETTY_NAME=.*/PRETTY_NAME="Blauer Zimt 44"/' \
        -e 's/^VARIANT=.*/VARIANT="Blauer Zimt"/' \
        -e 's/^VARIANT_ID=.*/VARIANT_ID=blauer-zimt/' \
        /usr/lib/os-release

# --- Build policy ---------------------------------------------------------
# Weak dependencies (Recommends) are not installed. Every package in this
# image is either a hard requirement or named in a dnf line below. ADR 0003.
RUN mkdir -p /etc/dnf/libdnf5.conf.d \
    && printf '[main]\ninstall_weak_deps=False\n' > /etc/dnf/libdnf5.conf.d/blauer-zimt.conf

# --- Hardware ------------------------------------------------------------
# mesa-dri-drivers: Gallium drivers — radeonsi for the target, virgl and
# llvmpipe for the VM. Vulkan (RADV) waits for a machine that can verify it.
#
# --- Sway ----------------------------------------------------------------
# The config provider is named explicitly; the resolver must never pick it.
# foot and wmenu are what upstream's config binds $mod+Return and $mod+d to.
RUN dnf -y install \
        mesa-dri-drivers \
        sway sway-config-upstream sway-systemd foot wmenu \
        greetd greetd-selinux tuigreet \
    && dnf clean all

# --- Validate (§18) -------------------------------------------------------
# Must be last: it checks the final image, not an intermediate state.
RUN bootc container lint
