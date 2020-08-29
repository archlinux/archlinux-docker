# Docker Base Image for Arch Linux
[![pipeline status](https://gitlab.archlinux.org/archlinux/archlinux-docker/badges/master/pipeline.svg)](https://gitlab.archlinux.org/archlinux/archlinux-docker/-/commits/master)

This repository contains all scripts and files needed to create a Docker base image for Arch Linux.

## Dependencies
Install the following Arch Linux packages:

* make
* devtools
* docker
* fakechroot
* fakeroot

Make sure your user can directly interact with Docker (ie. `docker info` works).

## Usage
Run `make docker-image-base` to build the image `archlinux:base` with the
`base` group installed. You can also run `make docker-image-base-devel` to
build the image `archlinux:base-devel` with the `base-devel` group installed.

## Purpose
* Provide the Arch experience in a Docker image
* Provide the most simple but complete image to base every other upon
* `pacman` needs to work out of the box
* All installed packages have to be kept unmodified
