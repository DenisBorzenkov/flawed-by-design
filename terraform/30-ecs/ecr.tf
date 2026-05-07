// ECR repo for the hello-world image. Scan-on-push catches CVEs before they
// reach the cluster.
resource "aws_ecr_repository" "hello" {
  name = "hello-${var.env}"
  // MUTABLE so the Jenkins pipeline can re-push :latest after rebuilds.
  // For prod, prefer IMMUTABLE + git-sha-based tags.
  image_tag_mutability = var.ecr_image_tag_mutability
  image_scanning_configuration {
    scan_on_push = true
  }
}

// Mirror of jenkins/jenkins:lts. Without NAT, tasks in private subnets cannot
// reach Docker Hub directly - the brief allows VPC endpoints only for AWS
// services. So we mirror upstream into ECR and pull from there over the
// ecr.api/ecr.dkr endpoints.
resource "aws_ecr_repository" "jenkins" {
  name                 = "jenkins-${var.env}"
  image_tag_mutability = var.ecr_image_tag_mutability
  image_scanning_configuration {
    scan_on_push = true
  }
}

// Keep last N - caps storage cost; older builds reproducible from CI history.
resource "aws_ecr_lifecycle_policy" "hello" {
  repository = aws_ecr_repository.hello.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "keep last ${var.ecr_keep_last_n_images}"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = var.ecr_keep_last_n_images
      }
      action = {
        type = "expire"
      }
    }]
  })
}

// Same retention policy on the jenkins mirror.
resource "aws_ecr_lifecycle_policy" "jenkins" {
  repository = aws_ecr_repository.jenkins.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "keep last ${var.ecr_keep_last_n_images}"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = var.ecr_keep_last_n_images
      }
      action = {
        type = "expire"
      }
    }]
  })
}
