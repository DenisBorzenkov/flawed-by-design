#!/usr/bin/env bash
# deploy.sh - apply every layer in order against a chosen account.
#
# Usage:   ./deploy.sh <account-name>
# Example: ./deploy.sh example
#
# Pre-reqs (one-time, see SETUP.md):
#   1. AWS CLI configured: `aws sts get-caller-identity` works.
#   2. accounts/_bootstrap/ has been applied (creates state bucket + lock table).
#   3. accounts/<account-name>/terraform.tfvars exists and has tfstate_bucket set.
#   4. accounts/<account-name>/backend.tfbackend exists and matches that bucket.
set -euo pipefail

readonly ACCOUNT="${1:?usage: $0 <account-name>}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT
readonly ACCT_DIR="${REPO_ROOT}/accounts/${ACCOUNT}"
readonly TFVARS="${ACCT_DIR}/terraform.tfvars"
readonly BACKEND="${ACCT_DIR}/backend.tfbackend"

[[ -f "$TFVARS"  ]] || { echo "missing $TFVARS";  exit 1; }
[[ -f "$BACKEND" ]] || { echo "missing $BACKEND"; exit 1; }

# Apply order is fixed by the dependency graph:
# 50-logging precedes 30-ecs because the ALBs reference the access-log bucket.
readonly LAYERS=(00-providers 10-network 20-security 50-logging 30-ecs 40-observability)

for layer in "${LAYERS[@]}"; do
  printf '\n=== %s ===\n' "$layer"
  cd "${REPO_ROOT}/terraform/${layer}"
  terraform init -reconfigure -input=false \
    -backend-config="${BACKEND}" \
    -backend-config="key=${layer}.tfstate"
  # -compact-warnings suppresses the per-layer "undeclared variable
  # alarm_email/domain_name/etc" noise - those vars live only in 00-providers
  # but the shared tfvars passes them to every layer.
  terraform apply -input=false -auto-approve -compact-warnings \
    -var-file="${TFVARS}"
done

printf '\nAll layers applied for account %s.\n' "$ACCOUNT"
printf 'Confirm SNS subscriptions in your inbox; alarms stay silent until you do.\n'
