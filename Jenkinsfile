pipeline {
    agent any

    tools {
        maven 'Maven'
        jdk 'JDK 11'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                bat 'mvn clean package -DskipTests'
            }
        }

        stage('Unit Tests') {
            steps {
                bat 'mvn test'
            }
            post {
                always {
                    junit '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                echo 'Skipping SonarQube for now'
                // If you have SonarQube configured, uncomment:
                // withSonarQubeEnv('SonarCloud') {
                //     bat 'mvn sonar:sonar'
                // }
            }
        }

        stage('Build Docker Image') {
            steps {
                bat 'docker build -t spring-petclinic:%BUILD_NUMBER% .'
                bat 'docker tag spring-petclinic:%BUILD_NUMBER% spring-petclinic:latest'
            }
        }

        stage('Run Docker Container') {
            steps {
                bat 'docker stop petclinic-test || exit 0'
                bat 'docker rm petclinic-test || exit 0'
                bat 'docker run -d -p 8081:8080 --name petclinic-test spring-petclinic:latest'
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
