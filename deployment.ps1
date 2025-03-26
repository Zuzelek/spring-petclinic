# deployment.ps1

$SSH_KEY_PATH = "C:\Users\Alan\Desktop\deploy\petclinic-key.pem"
$EC2_HOST = "ec2-user@13.58.97.148"

Write-Host "Starting deployment of Spring Pet Clinic to AWS..." -ForegroundColor Green

Write-Host "Building Docker image..." -ForegroundColor Yellow
docker build -t spring-petclinic:latest .

Write-Host "Saving Docker image to tar file..." -ForegroundColor Yellow
docker save -o spring-petclinic.tar spring-petclinic:latest

Write-Host "Copying Docker image to EC2 (this may take a while)..." -ForegroundColor Yellow
scp -i $SSH_KEY_PATH spring-petclinic.tar ${EC2_HOST}:~

Write-Host "Deploying on EC2..." -ForegroundColor Yellow
ssh -i $SSH_KEY_PATH $EC2_HOST "
    # Load the Docker image
    docker load -i ~/spring-petclinic.tar
    
    # Stop and remove the existing container
    docker stop petclinic || true
    docker rm petclinic || true
    
    # Run the new container
    docker run -d -p 80:8080 --name petclinic spring-petclinic:latest
    
    # Show running containers
    docker ps
"

Remove-Item -Path spring-petclinic.tar -Force

Write-Host "Deployment completed!" -ForegroundColor Green
Write-Host "Your application should be accessible at: http://13.58.97.148" -ForegroundColor Cyan
