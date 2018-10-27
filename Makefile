default: help

help:
	@echo "Popular Make Targets:"
	@echo "   image - build docker image"
	@echo "   run   - run shell in built image"

prodimage:
	docker build --pull --no-cache --compress --squash --tag makemkv .

image:
	docker build --rm --tag makemkv .
	docker image prune -f

run: image
	#docker run --rm --name makemkv -it makemkv:latest || true
	docker run --rm --name makemkv -it makemkv:latest makemkvcon || true

