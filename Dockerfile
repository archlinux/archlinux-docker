FROM scratch
ADD archlinux.tar /
RUN locale-gen
RUN pacman-key --init && pacman-key --populate archlinux
ENV LANG=en_US.UTF-8
CMD ["/usr/bin/bash"]
