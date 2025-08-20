# Deploy complete Bicep solution using main orchestration file
param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$ParametersFile = "main.parameters.json"
)

Write-Host "Deploying complete solution to resource group: $ResourceGroupName" -ForegroundColor Green

$bicepFile = "./main.bicep"

if (!(Test-Path $bicepFile)) {
    Write-Error "Main Bicep file not found: $bicepFile"
    exit 1
}

try {
    Write-Host "Validating deployment..." -ForegroundColor Yellow
    
    if (Test-Path $ParametersFile) {
        az deployment group validate `
            --resource-group $ResourceGroupName `
            --template-file $bicepFile `
            --parameters @$ParametersFile
    } else {
        az deployment group validate `
            --resource-group $ResourceGroupName `
            --template-file $bicepFile
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Validation successful. Starting deployment..." -ForegroundColor Green
        
        if (Test-Path $ParametersFile) {
            $result = az deployment group create `
                --resource-group $ResourceGroupName `
                --template-file $bicepFile `
                --parameters @$ParametersFile `
                --output json | ConvertFrom-Json
        } else {
            $result = az deployment group create `
                --resource-group $ResourceGroupName `
                --template-file $bicepFile `
                --output json | ConvertFrom-Json
        }
        
        if ($result.properties.provisioningState -eq "Succeeded") {
            Write-Host "Complete solution deployed successfully!" -ForegroundColor Green
        } else {
            Write-Error "Deployment failed"
            exit 1
        }
    } else {
        Write-Error "Validation failed"
        exit 1
    }
}
catch {
    Write-Error "Failed to deploy solution: $_"
    exit 1
}
