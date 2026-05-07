// Run with `tflint --recursive` from repo root, or via the
// `terraform_tflint` pre-commit hook.

config {
  format     = "compact"
  call_module_type = "all"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "aws" {
  enabled = true
  version = "0.36.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

// Module composition uses input variables that are validated at apply time
// against per-account tfvars; tflint cannot resolve them statically.
rule "terraform_required_version" { enabled = true }
rule "terraform_required_providers" { enabled = true }
rule "terraform_unused_declarations" { enabled = true }
rule "terraform_typed_variables" { enabled = true }
