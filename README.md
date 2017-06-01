# Docker Base Image for Arch Linux [![Build Status](https://travis-ci.org/pierres/archlinux-docker.svg?branch=master)](https://travis-ci.org/pierres/archlinux-docker)
This repository contains all scripts and files needed to crate a Docker base image for the Arch Linux distribution.
## Dependencies
Install the following Arch Linux packages:
* make
* devtools
## Usage
Run `make docker-image` as root to build the base image. 

By default, this command will build the `archlinux/base` image. You can build the other targets by setting the DOCKER_IMAGE variable upon building:

```bash
$ make DOCKER_IMAGE=testing docker-image
```
