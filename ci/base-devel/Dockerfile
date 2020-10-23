# We're using a multistage Docker build here in order to allow us to release a self-verifying
# Docker image when built on the official Docker infrastructure.
# They require us to verify the source integrity in some way while making sure that this is a
# reproducible build.
# See https://github.com/docker-library/official-images#image-build
# In order to achieve this, we externally host the rootfs archives and their checksums and then
# just download and verify it in the first stage of this Dockerfile.
# The second stage is for actually configuring the system a little bit.
# Some templating is done in order to allow us to easily build different configurations and to
# allow us to automate the releaes process.
FROM archlinux:latest AS verify
SHELL ["/bin/bash", "-c"]
RUN ROOTFS="$(curl --continue-at - --remote-name --write-out "%{filename_effective}" https://gitlab.archlinux.org/api/v4/projects/10185/packages/generic/rootfs/20201023.0.6809/base-devel-20201023.0.6809.tar.xz)" && \
    sha256sum -c <<< "3ddaf0bbdd144c7517e1e03956f952368ade55ec2ad0ae3c690b95eab1bfd356  base-devel-20201023.0.6809.tar.xz" && \
    mkdir /rootfs && \
    tar -C /rootfs --extract --auto-compress --file "${ROOTFS}"

FROM scratch AS root
COPY --from=verify /rootfs/ /

# manually run all alpm hooks that can't be run inside the fakechroot
RUN ldconfig && update-ca-trust && locale-gen
RUN sh -c 'ls usr/lib/sysusers.d/*.conf | /usr/share/libalpm/scripts/systemd-hook sysusers '

# update /etc/os-release
RUN ln -s /usr/lib/os-release /etc/os-release

# initialize the archlinux keyring, but discard any private key that may be shipped.
RUN pacman-key --init && pacman-key --populate archlinux && bash -c "rm -rf etc/pacman.d/gnupg/{openpgp-revocs.d/,private-keys-v1.d/,pubring.gpg~,gnupg.S.}*"

ENV LANG=en_US.UTF-8
CMD ["/usr/bin/bash"]
