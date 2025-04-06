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
                withCredentials([sshUserPrivateKey(credentialsId: 'aws-ec2-key', keyFileVariable: 'KEY_FILE')]) {
                    // Create deployment script with Unix line endings
                    powershell '''
                        $deployScript = @"
#!/bin/bash
docker load -i ~/spring-petclinic.tar
docker stop petclinic 2>/dev/null || true
docker rm petclinic 2>/dev/null || true
docker run -d -p 80:8080 --name petclinic --restart always spring-petclinic:latest
docker ps
"@
                        $deployScript -replace "`r`n", "`n" | Out-File -FilePath "deploy.sh" -Encoding utf8
                    '''

                    // Copy files to EC2 and execute deployment
                    bat 'scp -i "%KEY_FILE%" -o StrictHostKeyChecking=no spring-petclinic.tar ec2-user@13.58.97.148:~'
                    bat 'scp -i "%KEY_FILE%" -o StrictHostKeyChecking=no deploy.sh ec2-user@13.58.97.148:~'
                    bat 'ssh -i "%KEY_FILE%" -o StrictHostKeyChecking=no ec2-user@13.58.97.148 "chmod +x ~/deploy.sh && ~/deploy.sh"'

                    // Clean up local files
                    bat 'del deploy.sh'
                    bat 'del spring-petclinic.tar'
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
    }
}
