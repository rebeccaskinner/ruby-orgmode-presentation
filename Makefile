all: docker

docker:
	docker build --rm --tag rebeccaskinner/ruby-meetup-demo:0.0.1 .

.PHONY: docker
