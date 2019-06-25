FROM scratch
ADD archlinux.tar.xz /
ENV LANG=en_US.UTF-8
CMD ["/usr/bin/bash"]
