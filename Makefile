DOCKER_USER := 'pierres'
DOCKER_IMAGE := 'archlinux'

rootfs:
	$(eval TMPDIR := $(shell mktemp -d))
	pacstrap -C /usr/share/devtools/pacman-extra.conf -c -d -G -M $(TMPDIR) $(shell cat packages)
	cp --recursive --preserve=timestamps --backup --suffix=.pacnew rootfs/* $(TMPDIR)/
	arch-chroot $(TMPDIR) locale-gen
	arch-chroot $(TMPDIR) pacman-key --init
	arch-chroot $(TMPDIR) pacman-key --populate archlinux
	tar --numeric-owner --xattrs --acls --exclude-from=exclude -C $(TMPDIR) -c . -f archlinux.tar
	rm -rf $(TMPDIR)

docker-image: rootfs
	docker build -t $(DOCKER_USER)/$(DOCKER_IMAGE) .

docker-image-test: docker-image
	# FIXME: /etc/mtab is hidden by docker so the stricter -Qkk fails
	docker run --rm $(DOCKER_USER)/$(DOCKER_IMAGE) sh -c "/usr/bin/pacman -Sy && /usr/bin/pacman -Qqk"
	docker run --rm $(DOCKER_USER)/$(DOCKER_IMAGE) sh -c "/usr/bin/pacman -Syu --noconfirm docker && docker -v"
	# Ensure that the image does not include a private key
	! docker run --rm pierres/archlinux pacman-key --lsign-key pierre@archlinux.de

ci-test:
	docker run --rm --privileged -v /var/run/docker.sock:/var/run/docker.sock -v $(PWD):/app -w /app pierres/archlinux \
		sh -c 'pacman -Sy --noconfirm make devtools docker && make docker-image-test'

docker-push: docker-image-test
	docker login -u $(DOCKER_USER)
	docker push $(DOCKER_USER)/$(DOCKER_IMAGE)

.PHONY: rootfs docker-image docker-image-test docker-push
