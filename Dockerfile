FROM scratch
ADD archlinux.tar.xz /

# manually run all alpm hooks that can't be run inside the fakechroot
RUN ldconfig && update-ca-trust && locale-gen
RUN sh -c 'ls usr/lib/sysusers.d/*.conf | /usr/share/libalpm/scripts/systemd-hook sysusers '

# initialize the archlinux keyring, but discard any private key that may be shipped.
RUN pacman-key --init && pacman-key --populate archlinux && rm -rf etc/pacman.d/gnupg/{openpgp-revocs.d/,private-keys-v1.d/,pubring.gpg~,gnupg.S.}*

ENV LANG=en_US.UTF-8
CMD ["/usr/bin/bash"]
