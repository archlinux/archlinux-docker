DOCKER_USER:=pierres
BUILDDIR=build
PWD=$(shell pwd)

.PHONY: hooks
hooks:
	mkdir -p alpm-hooks/usr/share/libalpm/hooks
	find /usr/share/libalpm/hooks -exec ln -sf /dev/null $(PWD)/alpm-hooks{} \;

.PHONY: rootfs-base
rootfs-base: hooks
	mkdir -vp $(BUILDDIR)/var/lib/pacman/
	cp /usr/share/devtools/pacman-extra.conf rootfs/etc/pacman.conf
	cat pacman-conf.d-noextract.conf >> rootfs/etc/pacman.conf
	fakechroot -- fakeroot -- pacman -Sy -r $(BUILDDIR) \
		--noconfirm --dbpath $(PWD)/$(BUILDDIR)/var/lib/pacman \
		--config rootfs/etc/pacman.conf \
		--noscriptlet \
		--hookdir $(PWD)/alpm-hooks/usr/share/libalpm/hooks/ base
	cp --recursive --preserve=timestamps --backup --suffix=.pacnew rootfs/* $(BUILDDIR)/

	# remove passwordless login for root (see CVE-2019-5021 for reference)
	sed -i -e 's/^root::/root:!:/' "$(BUILDDIR)/etc/shadow"

	# fakeroot to map the gid/uid of the builder process to root
	# fixes #22
	fakeroot -- tar --numeric-owner --xattrs --acls --exclude-from=exclude -C $(BUILDDIR) -c . -f base.tar
	rm -rf $(BUILDDIR) alpm-hooks

.PHONY: rootfs-base-devel
rootfs-base-devel: hooks
	mkdir -vp $(BUILDDIR)/var/lib/pacman/
	cp /usr/share/devtools/pacman-extra.conf rootfs/etc/pacman.conf
	cat pacman-conf.d-noextract.conf >> rootfs/etc/pacman.conf
	fakechroot -- fakeroot -- pacman -Sy -r $(BUILDDIR) \
		--noconfirm --dbpath $(PWD)/$(BUILDDIR)/var/lib/pacman \
		--config rootfs/etc/pacman.conf \
		--noscriptlet \
		--hookdir $(PWD)/alpm-hooks/usr/share/libalpm/hooks/ base base-devel
	cp --recursive --preserve=timestamps --backup --suffix=.pacnew rootfs/* $(BUILDDIR)/

	# remove passwordless login for root (see CVE-2019-5021 for reference)
	sed -i -e 's/^root::/root:!:/' "$(BUILDDIR)/etc/shadow"

	# fakeroot to map the gid/uid of the builder process to root
	# fixes #22
	fakeroot -- tar --numeric-owner --xattrs --acls --exclude-from=exclude -C $(BUILDDIR) -c . -f base-devel.tar
	rm -rf $(BUILDDIR) alpm-hooks

base.tar.xz: rootfs-base
	xz -9 -T0 -f base.tar

base-devel.tar.xz: rootfs-base-devel
	xz -9 -T0 -f base-devel.tar

.PHONY: docker-image-base
docker-image-base: base.tar.xz
	unxz base.tar.xz
	sed "s/TEMPLATE_LOCATION_HERE/base.tar/" Dockerfile.template > Dockerfile.base
	docker build -f Dockerfile.base -t archlinux/archlinux:base .

.PHONY: docker-image-base-devel
docker-image-base-devel: base-devel.tar.xz
	unxz base-devel.tar.xz
	sed "s/TEMPLATE_LOCATION_HERE/base-devel.tar/" Dockerfile.template > Dockerfile.base-devel
	docker build -f Dockerfile.base-devel -t archlinux/archlinux:base-devel .

.PHONY: docker-push-base
docker-push-base:
	docker login -u $(DOCKER_USER)
	docker push archlinux/archlinux:base

.PHONY: docker-push-base-devel
docker-push-base-devel:
	docker login -u $(DOCKER_USER)
	docker push archlinux/archlinux:base-devel
