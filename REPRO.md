# Reproducing a `repro` image locally

The `repro` image provides a bit for bit [reproducible build](https://reproducible-builds.org)
of the `base` image.

Note that, to ensure reproducibility, the pacman keys are stripped from this
image, so you're expected to run `pacman-key --init && pacman-key --populate archlinux`
before being able to update the system and install packages via `pacman` when using this image.

To reproduce the `repro` image locally, follow the below instructions.

## Disclaimer

Reproducible builds [expect the same build environment across builds](https://reproducible-builds.org/docs/definition/).

While it *should* be fine in most cases, this means we cannot guarantee that you will always be able
to successfully reproduce a specific image locally over time.

Technically speaking, the older the image you're trying to reproduce is, the more chance there is
to have more or less significant differences between your build environment
and the one used to build the original image (for instance in terms of packages versions).  
Such differences can affect the build (and the resulting artifacts). Please note that failing to
reproduce an image locally does not necessarily mean that it isn't reproducible per se, but can
just be the result of significant enough differences between your build environment and the one
used to build the original image.

You can avoid (or mitigate) eventual issues due to such differences by restoring all packages
of your build environment to the build date of the original image (see the [related instructions
from the Arch Wiki](https://wiki.archlinux.org/title/Arch_Linux_Archive#Restore_all_packages_to_a_specific_date)).

## Dependencies

Install the following Arch Linux packages:

* make
* devtools
* git
* podman
* fakechroot
* fakeroot
* diffoscope (to optionally check the reproducibility of the rootFS)
* diffoci

## Prepare the build environment

Prepare the build environment by setting the following environment variables:

* `BUILD_VERSION`: The build version of the `repro` image you want to reproduce.
For instance, if you're aiming to reproduce the `repro-20260331.0.508794` image:

```bash
export BUILD_VERSION="20260331.0.508794"
```

* `ARCHIVE_SNAPSHOT`: The date of the Arch Linux repository archive snaphot to build
the image against. This is based on the date included in the image's `BUILD_VERSION`:

```bash
export ARCHIVE_SNAPSHOT=$(date -u -d "${BUILD_VERSION%%.*} -1 day" +"%Y/%m/%d")
```

* `SOURCE_DATE_EPOCH`: The value to normalize timestamps with during the build.
This is based on the date included in the image's `BUILD_VERSION`:

```bash
export SOURCE_DATE_EPOCH=$(date -u -d "${BUILD_VERSION%%.*} 00:00:00" +"%s")
```

Then pull the original image you're aiming to reproduce and set its revision value in your environment (needed to correctly set the revision annotation in the Dockerfile):

```bash
podman pull docker.io/archlinux/archlinux:repro-$BUILD_VERSION
export CI_COMMIT_SHA=$(podman inspect --format '{{ index .Config.Labels "org.opencontainers.image.revision" }}' archlinux/archlinux:repro-$BUILD_VERSION)
```

Finally, clone the [archlinux-docker](https://gitlab.archlinux.org/archlinux/archlinux-docker)
repository and move into it:

```bash
git clone https://gitlab.archlinux.org/archlinux/archlinux-docker.git
cd archlinux-docker
```

Note that all the following instructions assume that you are at the root of the
archlinux-docker repository cloned above.

## Build the rootFS and generate the Dockerfile

Build the rootFS with the required parameters:

```bash
make \
    ARCHIVE_SNAPSHOT="$ARCHIVE_SNAPSHOT" \
    SOURCE_DATE_EPOCH="$SOURCE_DATE_EPOCH" \
    $PWD/output/Dockerfile.repro

scripts/make-dockerfile.sh repro.tar.zst repro output/ "true" "repro" "$SOURCE_DATE_EPOCH"
```

The following resulting artifacts will be located in `$PWD/output`:

* repro.tar.zst (the rootFS)
* repro.tar.zst.SHA256 (sha256 hash of the rootFS)
* Dockerfile.repro (the generated Dockerfile)

## Optional - Check the rootFS reproducibility

At that point, if the artifacts built for the image you're aiming to reproduce
are still available for download from the rootfs stage of the corresponding
[archlinux-docker pipeline](https://gitlab.archlinux.org/archlinux/archlinux-docker/-/pipelines)
, you can optionally compare the content of the `repro.tar.zst.SHA256`
file from the pipeline to the one generated during your local build (which
should be the same, indicating that the rootFS has been successfully reproduced).

Additionally, you can check differences between the `repro.tar.zst` tarball from
the pipeline and the one built during your local build with `diffoscope`
*(where `/tmp/repro.tar.zst` is the rootFS tarball downloaded from the pipeline and
`$PWD/output/repro.tar.zst` is the rootFS tarball built during your local build in the following example)*:

```bash
diffoscope /tmp/repro.tar.zst $PWD/output/repro.tar.zst
```

This should return no difference, acting as additional indicator that the rootFS has been 
successfully reproduced.

## Build the image

You can now (re)build the image against the rootFS and the Dockerfile generated in the previous step.  
To do so, build the image with the required parameters:

```bash
podman build \
    --no-cache \
    --source-date-epoch=$SOURCE_DATE_EPOCH \
    --rewrite-timestamp \
    -f "$PWD/output/Dockerfile.repro" \
    -t "archlinux:repro-$BUILD_VERSION" \
    "$PWD/output"
```

The built image will be accessible in your local podman container storage under the name:
`localhost/archlinux:repro-$BUILD_VERSION`.

## Check the image reproducibility

Compare the digest of the original image pulled from Docker Hub to the digest of the image you built
locally:

```bash
podman inspect --format '{{.Digest}}' docker.io/archlinux/archlinux:repro-$BUILD_VERSION
podman inspect --format '{{.Digest}}' localhost/archlinux:repro-$BUILD_VERSION
```

Both digests should be identical, indicating that the image has been successfully reproduced.

Additionally, you can check difference between the image pulled from Docker Hub and
the image you built locally with `diffoci`:

```bash
diffoci diff --ignore-image-name --verbose podman://docker.io/archlinux/archlinux:repro-$BUILD_VERSION podman://localhost/archlinux:repro-$BUILD_VERSION
```

This should show no difference, acting as additional indicator that the image has been
successfully reproduced *(see the following section about the `--ignore-image-name` flag requirement)*.

### Note about the necessity of the `--ignore-image-name` flag with `diffoci`

Docker / Podman does not allow to have two images with the same name & tag combination stored
locally, [making it impossible to compare two images with the same name with
`diffoci`](https://github.com/reproducible-containers/diffoci/issues/74).
To work around this limitation, one of the two image has to be named differently, whether by
setting a different name / tag combination at build time (as done in this guide) or by renaming
it post-build with e.g. `podman tag`.

However, the image name & tag combination is automatically reported (and updated in the case
of a renaming) in the image annotations and it's not possible to fully overwrite
it during build or update it post-build in a straightforward way.  
This unavoidably introduces non-deterministic data in the image name annotations
that `diffoci` will systematically report by default.  
See for instance the following `diffoci` output reporting a difference in the image name annotation:

```
Event: "DescriptorMismatch" (field "Annotations")
  map[string]string{
        "io.containerd.image.name": strings.Join({
-               "docker.io/archlinux/archlinux:repro-20260331.0.508794",
+               "localhost/archlinux:repro-20260331.0.508794",
        }, ""),
```

Given that it's currently not possible to have two images with the same name & tag
combination stored locally and that it's also not possible to "normalize" the related
annotations metadata during (or after) the build, we are currently [forced to ignore those with
the `--ignore-image-name` flag](https://github.com/reproducible-containers/diffoci/issues/266)
to workaround this technical constraint.

Regardless, we can attest that:

* This limitation is specific to metadata handling in container tooling and does not
affect the actual filesystem contents or runtime behavior of the image.
* The reported difference in the image name annotation when running `diffoci` without the `--ignore-image-name` flag
is (or is supposed to be, at least) the **only** difference being reported when comparing the two images.
* The image name annotation metadata are not part of the hashed object when generating the image digest,
meaning that this difference does not prevent digest equality between the two images (allowing
us to claim bit for bit reproducibility regardless).
