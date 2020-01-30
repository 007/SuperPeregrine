default: rip

help:
	@echo "Popular Make Targets:"
	@echo "   image - build docker image"
	@echo "   rip   - run ripper"
	@echo "   bash  - run shell in built image"

.PHONY: clean

clean:
	@rm -f .dockerimage
	docker image rm --force superperegrine:latest
	docker image prune -f

.dockerimage: Dockerfile
	docker build --rm --tag superperegrine .
	docker image prune -f
	@touch .dockerimage

prodimage: clean Dockerfile
	docker build --rm --pull --squash --tag superperegrine .
	docker image prune -f
	@touch .dockerimage

image: Dockerfile .dockerimage

rip: .dockerimage
	docker run --rm --privileged --interactive --tty \
	  --device /dev/sr* \
	  --env MIN_LENGTH=900 \
	  --env UID=$(shell id -u) \
	  --env GID=$(shell id -g) \
	  --mount type=bind,source="$(shell pwd)"/presets,target=/presets \
	  --mount type=bind,source="$(shell pwd)"/inbound,target=/inbound \
	  --mount type=bind,source="$(shell pwd)"/outbound,target=/outbound \
	  --name superperegrine \
	  superperegrine:latest

bash:
	docker run --rm --privileged --interactive --tty \
	  --device /dev/sr* \
	  --mount type=bind,source="$(shell pwd)"/presets,target=/presets \
	  --mount type=bind,source="$(shell pwd)"/inbound,target=/inbound \
	  --mount type=bind,source="$(shell pwd)"/outbound,target=/outbound \
	  --name superperegrine \
	  superperegrine:latest bash
