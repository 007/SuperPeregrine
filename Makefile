default: help

help:
	@echo "Popular Make Targets:"
	@echo "   image - build docker image"
	@echo "   run   - run shell in built image"

.PHONY: clean

clean:
	@rm -f .dockerimage
	docker image rm --force makemkv:latest
	docker image prune -f

.dockerimage:
	docker build --rm --tag makemkv .
	docker image prune -f
	@touch .dockerimage

prodimage: clean Dockerfile
	docker build --rm --pull --no-cache --squash --tag makemkv .
	docker image prune -f
	@touch .dockerimage

image: Dockerfile .dockerimage

run: .dockerimage
	docker run --rm --privileged --interactive --tty \
	  --device /dev/sr* \
	  --mount type=bind,source="$(shell pwd)"/inbound,target=/inbound \
	  --mount type=bind,source="$(shell pwd)"/outbound,target=/outbound \
	  --name makemkv \
	  makemkv:latest
