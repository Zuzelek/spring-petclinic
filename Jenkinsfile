pipeline {
    agent any
    environment {
        SONAR_TOKEN = credentials('ff7215b135f436c686d8006d74bc630c0c53c238')
    }
    stages {
        stage('Checkout Code') {
            steps {
                git 'https://github.com/Zuzelek/spring-petclinic.git'
            }
        }
        stage('Build & Test') {
            steps {
                sh 'mvn clean test'
            }
        }
        stage('SonarCloud Analysis') {
            steps {
                sh '''
                    mvn sonar:sonar \
                    -Dsonar.projectKey=your_project_key \
                    -Dsonar.organization=your_organization_name \
                    -Dsonar.login=${SONAR_TOKEN}
                '''
            }
        }
        stage('Package Application') {
            steps {
                sh 'mvn package'
            }
        }
        stage('Archive Artifact') {
            steps {
                archiveArtifacts artifacts: '**/target/*.jar', fingerprint: true
            }
        }
    }
}
