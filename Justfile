# Blauer Zimt — local development recipes

image := "blauer-zimt"
tag   := "44"

default:
    @just --list

# Rebuild the image, regenerate the disk, and boot it
cycle: build build-qcow2 run-vm

# Build the OCI image (bootc container lint runs as the final layer)
build:
    sudo podman build -t {{image}}:{{tag}} .

# Build a QCOW2 disk image from the local image
build-qcow2:
    mkdir -p output
    sudo podman run --rm -it --privileged \
        -v ./config.toml:/config.toml:ro \
        -v ./output:/output \
        -v /var/lib/containers/storage:/var/lib/containers/storage \
        quay.io/centos-bootc/bootc-image-builder:latest \
        --type qcow2 \
        --rootfs xfs \
        --chown $(id -u):$(id -g) \
        localhost/{{image}}:{{tag}}
    cp /usr/share/OVMF/OVMF_VARS_4M.fd output/OVMF_VARS.fd

# Boot the QCOW2; Ctrl-A X to quit, Ctrl-A C for the monitor
run-vm:
    [ -f output/OVMF_VARS.fd ] || cp /usr/share/OVMF/OVMF_VARS_4M.fd output/OVMF_VARS.fd
    qemu-system-x86_64 -enable-kvm -m 4096 -smp 4 -cpu host -machine q35 \
        -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd \
        -drive if=pflash,format=raw,file=output/OVMF_VARS.fd \
        -drive file=output/qcow2/disk.qcow2,if=virtio,format=qcow2 \
        -nic user,model=virtio-net-pci,hostfwd=tcp::2222-:22 \
        -device virtio-vga,xres=1600,yres=900 \
        -device qemu-xhci \
        -device usb-tablet \
        -display gtk \
        -serial mon:stdio \
        -audiodev pa,id=snd0 \
        -device ich9-intel-hda -device hda-duplex,audiodev=snd0 

# Discard build artifacts (keeps config.toml)
clean:
    rm -rf output