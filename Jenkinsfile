pipeline {
  agent any

  environment {
    TF_DIR = "infra/terraform"
    AWS_CRED_ID = "aws-creds"
  }

  parameters {
    choice(name: 'TARGET_ENV', choices: ['staging','production'], description: 'Which env to deploy?')
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Init & Workspace') {
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: env.AWS_CRED_ID]]) {
          sh """
            cd ${TF_DIR}
            export TF_WORKSPACE=${params.TARGET_ENV}
            terraform init -input=false \
              -backend-config="bucket=<BUCKET>" \
              -backend-config="region=<REGION>" \
              -backend-config="dynamodb_table=<TABLE>" \
              -backend-config="key=infra/${TF_WORKSPACE}.tfstate"
            terraform workspace select ${TF_WORKSPACE} || terraform workspace new ${TF_WORKSPACE}
          """
        }
      }
    }

    stage('Plan') {
      steps {
        sh """
          cd ${TF_DIR}
          terraform plan -input=false -var "project_name=myapp" -out=tfplan-${params.TARGET_ENV}.out
        """
        archiveArtifacts artifacts: "${TF_DIR}/tfplan-${params.TARGET_ENV}.out", allowEmptyArchive: true
      }
    }

    stage('Apply') {
      steps {
        script {
          if (params.TARGET_ENV == 'production') {
            timeout(time: 60, unit: 'MINUTES') {
              input message: "Approve apply to PRODUCTION?", ok: "Apply"
            }
          }
          withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: env.AWS_CRED_ID]]) {
            sh """
              cd ${TF_DIR}
              terraform apply -input=false -auto-approve tfplan-${params.TARGET_ENV}.out
            """
          }
        }
      }
    }
  }

  post {
    success { echo "Done: ${params.TARGET_ENV}" }
    failure { echo "Failed: ${params.TARGET_ENV}" }
  }
}
