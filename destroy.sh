#!/usr/bin/env bash
# destroy.sh - tear down every layer in REVERSE apply order.
#
# Usage: ./destroy.sh <account-name>
#
# The state bucket (accounts/_bootstrap) is intentionally NOT destroyed -
# it has prevent_destroy=true. Tear it down manually after you're done.
set -euo pipefail

readonly ACCOUNT="${1:?usage: $0 <account-name>}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT
readonly ACCT_DIR="${REPO_ROOT}/accounts/${ACCOUNT}"
readonly TFVARS="${ACCT_DIR}/terraform.tfvars"
readonly BACKEND="${ACCT_DIR}/backend.tfbackend"

[[ -f "$TFVARS"  ]] || { echo "missing $TFVARS";  exit 1; }
[[ -f "$BACKEND" ]] || { echo "missing $BACKEND"; exit 1; }

# Reverse of deploy order - leaves nothing dangling.
readonly LAYERS=(40-observability 30-ecs 50-logging 20-security 10-network 00-providers)

for layer in "${LAYERS[@]}"; do
  printf '\n=== destroy %s ===\n' "$layer"
  cd "${REPO_ROOT}/terraform/${layer}"
  terraform init -reconfigure -input=false \
    -backend-config="${BACKEND}" \
    -backend-config="key=${layer}.tfstate"
  terraform destroy -input=false -auto-approve \
    -var-file="${TFVARS}"
done

printf '\nAll layers destroyed for account %s.\n' "$ACCOUNT"
printf 'State bucket and DynamoDB lock table remain (managed by accounts/_bootstrap).\n'
