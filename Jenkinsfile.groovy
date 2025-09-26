pipeline {
    agent {
        docker { image 'maven:3-amazoncorretto-21' }
    }

    environment {
        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') { //Clonar
            steps {
                checkout scm
            }
        }

        stage('Load Environment') { //Cargar variables de entorno
            steps {
                script {
                    def props = readProperties file: '.env'
                    props.each { k, v ->
                        env."${k}" = v
                    }
                }
            }
        }

        stage('Build Maven') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Loguarse a AWS ECR') {
            agent any
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws-credentials-id', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh '''
                        aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
                        aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
                        aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO
                    '''
                }
            }
        }

        stage('Build imagen Docker') {
            agent any
            steps {
                sh "docker build -t $ECR_REPO:$IMAGE_TAG ."
            }
        }

        stage('Push imagen Docker') {
            agent any
            steps {
                sh "docker push $ECR_REPO:$IMAGE_TAG"
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

