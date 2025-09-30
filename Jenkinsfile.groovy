pipeline {
    agent any

    environment {
        IMAGE_TAG = "${BUILD_NUMBER}"
        AWS_REGION = credentials('aws-region-id')  // solo si es string credential
        ECR_REPO = credentials('ecr-repo-id')      // string credential para repo
    }

    stages {
        stage('Checkout') { //Clonar
            steps {
                checkout scm
            }
        }

        stage('Build Maven') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Loguarse a AWS ECR') {
            steps {
                withCredentials([
                    usernamePassword(credentialsId: 'aws-credentials-id', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                        echo "REGION: $AWS_REGION"
                        echo "REPO: $ECR_REPO"
                        aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
                        aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
                        aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO
                    '''
                }
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                sh '''
                    docker build -t $ECR_REPO:$IMAGE_TAG .
                    docker push $ECR_REPO:$IMAGE_TAG
                '''
            }
        }
    }

    post {
        success {
            echo "Imagen Docker subida a ECR: $ECR_REPO:$IMAGE_TAG"
        }
        failure {
            echo "Falló el pipeline :v"
        }
    }
}

