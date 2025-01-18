
docker:
	docker compose up -d

aws:
	cd self-infra
	terraform init
	terraform apply --auto-approve

random:
	@echo $RANDOM$RANDOM | md5sum | head -c 12
