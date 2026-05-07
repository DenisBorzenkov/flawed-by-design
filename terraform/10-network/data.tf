// 10-network has no upstream state dependencies - region/env/tags come
// straight from per-account tfvars. Adding a `terraform_remote_state` here
// would be dead code (tflint terraform_unused_declarations).
locals {
  azs = var.azs == null ? ["${var.region}a", "${var.region}b"] : var.azs
}
