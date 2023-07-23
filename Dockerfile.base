# Docker image when built on the official Docker infrastructure.
# They require us to verify the source integrity in some way while making sure that this is a
# reproducible build.
# See https://github.com/docker-library/official-images#image-build
# In order to achieve this, we externally host the rootfs archives and their checksums and then
# just download and verify it in the first stage of this Dockerfile.
# The second stage is for actually configuring the system a little bit.
# Some templating is done in order to allow us to easily build different configurations and to
# allow us to automate the release process.

# Note: Only official DockerHub images are allowed, see https://gitlab.archlinux.org/archlinux/archlinux-docker/-/commit/daa67d18579024947d69a45e6d028c5adb1c8c23
# While we could use archlinux:base it could also break our build process, so we avoid dog fooding here
FROM alpine:3.18 AS verify

RUN apk add --no-cache curl tar zstd

# https://gitlab.archlinux.org/archlinux/archlinux-docker/-/releases/v20230723.0.166908
RUN ROOTFS="$(curl -sOJL -w "%{filename_effective}" "https://gitlab.archlinux.org/archlinux/archlinux-docker/-/package_files/4902/download")" && \
    echo "f97178dae81c61f6bc4c3e68bbdfa756983ce808ecc3022296891545572ee0f1  base-20230723.0.166908.tar.zst" > /tmp/rootfs.tar.sha256 && \
    cat /tmp/rootfs.tar.sha256 && \
    sha256sum -c /tmp/rootfs.tar.sha256 && \
    mkdir /rootfs && \
    tar -C /rootfs --extract --file "${ROOTFS}"

FROM scratch AS root

LABEL org.opencontainers.image.title="Arch Linux base Image"
LABEL org.opencontainers.image.description="Official containerd image of Arch Linux, a simple, lightweight Linux distribution aimed for flexibility."
LABEL org.opencontainers.image.authors="Santiago Torres-Arias <santiago@archlinux.org> (@SantiagoTorres), Christian Rebischke <Chris.Rebischke@archlinux.org> (@shibumi), Justin Kromlinger <hashworks@archlinux.org> (@hashworks)"
LABEL org.opencontainers.image.url="https://gitlab.archlinux.org/archlinux/archlinux-docker/-/blob/master/README.md"
LABEL org.opencontainers.image.documentation="https://wiki.archlinux.org/title/Docker#Arch_Linux"
LABEL org.opencontainers.image.source="https://gitlab.archlinux.org/archlinux/archlinux-docker"
LABEL org.opencontainers.image.licenses="GPL-3.0-or-later"
LABEL org.opencontainers.image.version="20230723.0.166908"
LABEL org.opencontainers.image.revision="301942f9e5995770cb5e4dedb4fe9166afa4806d"
LABEL org.opencontainers.image.created="2023-07-23T00:07:48+00:00"

COPY --from=verify /rootfs/ /

RUN ldconfig && \
    sed -i '/BUILD_ID/a VERSION_ID=20230723.0.166908' /etc/os-release

ENV LANG=C.UTF-8
CMD ["/usr/bin/bash"]
