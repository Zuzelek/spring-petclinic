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
                sshagent(['aws-ec2-key']) {
                    // Create deployment script with Unix line endings
                    bat '''
                        echo #!/bin/bash > deploy.sh
                        echo docker load -i ~/spring-petclinic.tar >> deploy.sh
                        echo docker stop petclinic 2^>/dev/null ^|^| true >> deploy.sh
                        echo docker rm petclinic 2^>/dev/null ^|^| true >> deploy.sh
                        echo docker run -d -p 80:8080 --name petclinic --restart always spring-petclinic:latest >> deploy.sh
                        echo docker ps >> deploy.sh
                    '''

                    // Copy files and execute on EC2
                    bat 'scp -o StrictHostKeyChecking=no spring-petclinic.tar ec2-user@13.58.97.148:~'
                    bat 'scp -o StrictHostKeyChecking=no deploy.sh ec2-user@13.58.97.148:~'
                    bat 'ssh -o StrictHostKeyChecking=no ec2-user@13.58.97.148 "chmod +x ~/deploy.sh && ~/deploy.sh"'
                }
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
        always {
            bat 'del deploy.sh spring-petclinic.tar /F /Q 2>nul || exit /b 0'
        }
    }
}
