// Manually-triggered pipeline: build -> push -> deploy hello-world to ECS.
// Email on success / failure / abort, as briefed.
pipeline {
  agent any

  // No SCM polling, no triggers - operator runs this when they want to ship.
  options {
    disableConcurrentBuilds()
    timestamps()
    timeout(time: 30, unit: 'MINUTES')
  }

  parameters {
    string(name: 'IMAGE_TAG',        defaultValue: 'latest',                  description: 'Tag to push')
    string(name: 'ECR_REPOSITORY',   defaultValue: '',                        description: 'ECR repo URL (e.g. <acct>.dkr.ecr.eu-central-1.amazonaws.com/hello-dev)')
    string(name: 'AWS_REGION',       defaultValue: 'eu-central-1',            description: 'AWS region')
    string(name: 'ECS_CLUSTER',      defaultValue: 'app-dev',                 description: 'ECS cluster name')
    string(name: 'ECS_SERVICE',      defaultValue: 'hello-dev',               description: 'ECS service name')
    string(name: 'BUILD_LOG_BUCKET', defaultValue: '',                        description: 'S3 bucket that captures per-stage build logs')
    string(name: 'NOTIFY_EMAIL',     defaultValue: 'ops@example.invalid',     description: 'Recipient for build outcome emails')
    string(name: 'ALB_DNS',          defaultValue: 'app.example.invalid',     description: 'ALB DNS name for the post-deploy smoke test')
  }

  environment {
    AWS_DEFAULT_REGION = "${params.AWS_REGION}"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Login to ECR') {
      steps {
        sh '''
          set -euo pipefail
          aws ecr get-login-password --region "$AWS_REGION" \
            | docker login --username AWS --password-stdin "${ECR_REPOSITORY%/*}"
        '''
      }
    }

    stage('Build') {
      steps {
        sh '''
          set -euo pipefail
          docker build --progress=plain -t "${ECR_REPOSITORY}:${IMAGE_TAG}" . 2>&1 \
            | tee build.log
          aws s3 cp build.log "s3://${BUILD_LOG_BUCKET}/${BUILD_TAG}/build.log"
        '''
      }
    }

    stage('Push') {
      steps {
        sh '''
          set -euo pipefail
          docker push "${ECR_REPOSITORY}:${IMAGE_TAG}" 2>&1 \
            | tee push.log
          aws s3 cp push.log "s3://${BUILD_LOG_BUCKET}/${BUILD_TAG}/push.log"
        '''
      }
    }

    stage('Deploy') {
      steps {
        sh '''
          set -euo pipefail
          aws ecs update-service \
            --cluster "$ECS_CLUSTER" \
            --service "$ECS_SERVICE" \
            --force-new-deployment >/dev/null
          aws ecs wait services-stable \
            --cluster "$ECS_CLUSTER" \
            --services "$ECS_SERVICE"
        '''
      }
    }

    stage('Smoke test') {
      steps {
        // FLAW #2: this stage runs from the Jenkins task - which lives in a
        // private subnet of the Jenkins VPC, with no NAT. The probe target
        // is the **public-facing** App ALB DNS. From inside the Jenkins VPC
        // that DNS resolves to public IPs (AWS only resolves an internet-
        // facing ALB to private IPs from *the same* VPC, not a peered one),
        // and there's no egress route to a public IP from this subnet.
        // Result: every smoke test times out, every build emails FAILURE
        // even though the deploy succeeded. Operators learn to ignore the
        // failure-email channel - see FLAW #3 in verify_health.sh for what
        // that hides. Fix: run the smoke test from a runner with NAT or
        // egress, or expose the app via an internal ALB resolvable through
        // the VPC peering.
        sh '''
          set -euo pipefail
          ./verify_health.sh "https://${ALB_DNS}/health" 60
        '''
      }
    }
  }

  post {
    success {
      mail to: "${params.NOTIFY_EMAIL}",
           subject: "[Jenkins] ${env.JOB_NAME} #${env.BUILD_NUMBER} SUCCESS",
           body:    "Build ${env.BUILD_URL} succeeded."
    }
    failure {
      mail to: "${params.NOTIFY_EMAIL}",
           subject: "[Jenkins] ${env.JOB_NAME} #${env.BUILD_NUMBER} FAILED",
           body:    "Build ${env.BUILD_URL} failed.\nConsole: ${env.BUILD_URL}console"
    }
    aborted {
      mail to: "${params.NOTIFY_EMAIL}",
           subject: "[Jenkins] ${env.JOB_NAME} #${env.BUILD_NUMBER} ABORTED",
           body:    "Build ${env.BUILD_URL} was aborted."
    }
  }
}
