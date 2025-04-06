pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                bat 'mvn clean package -DskipTests -Dcheckstyle.skip'
            }
        }

        stage('Test') {
            steps {
                bat 'mvn test -Dcheckstyle.skip'
            }
            post {
                always {
                    junit '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                bat 'docker build -t spring-petclinic:%BUILD_NUMBER% .'
                bat 'docker tag spring-petclinic:%BUILD_NUMBER% spring-petclinic:latest'
            }
        }

        stage('Save Docker Image') {
            steps {
                bat 'docker save -o spring-petclinic.tar spring-petclinic:latest'
            }
        }

        stage('Deploy to AWS') {
            steps {
                // Create a deployment script directly on the EC2 instance
                sshPublisher(
                    publishers: [
                        sshPublisherDesc(
                            configName: 'AWS-EC2',
                            transfers: [
                                sshTransfer(
                                    sourceFiles: 'spring-petclinic.tar',
                                    remoteDirectory: ''
                                ),
                                sshTransfer(
                                    execCommand: '''
                                    echo '#!/bin/bash' > deploy.sh
                                    echo 'docker load -i ~/spring-petclinic.tar' >> deploy.sh
                                    echo 'docker stop petclinic 2>/dev/null || true' >> deploy.sh
                                    echo 'docker rm petclinic 2>/dev/null || true' >> deploy.sh
                                    echo 'docker run -d -p 80:8080 --name petclinic --restart always spring-petclinic:latest' >> deploy.sh
                                    echo 'docker ps' >> deploy.sh
                                    chmod +x deploy.sh
                                    ./deploy.sh
                                    '''
                                )
                            ],
                            verbose: true
                        )
                    ]
                )
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
            echo 'Application deployed to http://13.58.97.148'
        }
        failure {
            echo 'Pipeline failed. Check the logs for details.'
        }
    }
}
