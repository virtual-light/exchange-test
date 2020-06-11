.PHONY: docker/build docker/run

export LOCAL_USER_ID ?= $(shell id -u $$USER)

docker/build:
	@docker-compose build

docker/run: docker/build
	@docker-compose up -d &&\
		docker-compose exec app mix deps.get && \
		docker-compose exec app iex -S mix