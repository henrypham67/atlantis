# Infrastructure as Code Orchestration

## Learning Purpose

- Atlantis
- pre-commit for terraform repository

## How to deploy

### Docker

- `cp .env.example .env`
- Fill all environment variables in `.env`
- `make docker`

### AWS

- config AWS identity for CLI
- `cp self-infra/tf.auto.tfvars.example self-infra/tf.auto.tfvars`
- Fill all variables in `self-infra/tf.auto.tfvars`
- `make aws`

## TODO

- make another secure version (private subnet, ALB, NAT) -> protect powerful role
