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

        stage('Check Docker') {
            steps {
                bat 'docker info'
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
                    // Write PowerShell script to file
                    bat '''
                        echo $keyFile = "%KEY_FILE%" > deploy.ps1
                        echo $secureKeyPath = "$env:WORKSPACE\\secure-key.pem" >> deploy.ps1
                        echo Copy-Item -Path $keyFile -Destination $secureKeyPath -Force >> deploy.ps1
                        echo icacls $secureKeyPath /inheritance:r >> deploy.ps1
                        echo icacls $secureKeyPath /grant:r "$env:USERNAME:(R)" >> deploy.ps1
                        echo $deployScript = @">> deploy.ps1
                        echo #!/bin/bash >> deploy.ps1
                        echo docker load -i ~/spring-petclinic.tar >> deploy.ps1
                        echo docker stop petclinic 2^>/dev/null ^|^| true >> deploy.ps1
                        echo docker rm petclinic 2^>/dev/null ^|^| true >> deploy.ps1
                        echo docker run -d -p 80:8080 --name petclinic --restart always spring-petclinic:latest >> deploy.ps1
                        echo docker ps >> deploy.ps1
                        echo "@ >> deploy.ps1
                        echo $deployScript ^| Out-File -FilePath "deploy.sh" -Encoding ASCII >> deploy.ps1
                        echo scp -i $secureKeyPath -o StrictHostKeyChecking=no spring-petclinic.tar ec2-user@13.58.97.148:~ >> deploy.ps1
                        echo scp -i $secureKeyPath -o StrictHostKeyChecking=no deploy.sh ec2-user@13.58.97.148:~ >> deploy.ps1
                        echo ssh -i $secureKeyPath -o StrictHostKeyChecking=no ec2-user@13.58.97.148 "chmod +x ~/deploy.sh && ~/deploy.sh" >> deploy.ps1
                        echo Remove-Item -Path $secureKeyPath -Force >> deploy.ps1
                    '''

                    // Execute the PowerShell script
                    bat 'powershell -ExecutionPolicy Bypass -File deploy.ps1'

                    // Clean up
                    bat 'del deploy.ps1 deploy.sh /F /Q 2>nul || exit /b 0'
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
            bat 'del spring-petclinic.tar /F /Q 2>nul || exit /b 0'
        }
    }
}
