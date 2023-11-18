# Arch Linux OCI Images

[![pipeline status][pipeline]][commits]

Arch Linux provides OCI-Compliant container images in multiple repositories:
* [Weekly in the official DockerHub library][hub-arch]:
`podman pull docker.io/library/archlinux:latest` or `docker pull archlinux:latest`
* [Daily in our DockerHub repository][hub-containers]:
`podman pull docker.io/archlinux/archlinux:latest` or `docker pull archlinux/archlinux:latest`
* [Daily in our quay.io repository][quay-containers]:
`podman pull quay.io/archlinux/archlinux:latest` or `docker pull quay.io/archlinux/archlinux:latest`
* [Daily in our ghcr.io repository][ghcr-containers]:
`podman pull ghcr.io/archlinux/archlinux:latest` or `docker pull ghcr.io/archlinux/archlinux:latest`

Three versions of the image are provided: `base` (approx. 150 MiB), `base-devel`
(approx. 260 MiB) and `multilib-devel` (approx. 300MiB) containing the
respective meta package. All of them are available as
tags with `latest` pointing to `base`. Additionally, images are tagged with their
date and build job number, f.e. `base-devel-20201118.0.9436`.

While the images are regularly kept up to date it is strongly recommended
running `pacman -Syu` right after starting a container due to the rolling
release nature of Arch Linux.

All the images, with the exception of the official DockerHub library image, are
signed by using [cosign's keyless signing][openid-signing]. The images can be
verified with one of the following commands:
```sh
$ cosign verify docker.io/archlinux/archlinux:latest --certificate-identity-regexp="https://gitlab\.archlinux\.org/archlinux/archlinux-docker//\.gitlab-ci\.yml@refs/tags/v[0-9]+\.0\.[0-9]+" --certificate-oidc-issuer=https://gitlab.archlinux.org
$ cosign verify quay.io/archlinux/archlinux:latest --certificate-identity-regexp="https://gitlab\.archlinux\.org/archlinux/archlinux-docker//\.gitlab-ci\.yml@refs/tags/v[0-9]+\.0\.[0-9]+" --certificate-oidc-issuer=https://gitlab.archlinux.org
$ cosign verify ghcr.io/archlinux/archlinux:latest --certificate-identity-regexp="https://gitlab\.archlinux\.org/archlinux/archlinux-docker//\.gitlab-ci\.yml@refs/tags/v[0-9]+\.0\.[0-9]+" --certificate-oidc-issuer=https://gitlab.archlinux.org
```

## Principles
* Provide the Arch experience in a Docker image
* Provide the simplest but complete image to `base`, `base-devel` and
`multilib-devel` on a regular basis
* `pacman` needs to work out of the box
* All installed packages have to be kept unmodified

>>>
     ⚠️⚠️⚠️ NOTE: For Security Reasons, these images strip the pacman lsign key.
     This is because the same key would be spread to all containers of the same
     image, allowing for malicious actors to inject packages (via, for example,
     a man-in-the-middle). In order to create a lsign-key run `pacman-key
     --init` on the first execution, but be careful to not redistribute that
     key.⚠️⚠️⚠️
>>>

## Building your own image

[This repository][self] contains all scripts and files needed to create an OCI
image for Arch Linux.

### Dependencies
Install the following Arch Linux packages:

* make
* devtools (for the pacman.conf files)
* git (to fetch the commit/revision number)
* podman
* fakechroot
* fakeroot

Make sure your user can directly interact with Podman (i.e. `podman info` works).

### Usage
There are multiple `make image-XXX` targets, where each creates the
respective `archlinux:XXX` image based on the corresponding meta package.
Currently those include `base`, `base-devel` and `multilib-devel`.

## Pipeline

### Daily releases

Daily images are build with scheduled [GitLab CI][in-tree-CI] using our own
runner infrastructure. Initially root filesystem archives are constructed and
provided in our [package registry][self-package-registry]. The released
multi-stage Dockerfile downloads those archives and verifies their integrity
before unpacking it into an OCI image layer. Images are built using
[podman](https://podman.io/), which also publishes them to our external
repositories.

### Weekly releases

Weekly releases to the official DockerHub library use the same pipeline as
daily builds. Updates are provided as automatic [pull requests][github-docker-prs]
to the [official-images library][github-docker-arch], whose GitHub pipeline will
build the images using our provided rootfs archives and Dockerfiles.

### Development

Changes in Git feature branches are built and tested using the pipeline as well.
Development images are uploaded to our
[GitLab Container Registry][self-container-registry].

[pipeline]: https://gitlab.archlinux.org/archlinux/archlinux-docker/badges/master/pipeline.svg
[commits]: https://gitlab.archlinux.org/archlinux/archlinux-docker/-/commits/master

[hub-arch]: https://hub.docker.com/_/archlinux
[hub-containers]: https://hub.docker.com/r/archlinux/archlinux
[quay-containers]: https://quay.io/repository/archlinux/archlinux
[ghcr-containers]: https://github.com/archlinux/archlinux-docker/pkgs/container/archlinux

[openid-signing]: (https://docs.sigstore.dev/cosign/openid_signing/)

[self]: https://gitlab.archlinux.org/archlinux/archlinux-docker

[in-tree-CI]: https://gitlab.archlinux.org/archlinux/archlinux-docker/-/blob/master/.gitlab-ci.yml
[self-package-registry]: https://gitlab.archlinux.org/archlinux/archlinux-docker/-/packages

[github-docker-prs]: https://github.com/docker-library/official-images/pulls?q=is%3Apr+archlinux+is%3Aclosed+author%3Aarchlinux-github
[github-docker-arch]: https://github.com/docker-library/official-images/blob/master/library/archlinux

[self-container-registry]: https://gitlab.archlinux.org/archlinux/archlinux-docker/container_registry
