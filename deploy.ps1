# Deploy.ps1

# Set variables
$projectPath = ".\super-service"
$dockerImageName = "super-service-api"
$dockerContainerName = "super-service-container"

# Function to write log messages
function Write-Log {
    param (
        [string]$message
    )
    Write-Host "[INFO] $message"
}

# 1. Run automated tests
Write-Log "Running automated tests..."
dotnet test "$projectPath\tests\SuperService.Tests\SuperService.Tests.csproj"
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Tests failed." -ForegroundColor Red
    exit $LASTEXITCODE
}

# 2. Build and package the application as a Docker image
Write-Log "Building and packaging the application as a Docker image..."
dotnet publish "$projectPath\SuperService.Api\SuperService.Api.csproj" -c Release -o "$projectPath\publish"

# Docker build
Write-Log "Building Docker image..."
docker build -t $dockerImageName -f "$projectPath\Dockerfile" "$projectPath"
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Docker build failed." -ForegroundColor Red
    exit $LASTEXITCODE
}

# 3. Deploy and run the image locally
Write-Log "Deploying the Docker container locally..."
docker stop $dockerContainerName 2>$null
docker rm $dockerContainerName 2>$null
docker run -d -p 5000:80 --name $dockerContainerName $dockerImageName
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Docker run failed." -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Log "Deployment successful. Application is running at http://localhost:5000"
