pipeline {
  agent any
  environment {
    TERRAFORM_HOME = "/var/jenkins_home"
    TF_IN_AUTOMATION = 'true'
  }
  stages {
    stage('Terraform Init') {
      steps {
        sh "pwd"
        sh "ls"
        sh "${env.TERRAFORM_HOME}/terraform init -input=false"
        }
    }

    stage('Terraform Plan') {
      steps {
        sh "${env.TERRAFORM_HOME}/terraform plan -out=tfplan -input=false -var-file='dev.tfvars'"
      }
    }
    stage('Terraform Apply') {
      steps {
        input 'Apply Plan'
        sh "${env.TERRAFORM_HOME}/terraform apply -input=false tfplan"
      }
    }
    
  }
}

