# flawed-by-design

> ⚠️ **Three intentional flaws** are tagged `// FLAW:` in the source — one in Terraform, one in `Jenkinsfile`, one in `verify_health.sh`. They are interlinked: fixing one without context surfaces a regression in the others. Fix all three before deploying anywhere real.

## Stack

Two-VPC, ECS-on-EC2 hosting `infrastructureascode/hello-world` and `jenkins/jenkins:lts` in `eu-central-1`. WAFv2 geo-fence on the Jenkins ALB, S3 access logs, CloudWatch alarms, billing guardrail.

## Layout

- `terraform/` — six numbered layers (`00-providers` → `50-logging`) + reusable `ecs_service` module
- `accounts/_bootstrap/` — one-time S3 state bucket (TF 1.10 native locking, no DynamoDB)
- `Jenkinsfile`, `Dockerfile`, `verify_health.sh` — pipeline + app container + health-probe helper

## Run

```sh
make bootstrap                       # one-time per AWS account
make ACCT=<alias> deploy             # six layers in order
make ACCT=<alias> destroy            # tear down
```

Apply order: `00 → 10 → 20 → 50 → 30 → 40`. `50-logging` precedes `30-ecs` because the ALBs write to the access-log bucket.

## CI gates

`terraform fmt`, `validate`, `tflint`, `checkov` (allow-list in [`.checkov.yaml`](.checkov.yaml)), `trivy fs` + `trivy image`, `shellcheck`. Net-new findings fail the build.

## The three flaws

| # | File | What | How it bites |
|---|---|---|---|
| 1 | [`terraform/50-logging/s3.tf`](terraform/50-logging/s3.tf) | The ALB-log-bucket lifecycle rule has an empty `filter {}` — the 90-day expiration applies to **every** object regardless of prefix. | Today only `alb/*` is in the bucket so nothing breaks. The moment another team thinks "this is the logs bucket, I'll put my exports here", their data evaporates at day 91. No alarm, no log line, no audit trail. |
| 2 | [`Jenkinsfile`](Jenkinsfile) (`Smoke test` stage) | The smoke test runs from the Jenkins task — private subnet, no NAT — against the **public-facing** App ALB DNS. From the Jenkins VPC that DNS resolves to public IPs and there's no egress route. | Every smoke test times out, every build emails **FAILURE**, deploy actually succeeded. Operators learn to ignore the failure-email channel. |
| 3 | [`verify_health.sh`](verify_health.sh) | `curl -o /dev/null -w '%{http_code}'` discards the response body and only checks the HTTP status code. | A misconfigured app returning `200 OK` with body `{"status":"down"}` (or an HTML error page from a fallback handler) passes. Both the in-container ECS healthcheck and the smoke test use this script. |

**Interlink — alarm fatigue → silent breakage.** Flaw 2 trains operators to ignore the failure-email channel ("smoke test always fails, just ignore"). Flaw 3 means a real broken-app state doesn't trigger a *different* signal — both ECS HC and smoke test happily pass on a 200-with-broken-body. Real outages slip through unnoticed; dashboards stay green; meanwhile flaw 1 quietly removes any third-party data someone parked in the logs bucket. **Three different blast radii (data loss, alert fatigue, false-healthy state) chained into one operationally invisible failure mode.**

To grep them yourself:

```sh
grep -rn 'FLAW' . --include='*.tf' --include='Jenkinsfile' --include='*.sh'
```

## License

[MIT](LICENSE).
