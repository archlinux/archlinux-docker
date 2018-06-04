FROM scratch
ADD archlinux.tar /

# manually run all alpm hooks that can't be run inside the fakechroot
RUN ldconfig && update-ca-trust && locale-gen && /usr/share/libalpm/scripts/systemd-hook sysusers && pacman-key --init && pacman-key --populate archlinux 

ENV LANG=en_US.UTF-8
CMD ["/usr/bin/bash"]
