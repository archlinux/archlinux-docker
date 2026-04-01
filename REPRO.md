# Reproducing the `repro` image

The `repro` image is a bit for bit [reproducible build](https://reproducible-builds.org/)
of the `base` image.  
Note that, to ensure reproducibility, the pacman keys are stripped from this
image, so you're expected to run `pacman-key --init && pacman-key --populate archlinux`
before being able to update the system and install packages via `pacman`.

To reproduce the `repro` image locally, follow the below instructions.

## Dependencies

Install the following Arch Linux packages:

* make
* devtools (for the pacman.conf files)
* git (to fetch the commit/revision number)
* podman
* fakechroot
* fakeroot
* diffoscope (to optionally check the reproducibility of the rootFS)
* diffoci

## Set required environment variables

Prepare the build environment by setting the following environment variables:

* IMAGE_BUILD_DATE: The build date of the `repro` image you want to reproduce.
For instance, if you're aiming to reproduce the `repro-20260331.0.508794` image:
   * `export IMAGE_BUILD_DATE="20260331"`
* IMAGE_BUILD_NUMBER: The build number of the `repro` image you want to reproduce.
For instance, if you're aiming to reproduce the `repro-20260331.0.508794` image:
   * `export IMAGE_BUILD_NUMBER="0.508794"`
* ARCHIVE_SNAPSHOT: The date of the Arch Linux repository archive snaphot to build
the image against. This is based on the `IMAGE_BUILD_DATE`:
   * `export ARCHIVE_SNAPSHOT=$(date -d "${IMAGE_BUILD_DATE} -1 day" +"%Y/%m/%d")`
* SOURCE_DATE_EPOCH: The value to normalize timestamps with during the build.
This is based on the `IMAGE_BUILD_DATE`:
   * `export SOURCE_DATE_EPOCH=$(date -u -d "${IMAGE_BUILD_DATE} 00:00:00" +"%s")`

## Build the rootFS and generate the Dockerfile

From a clone of the [archlinux-docker](https://gitlab.archlinux.org/archlinux/archlinux-docker)
repository, build the rootFS with the required parameters:

```bash
make \
    ARCHIVE_SNAPSHOT="$ARCHIVE_SNAPSHOT" \
    SOURCE_DATE_EPOCH="$SOURCE_DATE_EPOCH" \
    $PWD/output/Dockerfile.repro
```

The following built artifact will be located in `$PWD/output`:

* repro.tar.zst (the rootFS)
* repro.tar.zst.SHA256 (sha256 hash of the rootFS)
* Dockerfile.repro (the generated Dockerfile)

## Optional - Check the rootFS reproducibility

At that point, if the above artifacts built for the image you're aiming to reproduce
are still available for download from the
[archlinux-docker pipelines](https://gitlab.archlinux.org/archlinux/archlinux-docker/-/pipelines)
artifacts, you can optionally compare the content of the `repro.tar.zst.SHA256`
file from the pipeline to the one generated during the above local build (which
should be the same, indicating that the rootFS has been successfully reproduced).

Additionally, you can check differences between the `repro.tar.zst` tarball from
the pipeline and the one built during your local build with `diffoscope`:  
`diffoscope /tmp/repro.tar.zst $PWD/output/repro.tar.zst` *(where `/tmp/repro.tar.zst`
is the rootFS tarball downloaded from the pipeline and `$PWD/output/repro.tar.zst` is
the rootFS tarball you just built)*.  
This should show no difference, acting as additional indicator that the rootFS has been 
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
    -t "archlinux-docker:repro-${IMAGE_BUILD_DATE}.${IMAGE_BUILD_NUMBER}" \
    "$PWD/output"
```

The built image will be accessible in your local podman container storage under the name:
`localhost/archlinux-docker:repro-${IMAGE_BUILD_DATE}.${IMAGE_BUILD_NUMBER}`.

## Check the image reproducibility

Pull the image you're aiming at reproducing from Docker Hub:
`podman pull docker.io/archlinux/archlinux:repro-${IMAGE_BUILD_DATE}.${IMAGE_BUILD_NUMBER}`

Compare the digest of the image pulled from Docker Hub to the digest of the image you built
locally:

```bash
podman inspect --format '{{.Digest}}' docker.io/archlinux/archlinux:repro-${IMAGE_BUILD_DATE}.${IMAGE_BUILD_NUMBER}
podman inspect --format '{{.Digest}}' localhost/archlinux-docker:repro-${IMAGE_BUILD_DATE}.${IMAGE_BUILD_NUMBER}
```

Both digests should be identical, indicating that the image has been successfully reproduced.

Additionally, you can check difference between the image pulled from Docker Hub and
the image you built locally with `diffoci`:

```bash
diffoci diff --semantic --verbose podman://docker.io/archlinux/archlinux:repro-${IMAGE_BUILD_DATE}.${IMAGE_BUILD_NUMBER} podman://localhost/archlinux-docker:repro-${IMAGE_BUILD_DATE}.${IMAGE_BUILD_NUMBER}
```

This should show no difference, acting as additional indicator that the image has been
successfully reproduced *(see the following section about the `--semantic` flag requirement)*.

### Note about `diffoci` requiring the `--semantic` flag (a.k.a "non-strict" mode)

Docker / Podman does not allow to have two images with the same name & tag combination stored
locally, [preventing them to be checked with `diffoci` as-is](https://github.com/reproducible-containers/diffoci/issues/74).
To work around this limitation, one of the two image has to be named differently, whether by
setting a different name / tag combination at build time or by renaming it post-build
with e.g. `podman tag`.

However, the image name & tag combination is automatically reported (and updated in the case
of a renaming) in the image annotations / metadata and it's apparently not possible to fully overwrite
it during build or update it post-build in a straightforward way.  
This introduces unavoidable non-determinism
in the image annotations / metadata that `diffoci` will report by default.  
See for instance the following `diffoci` output (with the reported difference being introduced by
using `podman tag` to "rename" one of the images with the "-orig" suffix, in order to avoid name collision):

```
Event: "DescriptorMismatch" (field "Annotations")
  map[string]string{
  	"io.containerd.image.name": strings.Join({
  		"registry.archlinux.org/archlinux/archlinux-docker:repro-repro",
- 		"-orig",
  	}, ""),
- 	"org.opencontainers.image.ref.name": "repro-repro-orig",
+ 	"org.opencontainers.image.ref.name": "repro-repro",
  }
```

Given that it's currently not possible to have two images with the same name & tag
combination stored locally and that it's also not possible to "normalize" the related
annotations / metadata during (or after) the build, we are not aware of a way to get a
fully successful `diffoci` output in default / strict mode (i.e., with *absolutely* no
reported differences).  
This is why we are "forced" to run `diffoci` with the `--semantic` flag
([a.k.a "non-strict" mode](https://github.com/reproducible-containers/diffoci?tab=readme-ov-file#non-strict-aka-semantic-mode)),
which ignores some attributes, including image name annotations.

While having to run `diffoci` with the `--semantic` flag (for the lack of another option)
just to workaround this image naming technical constraint is unfortunate, we can attest that:

* This limitation is specific to metadata handling in container tooling and does not
affect the actual filesystem contents or runtime behavior of the image.
* The reported difference in the image name annotations is (or is supposed to be, at least) the **only**
difference being reported when comparing the two images.
* These image name annotations are not part of the hashed object when generating the image digest,
meaning that this difference does not go in the way of digest equality between the two images (allowing
us to claim bit for bit reproducibility regardless).
