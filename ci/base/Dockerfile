FROM archlinux:latest AS verify
SHELL ["/bin/bash", "-c"]
RUN ROOTFS="$(curl --continue-at - --remote-name --write-out "%{filename_effective}" https://gitlab.archlinux.org/archlinux/archlinux-docker/uploads/43f8631c144b0406b5bd1a160241ebb6/base-20201020.6383.tar.xz)" && \
    sha256sum -c <<< "7993f11890d929bc324585754ab52ecf35fb9f905ab7c10e877b67e9083e83a5  base-20201020.6383.tar.xz" && \
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
