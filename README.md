# Arch Linux OCI Images

[![pipeline status](https://gitlab.archlinux.org/archlinux/archlinux-docker/badges/master/pipeline.svg)](https://gitlab.archlinux.org/archlinux/archlinux-docker/-/commits/master)

Arch Linux provides OCI-Compliant container images in multiple repositories:
* [Weekly in the official DockerHub library](https://hub.docker.com/_/archlinux): `podman pull docker.io/library/archlinux:latest` or `docker pull archlinux:latest`
* [Daily in our DockerHub repository](https://hub.docker.com/r/archlinux/archlinux): `podman pull docker.io/archlinux/archlinux:latest` or `docker pull archlinux/archlinux:latest`
* [Daily in our Quay.io repository](https://quay.io/repository/archlinux/archlinux): `podman pull quay.io/archlinux/archlinux:latest` or `docker pull quay.io/archlinux/archlinux:latest`

Two versions of the image are provided: `base` (approx. 150 MiB) and `base-devel` (approx. 260 MiB), containing the respective meta package / package group. Both are available as tags with `latest` pointing to `base`. Additionally, images are tagged with their date and build job number, f.e. `base-devel-20201118.0.9436`.

While the images are regularly kept up to date it is strongly recommended running `pacman -Syu` right after starting a container due to the rolling release nature of Arch Linux.

## Principles
* Provide the Arch experience in a Docker image
* Provide the simplest but complete image to `base` and `base-devel` on a regular basis
* `pacman` needs to work out of the box
* All installed packages have to be kept unmodified

>>>
     ⚠️⚠️⚠️ NOTE: For Security Reasons, these images strip the pacman lsign key.
     This is because the same key would be spread to all containers of the same
     image, allowing for malicious actors to inject packages (via, for example,
     a man-in-the-middle). In order to create an lsign-key run `pacman-key
     --init` on the first execution, but be careful to not redistribute that
     key.⚠️⚠️⚠️
>>>

## Building your own image

[This repository](https://gitlab.archlinux.org/archlinux/archlinux-docker) contains all scripts and files needed to create an OCI image for Arch Linux.

### Dependencies
Install the following Arch Linux packages:

* make
* devtools
* docker
* fakechroot
* fakeroot

Make sure your user can directly interact with Docker (i.e. `docker info` works).

### Usage
Run `make docker-image-base` to build the `archlinux:base` image with the
`base` meta package installed. You can also run `make docker-image-base-devel` to
build the image `archlinux:base-devel` which additionally has the `base-devel` group installed.

## Pipeline

### Daily releases

Daily images are build with scheduled [GitLab CI](https://gitlab.archlinux.org/archlinux/archlinux-docker/-/blob/master/.gitlab-ci.yml) using our own runner infrastructure. Initially root filesystem archives are constructed and provided in our [package registry](https://gitlab.archlinux.org/archlinux/archlinux-docker/-/packages). The released multi-stage Dockerfile downloads those archives and verifies their integrity before unpacking it into a OCI image layer. Images are built using [kaniko](https://github.com/GoogleContainerTools/kaniko) to avoid using privileged Docker containers, which also publishes them to our external repositories.

### Weekly releases

Weekly releases to the official DockerHub library use the same pipeline as daily builds. Updates are provided as automatic [pull requests](https://github.com/docker-library/official-images/pulls?q=is%3Apr+archlinux+is%3Aclosed+author%3Aarchlinux-github) to the [official-images library](https://github.com/docker-library/official-images/blob/master/library/archlinux), whose GitHub pipeline will build the images using our provided rootfs archives and Dockerfiles.

### Development

Changes in Git feature branches are built and tested using the pipeline as well. Development images are uploaded to our [GitLab Container Registry](https://gitlab.archlinux.org/archlinux/archlinux-docker/container_registry).
