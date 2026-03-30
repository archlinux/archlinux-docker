OCITOOL=podman # or docker
BUILDDIR=$(shell pwd)/build
OUTPUTDIR=$(shell pwd)/output
ARCHIVE_SNAPSHOT=$(shell date -d "-1 day" +"%Y/%m/%d")
SOURCE_DATE_EPOCH=$(shell date -u -d "$(echo "$ARCHIVE_SNAPSHOT")" +"%s")

.PHONY: clean
clean:
	rm -rf $(BUILDDIR) $(OUTPUTDIR)

.PRECIOUS: $(OUTPUTDIR)/%.tar.zst
$(OUTPUTDIR)/%.tar.zst:
	scripts/make-rootfs.sh $(*) $(BUILDDIR) $(OUTPUTDIR) $(ARCHIVE_SNAPSHOT) $(SOURCE_DATE_EPOCH)

.PRECIOUS: $(OUTPUTDIR)/Dockerfile.%
$(OUTPUTDIR)/Dockerfile.%: $(OUTPUTDIR)/%.tar.zst
	scripts/make-dockerfile.sh "$(*).tar.zst" $(*) $(OUTPUTDIR) "true" "Dev" $(SOURCE_DATE_EPOCH)

# The following is for local builds only, it is not used by the CI/CD pipeline

all: image-base image-base-devel image-multilib-devel image-repro
image-%: $(OUTPUTDIR)/Dockerfile.%
	${OCITOOL} build -f $(OUTPUTDIR)/Dockerfile.$(*) -t archlinux/archlinux:$(*) $(OUTPUTDIR)
