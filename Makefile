.DEFAULT_GOAL := up

.PHONY: up down backend frontend test lint format

up:
	docker compose up -d

down:
	docker compose down

backend:
	docker compose run --rm backend

frontend:
	docker compose run --rm frontend

test:
	docker compose run --rm backend make test

lint:
	docker compose run --rm backend make lint

format:
	docker compose run --rm backend make format
