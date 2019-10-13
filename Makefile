DOCKER_USER:=pierres
DOCKER_ORGANIZATION=archlinux
DOCKER_IMAGE:=base

docker-image:
	docker build -t $(DOCKER_ORGANIZATION)/$(DOCKER_IMAGE) .

docker-image-test: docker-image
	# FIXME: /etc/mtab is hidden by docker so the stricter -Qkk fails
	docker run --rm $(DOCKER_ORGANIZATION)/$(DOCKER_IMAGE) sh -c "/usr/bin/pacman -Sy && /usr/bin/pacman -Qqk"
	docker run --rm $(DOCKER_ORGANIZATION)/$(DOCKER_IMAGE) sh -c "/usr/bin/pacman -Syu --noconfirm docker && docker -v"
	# Ensure that the image does not include a private key
	! docker run --rm $(DOCKER_ORGANIZATION)/$(DOCKER_IMAGE) pacman-key --lsign-key pierre@archlinux.de
	docker run --rm $(DOCKER_ORGANIZATION)/$(DOCKER_IMAGE) sh -c "/usr/bin/id -u http"
	docker run --rm $(DOCKER_ORGANIZATION)/$(DOCKER_IMAGE) sh -c "/usr/bin/pacman -Syu --noconfirm grep && locale | grep -q UTF-8"

docker-push:
	docker login -u $(DOCKER_USER)
	docker push $(DOCKER_ORGANIZATION)/$(DOCKER_IMAGE)

.PHONY: docker-image docker-image-test docker-push
