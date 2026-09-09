# Blauer Zimt — minimal bootc image (Milestone 0)
#
# The §5 layer boundaries (hardware / Cinnamon / common / edition) live as
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

# --- Validate (§18) -------------------------------------------------------
# Must be last: it checks the final image, not an intermediate state.
RUN bootc container lint
