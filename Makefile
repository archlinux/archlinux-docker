OCITOOL=podman # or docker
BUILDDIR=$(shell pwd)/build
OUTPUTDIR=$(shell pwd)/output

.PHONY: clean
clean:
	rm -rf $(BUILDDIR) $(OUTPUTDIR)

$(OUTPUTDIR)/base.tar.zst:
	scripts/make-rootfs.sh base $(BUILDDIR) $(OUTPUTDIR)

$(OUTPUTDIR)/base-devel.tar.zst:
	scripts/make-rootfs.sh base-devel $(BUILDDIR) $(OUTPUTDIR)

$(OUTPUTDIR)/Dockerfile.base: $(OUTPUTDIR)/base.tar.zst
	scripts/make-dockerfile.sh base $(OUTPUTDIR)

$(OUTPUTDIR)/Dockerfile.base-devel: $(OUTPUTDIR)/base-devel.tar.zst
	scripts/make-dockerfile.sh base-devel $(OUTPUTDIR)

# The following is for local builds only, it is not used by the CI/CD pipeline

.PHONY: image-base
image-base: $(OUTPUTDIR)/Dockerfile.base
	${OCITOOL} build -f $(OUTPUTDIR)/Dockerfile.base -t archlinux/archlinux:base $(OUTPUTDIR)

.PHONY: image-base-devel
image-base-devel: $(OUTPUTDIR)/Dockerfile.base-devel
	${OCITOOL} build -f $(OUTPUTDIR)/Dockerfile.base-devel -t archlinux/archlinux:base-devel $(OUTPUTDIR)
