# Makefile - repeatable ops for the take-home stack.
# Usage: make ACCT=denis deploy
#        make ACCT=denis destroy
#        make fmt validate precommit

ACCT ?=
LAYERS := 00-providers 10-network 20-security 50-logging 30-ecs 40-observability
ROOT  := $(CURDIR)

.PHONY: help fmt fmt-check validate precommit deploy destroy bootstrap clean

help:
	@printf 'targets:\n'
	@printf '  make fmt             terraform fmt -recursive\n'
	@printf '  make fmt-check       fail if anything needs fmt\n'
	@printf '  make validate        terraform validate per layer\n'
	@printf '  make precommit       run all pre-commit hooks\n'
	@printf '  make bootstrap       apply accounts/_bootstrap (one-time per AWS account)\n'
	@printf '  make ACCT=<a> deploy  apply six layers for <acct>\n'
	@printf '  make ACCT=<a> destroy tear down six layers for <acct>\n'
	@printf '  make clean           remove .terraform/ and *.tfplan everywhere\n'

fmt:
	terraform fmt -recursive

fmt-check:
	terraform fmt -recursive -check -diff

validate:
	@for d in $(LAYERS) modules/ecs_service; do \
	  printf '== %s ==\n' "$$d"; \
	  cd $(ROOT)/terraform/$$d && terraform init -backend=false -input=false >/dev/null && terraform validate; \
	done

precommit:
	pre-commit run --all-files

bootstrap:
	cd accounts/_bootstrap && terraform init -input=false && terraform apply -input=false -auto-approve

deploy:
	@test -n "$(ACCT)" || (echo 'set ACCT=<account-folder-name>' >&2; exit 1)
	./deploy.sh $(ACCT)

destroy:
	@test -n "$(ACCT)" || (echo 'set ACCT=<account-folder-name>' >&2; exit 1)
	./destroy.sh $(ACCT)

clean:
	find . -type d -name '.terraform' -exec rm -rf {} +
	find . -type f -name '*.tfplan' -delete
