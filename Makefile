OCITOOL=podman # or docker
BUILDDIR=$(shell pwd)/build
REPRO_BUILDDIR=$(shell pwd)/repro-build
OUTPUTDIR=$(shell pwd)/output
REPRO_OUTPUTDIR=$(shell pwd)/repro-output
ARCHIVE_SNAPSHOT=$(shell date -d "-1 day" +"%Y/%m/%d")
SOURCE_DATE_EPOCH=$(shell date -u -d "$(echo "$ARCHIVE_SNAPSHOT")" +"%s")

.PHONY: clean
clean:
	rm -rf $(BUILDDIR) $(REPRO_BUILDDIR) $(OUTPUTDIR) $(REPRO_OUTPUTDIR)

.PRECIOUS: $(OUTPUTDIR)/%.tar.zst
$(OUTPUTDIR)/%.tar.zst:
	scripts/make-rootfs.sh $(*) $(BUILDDIR) $(OUTPUTDIR) $(ARCHIVE_SNAPSHOT) $(SOURCE_DATE_EPOCH)

.PRECIOUS: $(OUTPUTDIR)/Dockerfile.%
$(OUTPUTDIR)/Dockerfile.%: $(OUTPUTDIR)/%.tar.zst
	scripts/make-dockerfile.sh "$(*).tar.zst" $(*) $(OUTPUTDIR) "true" "Dev"

# The following aims to rebuild a "repro" tagged image and verify the reproducibility status

repro:
	scripts/make-repro.sh $(*) $(OUTPUTDIR) $(REPRO_BUILDDIR) $(REPRO_OUTPUTDIR) $(ARCHIVE_SNAPSHOT) $(SOURCE_DATE_EPOCH)

# The following is for local builds only, it is not used by the CI/CD pipeline

all: image-base image-base-devel image-multilib-devel image-repro
image-%: $(OUTPUTDIR)/Dockerfile.%
	${OCITOOL} build -f $(OUTPUTDIR)/Dockerfile.$(*) -t archlinux/archlinux:$(*) $(OUTPUTDIR)
