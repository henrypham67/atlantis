
docker:
	docker compose up -d

aws:
	cd self-infra
	terraform init
	terraform apply --auto-approve