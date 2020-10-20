FROM archlinux:latest AS verify
SHELL ["/bin/bash", "-c"]
RUN ROOTFS="$(curl --continue-at - --remote-name --write-out "%{filename_effective}" https://gitlab.archlinux.org/archlinux/archlinux-docker/uploads/93e7d135858872fa3aa626a5fe2719ea/base-20201020.6556.tar.xz)" && \
    sha256sum -c <<< "c980d72136d9db1d82be7844a09341f0ccfc211a2a0ac94d1c471d9aa4f2fba3  base-20201020.6556.tar.xz" && \
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
