FROM archlinux/base
ADD packages /
ADD exclude /
ADD rootfs /rootfs.files
RUN mkdir /rootfs && \
    pacman -Syu --noconfirm base arch-install-scripts && \
    pacstrap -C /usr/share/devtools/pacman-extra.conf -c -d -G -M /rootfs $(cat /packages) && \
    cp --recursive --preserve=timestamps --backup --suffix=.pacnew /rootfs.files/* /rootfs/ && \
    cd /rootfs && \
    eval rm -rfv $(cat /exclude)

FROM scratch
COPY --from=0 /rootfs /
RUN locale-gen && pacman-key --init && pacman-key --populate archlinux
ENV LANG=en_US.UTF-8
CMD ["/usr/bin/bash"]
