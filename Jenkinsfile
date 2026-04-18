pipeline {
    agent any

    environment {
        PROJECT_ID  = credentials('gcp-project-id')
        REGION      = credentials('gcp-region')
        REPO        = 'certforge-app'
        IMAGE_NAME  = "${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/app"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
                echo '✅ Code checked out successfully'
            }
        }

        stage('Install & Test') {
            steps {
                sh 'npm install'
                sh 'npm test'
                echo '✅ Tests passed'
            }
        }

        stage('Docker Build') {
            steps {
                sh "docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} ."
                sh "docker tag ${IMAGE_NAME}:${BUILD_NUMBER} ${IMAGE_NAME}:latest"
                echo '✅ Docker image built'
            }
        }

        stage('Configure Docker for GCP') {
            steps {
                sh "gcloud auth configure-docker ${REGION}-docker.pkg.dev --quiet"
                echo '✅ Docker configured for Artifact Registry'
            }
        }

        stage('Push to Artifact Registry') {
            steps {
                sh "docker push ${IMAGE_NAME}:${BUILD_NUMBER}"
                sh "docker push ${IMAGE_NAME}:latest"
                echo '✅ Image pushed to Artifact Registry'
            }
        }

        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                    echo '✅ Terraform initialized'
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    sh """
                        terraform apply -auto-approve \
                        -var="project_id=${PROJECT_ID}" \
                        -var="region=${REGION}"
                    """
                    echo '✅ Infrastructure deployed'
                }
            }
        }

        stage('Get Deployment URL') {
            steps {
                dir('terraform') {
                    sh 'terraform output cloud_run_url'
                }
                echo '✅ App deployed successfully!'
            }
        }
    }

    post {
        success {
            echo '🎉 Pipeline completed! App is live on Cloud Run!'
        }
        failure {
            echo '❌ Pipeline failed. Check the logs above.'
        }
        always {
            sh 'docker system prune -f'
        }
    }
}
