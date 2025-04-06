$SSH_KEY_PATH = "C:\Users\Alan\Desktop\deploy\petclinic-key.pem"
$EC2_HOST = "ec2-user@13.58.97.148"

Write-Host "Starting deployment of Spring Pet Clinic to AWS..." -ForegroundColor Green

Write-Host "Building application with Maven..." -ForegroundColor Yellow
./mvnw clean package -DskipTests -Dcheckstyle.skip

Write-Host "Building Docker image..." -ForegroundColor Yellow
docker build -t spring-petclinic:latest .

Write-Host "Saving Docker image to tar file..." -ForegroundColor Yellow
docker save -o spring-petclinic.tar spring-petclinic:latest

Write-Host "Copying Docker image to EC2 (this may take a while)..." -ForegroundColor Yellow
scp -i $SSH_KEY_PATH spring-petclinic.tar ${EC2_HOST}:~

$deployScript = @"
#!/bin/bash
docker load -i ~/spring-petclinic.tar
docker stop petclinic 2>/dev/null || true
docker rm petclinic 2>/dev/null || true
docker run -d -p 80:8080 --name petclinic --restart always spring-petclinic:latest
docker ps
"@

$deployScript -replace "`r`n", "`n" | Out-File -FilePath "deploy_ec2.sh" -Encoding utf8

Write-Host "Deploying on EC2..." -ForegroundColor Yellow
scp -i $SSH_KEY_PATH deploy_ec2.sh ${EC2_HOST}:~/deploy_ec2.sh
ssh -i $SSH_KEY_PATH $EC2_HOST "chmod +x ~/deploy_ec2.sh && ~/deploy_ec2.sh"

Remove-Item -Path spring-petclinic.tar -Force
Remove-Item -Path deploy_ec2.sh -Force

Write-Host "Deployment completed!" -ForegroundColor Green
Write-Host "Your application should be accessible at: http://13.58.97.148" -ForegroundColor Cyan
