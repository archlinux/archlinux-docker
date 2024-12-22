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
FROM alpine:3.19 AS verify

RUN apk add --no-cache curl tar zstd

RUN curl -sOJL "https://gitlab.archlinux.org/api/v4/projects/10185/packages/generic/rootfs/20241222.0.291122/multilib-devel-20241222.0.291122.tar.zst" && \
    echo "186b9ee670b714afa95cd7c4cae6d1f95c5ea17e304bdea65ddaffd92a0ac9e6  multilib-devel-20241222.0.291122.tar.zst" > /tmp/sha256sums.txt && \
    sha256sum -c /tmp/sha256sums.txt && \
    mkdir /rootfs && \
    tar -C /rootfs --extract --file multilib-devel-20241222.0.291122.tar.zst

FROM scratch AS root

LABEL org.opencontainers.image.title="Arch Linux multilib-devel Image"
LABEL org.opencontainers.image.description="Official containerd image of Arch Linux, a simple, lightweight Linux distribution aimed for flexibility."
LABEL org.opencontainers.image.authors="Santiago Torres-Arias <santiago@archlinux.org> (@SantiagoTorres), Christian Rebischke <Chris.Rebischke@archlinux.org> (@shibumi), Justin Kromlinger <hashworks@archlinux.org> (@hashworks)"
LABEL org.opencontainers.image.url="https://gitlab.archlinux.org/archlinux/archlinux-docker/-/blob/master/README.md"
LABEL org.opencontainers.image.documentation="https://wiki.archlinux.org/title/Docker#Arch_Linux"
LABEL org.opencontainers.image.source="https://gitlab.archlinux.org/archlinux/archlinux-docker"
LABEL org.opencontainers.image.licenses="GPL-3.0-or-later"
LABEL org.opencontainers.image.version="20241222.0.291122"
LABEL org.opencontainers.image.revision="61cb892bfc251e46f73e716ceb3b903ec4e9e725"
LABEL org.opencontainers.image.created="2024-12-22T00:07:56+00:00"

COPY --from=verify /rootfs/ /

RUN ldconfig && \
    sed -i '/BUILD_ID/a VERSION_ID=20241222.0.291122' /etc/os-release

ENV LANG=C.UTF-8
CMD ["/usr/bin/bash"]
