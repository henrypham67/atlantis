.PHONY: local deploy random

local:
	docker compose up -d

deploy:
	cd self-infra && \
	terraform init && \
	terraform apply

random:
	@echo $$(echo $$RANDOM$$RANDOM | md5sum | head -c 12)