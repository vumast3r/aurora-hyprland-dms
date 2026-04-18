ARG BASE_IMAGE="ghcr.io/ublue-os/aurora-nvidia-open"
ARG FEDORA_MAJOR_VERSION="43"

FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION}

ARG FEDORA_MAJOR_VERSION="43"

# Copy build scripts and system files into the image
COPY build_files /tmp/build_files
COPY system_files /tmp/system_files

# Install hyprland-dms packages
RUN --mount=type=cache,dst=/var/cache/libdnf5 \
    chmod +x /tmp/build_files/*.sh && \
    /tmp/build_files/01-packages.sh

# Install configs and system files
RUN /tmp/build_files/03-configs.sh

# Sanity checks
RUN /tmp/build_files/05-tests.sh

# Cleanup
RUN /tmp/build_files/04-cleanup.sh

CMD ["/sbin/init"]
