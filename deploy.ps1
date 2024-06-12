# Deploy.ps1

# Set variables
$projectPath = ".\super-service"
$dockerImageName = "super-service-api"
$dockerContainerName = "super-service-container"
$dockerHubRepo = "yourdockerhubusername/$dockerImageName"
$dockerTag = "latest"

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
docker build -t $dockerImageName -f "$projectPath\Dockerfile" "$projectPath\publish"
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Docker build failed." -ForegroundColor Red
    exit $LASTEXITCODE
}

# 3. Push the Docker image to Docker Hub (optional step)
# Uncomment the following lines if you want to push to Docker Hub
# Write-Log "Pushing Docker image to Docker Hub..."
# docker tag $dockerImageName $dockerHubRepo:$dockerTag
# docker push $dockerHubRepo:$dockerTag
# if ($LASTEXITCODE -ne 0) {
#     Write-Host "[ERROR] Docker push failed." -ForegroundColor Red
#     exit $LASTEXITCODE
# }

# 4. Deploy and run the image locally or in a public cloud

# Stop and remove any existing container with the same name
docker stop $dockerContainerName
docker rm $dockerContainerName

# Run the Docker container locally
Write-Log "Deploying the Docker container locally..."
docker run -d -p 5000:80 --name $dockerContainerName $dockerImageName
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Docker run failed." -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Log "Deployment successful. Application is running at http://localhost:5000"
Dockerfile
Create a Dockerfile in the super-service directory to package the .NET Core application.

Dockerfile
Copy code
# Use the .NET Core runtime as the base image
FROM mcr.microsoft.com/dotnet/aspnet:7.0 AS base
WORKDIR /app
EXPOSE 80

# Use the .NET SDK to build the application
FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
WORKDIR /src
COPY ["SuperService.Api/SuperService.Api.csproj", "SuperService.Api/"]
RUN dotnet restore "SuperService.Api/SuperService.Api.csproj"
COPY . .
WORKDIR "/src/SuperService.Api"
RUN dotnet build "SuperService.Api.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "SuperService.Api.csproj" -c Release -o /app/publish

# Final stage: copy the build and run the application
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "SuperService.Api.dll"]