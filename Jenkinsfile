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
                    // Create a PowerShell script file
                    writeFile file: 'deploy.ps1', text: '''
                        $keyFile = $env:KEY_FILE
                        $secureKeyPath = "$env:WORKSPACE\\secure-key.pem"

                        # Copy the key and set permissions
                        Copy-Item -Path $keyFile -Destination $secureKeyPath -Force
                        icacls $secureKeyPath /inheritance:r
                        icacls $secureKeyPath /grant:r "${env:USERNAME}:(R)"

                        # Create the deployment script
                        @"
#!/bin/bash
docker load -i ~/spring-petclinic.tar
docker stop petclinic 2>/dev/null || true
docker rm petclinic 2>/dev/null || true
docker run -d -p 80:8080 --name petclinic --restart always spring-petclinic:latest
docker ps
"@ | Out-File -FilePath "deploy.sh" -Encoding ASCII

                        # Transfer files to EC2
                        & scp -i $secureKeyPath -o StrictHostKeyChecking=no spring-petclinic.tar ec2-user@13.58.97.148:~
                        & scp -i $secureKeyPath -o StrictHostKeyChecking=no deploy.sh ec2-user@13.58.97.148:~

                        # Run deployment commands
                        & ssh -i $secureKeyPath -o StrictHostKeyChecking=no ec2-user@13.58.97.148 "chmod +x ~/deploy.sh && ~/deploy.sh"

                        # Clean up
                        Remove-Item -Path $secureKeyPath -Force
                    '''

                    // Run the PowerShell script with proper execution policy
                    bat 'powershell -ExecutionPolicy Bypass -File deploy.ps1'
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
            bat 'del deploy.ps1 spring-petclinic.tar /F /Q 2>nul || exit /b 0'
        }
    }
}
