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
                script {
                    // Create deploy.sh with LF endings
                    def deployScript = '''#!/bin/bash
docker load -i ~/spring-petclinic.tar
docker stop petclinic 2>/dev/null || true
docker rm petclinic 2>/dev/null || true
docker run -d -p 80:8080 --name petclinic --restart always spring-petclinic:latest
docker ps
'''

                    // Write deploy.sh to workspace with LF endings
                    writeFile file: 'deploy.sh', text: deployScript.replaceAll('\\r\\n?', '\n')

                    // Convert line endings explicitly (just in case)
                    bat 'powershell -Command "(Get-Content deploy.sh) | Set-Content -NoNewline -Encoding Ascii deploy.sh"'
                }

                // Use Publish Over SSH plugin to deploy
                sshPublisher(
                    publishers: [
                        sshPublisherDesc(
                            configName: 'AWS-EC2',
                            transfers: [
                                sshTransfer(
                                    sourceFiles: 'spring-petclinic.tar,deploy.sh',
                                    execCommand: 'chmod +x ~/deploy.sh && ~/deploy.sh'
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
            echo ' Pipeline failed. Check the logs for details.'
        }
    }
}
