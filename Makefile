DOCKER_USER := 'pierres'
DOCKER_IMAGE := 'archlinux'

rootfs:
	$(eval TMPDIR := $(shell mktemp -d))
	pacstrap -C /usr/share/devtools/pacman-extra.conf -c -d -G -M $(TMPDIR) $(shell cat packages)
	cp -rp --backup --suffix=.pacnew rootfs/* $(TMPDIR)/
	arch-chroot $(TMPDIR) locale-gen
	arch-chroot $(TMPDIR) pacman-key --init
	arch-chroot $(TMPDIR) pacman-key --populate archlinux
	tar --numeric-owner --xattrs --acls --exclude-from=exclude -C $(TMPDIR) -c . -f archlinux.tar
	rm -rf $(TMPDIR)

docker-image: rootfs
	docker build -t $(DOCKER_USER)/$(DOCKER_IMAGE) .

docker-push: docker-image
	docker login -u $(DOCKER_USER)
	docker push $(DOCKER_USER)/$(DOCKER_IMAGE)

.PHONY: rootfs docker-image docker-push
