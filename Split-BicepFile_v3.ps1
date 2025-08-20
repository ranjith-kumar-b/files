# Improved Bicep File Splitter with Proper Dependency Management
# This script splits a large Bicep file into smaller modules and properly handles cross-module dependencies
# Fixes resource reference issues by creating proper module interfaces

param(
    [Parameter(Mandatory=$true)]
    [string]$InputFile = "main.bicep",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputDir = "bicep-modules"
)

# Create output directory
if (!(Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

Write-Host "Reading Bicep file: $InputFile" -ForegroundColor Green

# Read the entire Bicep file
$bicepContent = Get-Content $InputFile -Raw

# Define resource type mappings with deployment order consideration
$resourceCategories = @{
    'identity' = @{
        'order' = 1
        'types' = @('Microsoft.ManagedIdentity/userAssignedIdentities')
    }
    'networking' = @{
        'order' = 2
        'types' = @(
            'Microsoft.Network/networkSecurityGroups',
            'Microsoft.Network/virtualNetworks',
            'Microsoft.Network/publicIPAddresses',
            'Microsoft.Network/networkInterfaces',
            'Microsoft.Network/applicationGateways',
            'Microsoft.Network/loadBalancers',
            'Microsoft.Network/natGateways'
        )
    }
    'storage' = @{
        'order' = 3
        'types' = @('Microsoft.Storage/storageAccounts')
    }
    'keyvault' = @{
        'order' = 4
        'types' = @('Microsoft.KeyVault/vaults')
    }
    'compute' = @{
        'order' = 5
        'types' = @(
            'Microsoft.Compute/virtualMachines',
            'Microsoft.Compute/sshPublicKeys',
            'Microsoft.Compute/disks',
            'Microsoft.Compute/virtualMachineScaleSets',
            'Microsoft.Compute/availabilitySets'
        )
    }
    'database' = @{
        'order' = 6
        'types' = @(
            'Microsoft.Sql/servers',
            'Microsoft.Sql/servers/databases',
            'Microsoft.DBforPostgreSQL/servers',
            'Microsoft.DocumentDB/databaseAccounts'
        )
    }
    'monitoring' = @{
        'order' = 7
        'types' = @(
            'Microsoft.OperationalInsights/workspaces',
            'Microsoft.Insights/components',
            'Microsoft.Portal/dashboards',
            'Microsoft.Insights/actionGroups',
            'Microsoft.Insights/metricalerts'
        )
    }
    'containers' = @{
        'order' = 8
        'types' = @(
            'Microsoft.ContainerRegistry/registries',
            'Microsoft.App/containerApps',
            'Microsoft.App/managedEnvironments'
        )
    }
    'web' = @{
        'order' = 9
        'types' = @(
            'Microsoft.Web/staticSites',
            'Microsoft.Web/sites',
            'Microsoft.Web/serverfarms'
        )
    }
    'cdn' = @{
        'order' = 10
        'types' = @(
            'Microsoft.Cdn/profiles',
            'Microsoft.Cdn/profiles/endpoints'
        )
    }
}

# Global variables to store analysis
$globalParameters = @{}
$globalVariables = @{}
$globalOutputs = @{}
$allResourceDeclarations = @{}
$crossModuleDependencies = @{}

# Function to extract parameters with detailed analysis
function Get-Parameters {
    param([string]$content)
    
    Write-Host "Extracting parameters..." -ForegroundColor Yellow
    
    $paramPattern = '(?m)^@[^\r\n]*\r?\n\s*param\s+(\w+)\s+([^\r\n=]+)(?:\s*=\s*([^\r\n]+))?|^param\s+(\w+)\s+([^\r\n=]+)(?:\s*=\s*([^\r\n]+))?'
    $parameters = [regex]::Matches($content, $paramPattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)
    
    $paramList = @{}
    foreach ($match in $parameters) {
        if ($match.Groups[1].Success) {
            # Parameter with decorator
            $paramName = $match.Groups[1].Value
            $paramType = $match.Groups[2].Value.Trim()
            $defaultValue = if ($match.Groups[3].Success) { $match.Groups[3].Value.Trim() } else { $null }
            $decorator = $match.Value.Split("`n")[0].Trim()
        } else {
            # Parameter without decorator
            $paramName = $match.Groups[4].Value
            $paramType = $match.Groups[5].Value.Trim()
            $defaultValue = if ($match.Groups[6].Success) { $match.Groups[6].Value.Trim() } else { $null }
            $decorator = ""
        }
        
        $paramList[$paramName] = @{
            'type' = $paramType
            'defaultValue' = $defaultValue
            'decorator' = $decorator
            'fullDeclaration' = $match.Value.Trim()
        }
    }
    
    Write-Host "Found $($paramList.Count) parameters" -ForegroundColor Green
    return $paramList
}

# Function to find matching closing brace with proper nesting support
function Find-MatchingCloseBrace {
    param(
        [string]$content,
        [int]$startPos
    )
    
    $braceCount = 0
    $inString = $false
    $inComment = $false
    $escaped = $false
    
    for ($i = $startPos; $i -lt $content.Length; $i++) {
        $char = $content[$i]
        
        # Handle escape sequences
        if ($escaped) {
            $escaped = $false
            continue
        }
        
        if ($char -eq '\' -and $inString) {
            $escaped = $true
            continue
        }
        
        # Handle single-line comments
        if (!$inString -and $char -eq '/' -and $i + 1 -lt $content.Length -and $content[$i+1] -eq '/') {
            $inComment = $true
            continue
        }
        
        # Handle end of single-line comment
        if ($inComment -and ($char -eq "`r" -or $char -eq "`n")) {
            $inComment = $false
            continue
        }
        
        # Skip if in comment
        if ($inComment) {
            continue
        }
        
        # Handle strings
        if ($char -eq "'" -and !$inString) {
            $inString = $true
            continue
        }
        elseif ($char -eq "'" -and $inString) {
            $inString = $false
            continue
        }
        
        # Skip if in string
        if ($inString) {
            continue
        }
        
        # Count braces
        if ($char -eq '{') {
            $braceCount++
        }
        elseif ($char -eq '}') {
            $braceCount--
            if ($braceCount -eq 0) {
                return $i
            }
        }
    }
    
    return -1
}

# Function to extract all resources with dependency analysis
function Get-AllResources {
    param([string]$content)
    
    Write-Host "Analyzing all resources and dependencies..." -ForegroundColor Yellow
    
    $resources = @{}
    
    # Find all resource declarations
    $resourceStartPattern = "resource\s+(\w+)\s+'([^']+)'\s*="
    $resourceStartMatches = [regex]::Matches($content, $resourceStartPattern)
    
    foreach ($match in $resourceStartMatches) {
        $resourceName = $match.Groups[1].Value
        $resourceTypeWithVersion = $match.Groups[2].Value
        $resourceType = $resourceTypeWithVersion.Split('@')[0]
        
        # Find the start of the resource definition
        $resourceStart = $match.Index
        $braceStart = $content.IndexOf('{', $resourceStart)
        
        if ($braceStart -ne -1) {
            # Find the matching closing brace
            $braceEnd = Find-MatchingCloseBrace -content $content -startPos $braceStart
            
            if ($braceEnd -ne -1) {
                # Extract the complete resource definition
                $resourceContent = $content.Substring($resourceStart, ($braceEnd - $resourceStart + 1))
                
                # Analyze dependencies within this resource
                $dependencies = Get-ResourceDependencies -resourceContent $resourceContent -resourceName $resourceName
                
                $resources[$resourceName] = @{
                    'type' = $resourceType
                    'typeWithVersion' = $resourceTypeWithVersion
                    'content' = $resourceContent.Trim()
                    'dependencies' = $dependencies
                    'category' = Get-ResourceCategory -resourceType $resourceType
                    'exports' = Get-ResourceExports -resourceName $resourceName -resourceContent $resourceContent
                }
                
                Write-Host "Found resource: $resourceName ($resourceType) - Dependencies: $($dependencies -join ', ')" -ForegroundColor Gray
            }
        }
    }
    
    return $resources
}

# Function to determine which category a resource belongs to
function Get-ResourceCategory {
    param([string]$resourceType)
    
    foreach ($category in $resourceCategories.Keys) {
        if ($resourceCategories[$category].types -contains $resourceType) {
            return $category
        }
    }
    return 'misc'
}

# Function to analyze resource dependencies
function Get-ResourceDependencies {
    param(
        [string]$resourceContent,
        [string]$resourceName
    )
    
    $dependencies = @()
    
    # Look for direct resource references (resourceName.property or resourceName)
    $resourceRefPattern = '\b(\w+)\.(?:id|name|properties|outputs)\b|\bdependsOn:\s*\[\s*([^\]]+)\s*\]'
    $refMatches = [regex]::Matches($resourceContent, $resourceRefPattern)
    
    foreach ($match in $refMatches) {
        if ($match.Groups[1].Success) {
            $refName = $match.Groups[1].Value
            if ($refName -ne $resourceName -and $refName -notmatch '^(location|resourceGroup|subscription|tenant|deployment|environment)$') {
                $dependencies += $refName
            }
        }
        if ($match.Groups[2].Success) {
            # Parse dependsOn array
            $dependsOnContent = $match.Groups[2].Value
            $depRefs = $dependsOnContent -split ',' | ForEach-Object { 
                $dep = $_.Trim()
                if ($dep -match '^\s*(\w+)\s*$') {
                    $Matches[1]
                }
            } | Where-Object { $_ -and $_ -ne $resourceName }
            $dependencies += $depRefs
        }
    }
    
    return $dependencies | Select-Object -Unique
}

# Function to identify what a resource exports (for use by other resources)
function Get-ResourceExports {
    param(
        [string]$resourceName,
        [string]$resourceContent
    )
    
    $exports = @{
        'id' = "$resourceName.id"
        'name' = "$resourceName.name"
    }
    
    # Analyze resource type for common exports
    if ($resourceContent -match "Microsoft\.Network/networkInterfaces") {
        $exports['privateIPAddress'] = "$resourceName.properties.ipConfigurations[0].properties.privateIPAddress"
    }
    elseif ($resourceContent -match "Microsoft\.Network/publicIPAddresses") {
        $exports['ipAddress'] = "$resourceName.properties.ipAddress"
        $exports['fqdn'] = "$resourceName.properties.dnsSettings.fqdn"
    }
    elseif ($resourceContent -match "Microsoft\.Storage/storageAccounts") {
        $exports['primaryEndpoints'] = "$resourceName.properties.primaryEndpoints"
        $exports['primaryKey'] = "listKeys($resourceName.id, $resourceName.apiVersion).keys[0].value"
    }
    elseif ($resourceContent -match "Microsoft\.KeyVault/vaults") {
        $exports['vaultUri'] = "$resourceName.properties.vaultUri"
    }
    
    return $exports
}

# Function to extract variables
function Get-Variables {
    param([string]$content)
    
    $variables = @{}
    $varPattern = '(?m)^var\s+(\w+)\s*=\s*(.+?)(?=\r?\n\s*(?:param\s+|resource\s+|module\s+|output\s+|var\s+|@|$))'
    $varMatches = [regex]::Matches($content, $varPattern, [System.Text.RegularExpressions.RegexOptions]::Multiline -bor [System.Text.RegularExpressions.RegexOptions]::Singleline)
    
    foreach ($match in $varMatches) {
        $varName = $match.Groups[1].Value
        $varValue = $match.Groups[2].Value.Trim()
        $variables[$varName] = @{
            'value' = $varValue
            'fullDeclaration' = $match.Value.Trim()
        }
    }
    
    return $variables
}

# Function to extract outputs
function Get-Outputs {
    param([string]$content)
    
    $outputs = @{}
    $outputPattern = '(?m)^output\s+(\w+)\s+([^\r\n=]+)\s*=\s*(.+?)(?=\r?\n\s*(?:param\s+|resource\s+|module\s+|output\s+|var\s+|@|$))'
    $outputMatches = [regex]::Matches($content, $outputPattern, [System.Text.RegularExpressions.RegexOptions]::Multiline -bor [System.Text.RegularExpressions.RegexOptions]::Singleline)
    
    foreach ($match in $outputMatches) {
        $outputName = $match.Groups[1].Value
        $outputType = $match.Groups[2].Value.Trim()
        $outputValue = $match.Groups[3].Value.Trim()
        $outputs[$outputName] = @{
            'type' = $outputType
            'value' = $outputValue
            'fullDeclaration' = $match.Value.Trim()
        }
    }
    
    return $outputs
}

# Function to analyze cross-module dependencies
function Get-CrossModuleDependencies {
    param([hashtable]$allResources)
    
    Write-Host "Analyzing cross-module dependencies..." -ForegroundColor Yellow
    
    $crossDeps = @{}
    
    foreach ($resourceName in $allResources.Keys) {
        $resource = $allResources[$resourceName]
        $resourceCategory = $resource.category
        
        $crossDeps[$resourceCategory] = @{
            'dependsOn' = @()
            'provides' = @()
        }
    }
    
    # Analyze dependencies between categories
    foreach ($resourceName in $allResources.Keys) {
        $resource = $allResources[$resourceName]
        $resourceCategory = $resource.category
        
        foreach ($dependency in $resource.dependencies) {
            if ($allResources.ContainsKey($dependency)) {
                $depCategory = $allResources[$dependency].category
                if ($depCategory -ne $resourceCategory) {
                    if ($crossDeps[$resourceCategory].dependsOn -notcontains $depCategory) {
                        $crossDeps[$resourceCategory].dependsOn += $depCategory
                    }
                    if ($crossDeps[$depCategory].provides -notcontains $resourceCategory) {
                        $crossDeps[$depCategory].provides += $resourceCategory
                    }
                }
            }
        }
    }
    
    return $crossDeps
}

# Function to create a module with proper parameters and outputs
function New-ModuleFile {
    param(
        [string]$category,
        [hashtable]$categoryResources,
        [hashtable]$requiredParameters,
        [hashtable]$requiredVariables,
        [array]$dependentCategories
    )
    
    Write-Host "Creating module: $category.bicep" -ForegroundColor Yellow
    
    $moduleContent = @()
    
    # Add module header
    $moduleContent += "// Module: $category"
    $moduleContent += "// Auto-generated from main.bicep"
    $moduleContent += ""
    
    # Add parameters (both original and cross-module)
    $moduleContent += "// === PARAMETERS ==="
    
    foreach ($paramName in $requiredParameters.Keys) {
        $param = $requiredParameters[$paramName]
        if ($param.decorator) {
            $moduleContent += $param.decorator
        }
        $paramDecl = "param $paramName $($param.type)"
        if ($param.defaultValue) {
            $paramDecl += " = $($param.defaultValue)"
        }
        $moduleContent += $paramDecl
        $moduleContent += ""
    }
    
    # Add cross-module parameters for dependencies
    foreach ($depCategory in $dependentCategories) {
        $moduleContent += "// Parameters from $depCategory module"
        
        # Analyze what this module needs from the dependency
        $neededRefs = Get-CrossModuleReferences -category $category -dependencyCategory $depCategory -allResources $allResourceDeclarations
        
        foreach ($ref in $neededRefs) {
            $paramType = Get-ParameterTypeForReference -reference $ref
            $moduleContent += "param $($ref.paramName) $paramType"
        }
        $moduleContent += ""
    }
    
    # Add variables that are used in this module
    if ($requiredVariables.Count -gt 0) {
        $moduleContent += "// === VARIABLES ==="
        foreach ($varName in $requiredVariables.Keys) {
            $moduleContent += $requiredVariables[$varName].fullDeclaration
        }
        $moduleContent += ""
    }
    
    # Add resources
    $moduleContent += "// === RESOURCES ==="
    foreach ($resourceName in $categoryResources.Keys) {
        $resource = $categoryResources[$resourceName]
        $cleanedContent = Repair-ResourceReferences -resourceContent $resource.content -category $category -dependentCategories $dependentCategories
        $moduleContent += $cleanedContent
        $moduleContent += ""
    }
    
    # Add outputs for resources that other modules might need
    $moduleContent += "// === OUTPUTS ==="
    foreach ($resourceName in $categoryResources.Keys) {
        $resource = $categoryResources[$resourceName]
        $exports = $resource.exports
        
        foreach ($exportName in $exports.Keys) {
            $outputName = "$($resourceName)_$exportName"
            $outputValue = $exports[$exportName]
            
            # Determine output type based on export
            $outputType = switch ($exportName) {
                'id' { 'string' }
                'name' { 'string' }
                'ipAddress' { 'string' }
                'fqdn' { 'string' }
                'privateIPAddress' { 'string' }
                'vaultUri' { 'string' }
                'primaryKey' { 'string' }
                'primaryEndpoints' { 'object' }
                default { 'string' }
            }
            
            $moduleContent += "output $outputName $outputType = $outputValue"
        }
    }
    
    # Write the module file
    $moduleFileName = "$OutputDir/$category.bicep"
    ($moduleContent -join "`r`n") | Out-File -FilePath $moduleFileName -Encoding UTF8
    
    Write-Host "Created: $moduleFileName" -ForegroundColor Green
}

# Function to get cross-module references
function Get-CrossModuleReferences {
    param(
        [string]$category,
        [string]$dependencyCategory,
        [hashtable]$allResources
    )
    
    $references = @()
    
    # Get resources in this category that depend on resources in dependency category
    $categoryResources = $allResources.Values | Where-Object { $_.category -eq $category }
    
    foreach ($resource in $categoryResources) {
        foreach ($dep in $resource.dependencies) {
            $depResource = $allResources[$dep]
            if ($depResource -and $depResource.category -eq $dependencyCategory) {
                # This resource depends on a resource from dependency category
                foreach ($exportName in $depResource.exports.Keys) {
                    $references += @{
                        'resourceName' = $dep
                        'exportName' = $exportName
                        'paramName' = "$($dep)_$exportName"
                    }
                }
            }
        }
    }
    
    return $references | Sort-Object paramName | Get-Unique -AsString
}

# Function to determine parameter type for a reference
function Get-ParameterTypeForReference {
    param([hashtable]$reference)
    
    switch ($reference.exportName) {
        'id' { return 'string' }
        'name' { return 'string' }
        'ipAddress' { return 'string' }
        'fqdn' { return 'string' }
        'privateIPAddress' { return 'string' }
        'vaultUri' { return 'string' }
        'primaryKey' { return 'string' }
        'primaryEndpoints' { return 'object' }
        default { return 'string' }
    }
}

# Function to fix resource references within modules
function Repair-ResourceReferences {
    param(
        [string]$resourceContent,
        [string]$category,
        [array]$dependentCategories
    )
    
    # Replace cross-module references with parameter references
    $fixedContent = $resourceContent
    
    foreach ($resourceName in $allResourceDeclarations.Keys) {
        $resource = $allResourceDeclarations[$resourceName]
        if ($resource.category -ne $category) {
            # This is a cross-module reference - replace with parameter
            foreach ($exportName in $resource.exports.Keys) {
                $originalRef = $resource.exports[$exportName]
                $paramName = "$($resourceName)_$exportName"
                
                # Replace the reference pattern
                $pattern = [regex]::Escape($resourceName) + '\.(' + [regex]::Escape($exportName) + '|id|name)'
                $fixedContent = [regex]::Replace($fixedContent, $pattern, $paramName)
            }
        }
    }
    
    return $fixedContent
}

# Function to create main orchestration file
function New-OrchestrationFile {
    param([hashtable]$crossModuleDeps)
    
    Write-Host "Creating main orchestration file..." -ForegroundColor Yellow
    
    $mainContent = @()
    
    # Add header
    $mainContent += "// Main orchestration file for modular Bicep deployment"
    $mainContent += "// Auto-generated from main.bicep"
    $mainContent += ""
    
    # Add all original parameters
    $mainContent += "// === ORIGINAL PARAMETERS ==="
    foreach ($paramName in $globalParameters.Keys) {
        $param = $globalParameters[$paramName]
        if ($param.decorator) {
            $mainContent += $param.decorator
        }
        $paramDecl = "param $paramName $($param.type)"
        if ($param.defaultValue) {
            $paramDecl += " = $($param.defaultValue)"
        }
        $mainContent += $paramDecl
    }
    $mainContent += ""
    
    # Add all original variables
    if ($globalVariables.Count -gt 0) {
        $mainContent += "// === ORIGINAL VARIABLES ==="
        foreach ($varName in $globalVariables.Keys) {
            $mainContent += $globalVariables[$varName].fullDeclaration
        }
        $mainContent += ""
    }
    
    # Add modules in dependency order
    $mainContent += "// === MODULES ==="
    
    $sortedCategories = $resourceCategories.Keys | Sort-Object { $resourceCategories[$_].order }
    
    foreach ($category in $sortedCategories) {
        $moduleFile = "$category.bicep"
        $moduleFilePath = "$OutputDir/$moduleFile"
        
        if (Test-Path $moduleFilePath) {
            $mainContent += "// $category module"
            
            # Get dependencies for this module
            $moduleDeps = if ($crossModuleDeps.ContainsKey($category)) { $crossModuleDeps[$category].dependsOn } else { @() }
            
            $moduleDecl = @()
            $moduleDecl += "module $category './$moduleFile' = {"
            $moduleDecl += "  name: '$category-deployment'"
            
            # Add parameters
            $moduleDecl += "  params: {"
            
            # Add original parameters that this module needs
            $categoryResources = $allResourceDeclarations.Values | Where-Object { $_.category -eq $category }
            $usedParams = Get-UsedParameters -resources $categoryResources
            
            foreach ($paramName in $usedParams) {
                $moduleDecl += "    $($paramName): $paramName"
            }
            
            # Add cross-module parameters
            foreach ($depCategory in $moduleDeps) {
                $crossRefs = Get-CrossModuleReferences -category $category -dependencyCategory $depCategory -allResources $allResourceDeclarations
                foreach ($ref in $crossRefs) {
                    $moduleDecl += "    $($ref.paramName): $depCategory.outputs.$($ref.paramName)"
                }
            }
            
            $moduleDecl += "  }"
            
            # Add dependencies
            if ($moduleDeps.Count -gt 0) {
                $validDeps = $moduleDeps | Where-Object { Test-Path "$OutputDir/$_.bicep" }
                if ($validDeps.Count -gt 0) {
                    $moduleDecl += "  dependsOn: ["
                    $moduleDecl += ($validDeps | ForEach-Object { "    $_" }) -join "`r`n"
                    $moduleDecl += "  ]"
                }
            }
            
            $moduleDecl += "}"
            
            $mainContent += ($moduleDecl -join "`r`n")
            $mainContent += ""
        }
    }
    
    # Add outputs
    if ($globalOutputs.Count -gt 0) {
        $mainContent += "// === OUTPUTS ==="
        foreach ($outputName in $globalOutputs.Keys) {
            $output = $globalOutputs[$outputName]
            $fixedOutput = Repair-OutputReferences -outputContent $output.fullDeclaration
            $mainContent += $fixedOutput
        }
    }
    
    # Write the main file
    $mainFileName = "$OutputDir/main.bicep"
    ($mainContent -join "`r`n") | Out-File -FilePath $mainFileName -Encoding UTF8
    
    Write-Host "Created: $mainFileName" -ForegroundColor Green
}

# Function to get parameters used by resources
function Get-UsedParameters {
    param([array]$resources)
    
    $usedParams = @()
    
    foreach ($resource in $resources) {
        foreach ($paramName in $globalParameters.Keys) {
            if ($resource.content -match "\b$paramName\b") {
                $usedParams += $paramName
            }
        }
    }
    
    return $usedParams | Select-Object -Unique
}

# Function to fix output references to use module outputs
function Repair-OutputReferences {
    param([string]$outputContent)
    
    $fixedContent = $outputContent
    
    foreach ($resourceName in $allResourceDeclarations.Keys) {
        $resource = $allResourceDeclarations[$resourceName]
        $category = $resource.category
        
        # Replace resource references with module output references
        $pattern = "\b$resourceName\.(id|name|properties\.[^\s\}]+)"
        $replacement = "$category.outputs.$($resourceName)_`$1"
        $fixedContent = [regex]::Replace($fixedContent, $pattern, $replacement)
    }
    
    return $fixedContent
}

# Function to create parameter files for each module
function New-ModuleParameterFile {
    param(
        [string]$category,
        [array]$requiredParams
    )
    
    $paramEntries = @()
    foreach ($param in $requiredParams) {
        $paramEntries += @"
    "$param": {
      "value": "// TODO: Set value for $param"
    }
"@
    }
    
    $paramFile = @"
{
  "`$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
$($paramEntries -join ",`r`n")
  }
}
"@
    
    $paramFileName = "$OutputDir/$category.parameters.json"
    $paramFile | Out-File -FilePath $paramFileName -Encoding UTF8
    Write-Host "Created parameter file: $paramFileName" -ForegroundColor Green
}

# Function to create deployment scripts
function New-DeploymentScripts {
    # Individual module deployment script
    $deployScript = @"
# Deploy individual Bicep module
param(
    [Parameter(Mandatory=`$true)]
    [string]`$ResourceGroupName,
    
    [Parameter(Mandatory=`$true)]
    [string]`$ModuleName,
    
    [Parameter(Mandatory=`$false)]
    [string]`$ParametersFile = "`$ModuleName.parameters.json"
)

Write-Host "Deploying module: `$ModuleName to resource group: `$ResourceGroupName" -ForegroundColor Green

`$bicepFile = "./`$ModuleName.bicep"

if (!(Test-Path `$bicepFile)) {
    Write-Error "Bicep file not found: `$bicepFile"
    exit 1
}

try {
    if (Test-Path `$ParametersFile) {
        `$result = az deployment group create ``
            --resource-group `$ResourceGroupName ``
            --template-file `$bicepFile ``
            --parameters @`$ParametersFile ``
            --output json | ConvertFrom-Json
    } else {
        `$result = az deployment group create ``
            --resource-group `$ResourceGroupName ``
            --template-file `$bicepFile ``
            --output json | ConvertFrom-Json
    }
    
    if (`$result.properties.provisioningState -eq "Succeeded") {
        Write-Host "Module `$ModuleName deployed successfully!" -ForegroundColor Green
    } else {
        Write-Error "Deployment failed for module: `$ModuleName"
        exit 1
    }
}
catch {
    Write-Error "Failed to deploy module `$ModuleName`: `$_"
    exit 1
}
"@
    
    $deployScript | Out-File -FilePath "$OutputDir/deploy-module.ps1" -Encoding UTF8
    
    # Full orchestration deployment script
    $fullDeployScript = @"
# Deploy complete Bicep solution using main orchestration file
param(
    [Parameter(Mandatory=`$true)]
    [string]`$ResourceGroupName,
    
    [Parameter(Mandatory=`$false)]
    [string]`$ParametersFile = "main.parameters.json"
)

Write-Host "Deploying complete solution to resource group: `$ResourceGroupName" -ForegroundColor Green

`$bicepFile = "./main.bicep"

if (!(Test-Path `$bicepFile)) {
    Write-Error "Main Bicep file not found: `$bicepFile"
    exit 1
}

try {
    Write-Host "Validating deployment..." -ForegroundColor Yellow
    
    if (Test-Path `$ParametersFile) {
        az deployment group validate ``
            --resource-group `$ResourceGroupName ``
            --template-file `$bicepFile ``
            --parameters @`$ParametersFile
    } else {
        az deployment group validate ``
            --resource-group `$ResourceGroupName ``
            --template-file `$bicepFile
    }
    
    if (`$LASTEXITCODE -eq 0) {
        Write-Host "Validation successful. Starting deployment..." -ForegroundColor Green
        
        if (Test-Path `$ParametersFile) {
            `$result = az deployment group create ``
                --resource-group `$ResourceGroupName ``
                --template-file `$bicepFile ``
                --parameters @`$ParametersFile ``
                --output json | ConvertFrom-Json
        } else {
            `$result = az deployment group create ``
                --resource-group `$ResourceGroupName ``
                --template-file `$bicepFile ``
                --output json | ConvertFrom-Json
        }
        
        if (`$result.properties.provisioningState -eq "Succeeded") {
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
    Write-Error "Failed to deploy solution: `$_"
    exit 1
}
"@
    
    $fullDeployScript | Out-File -FilePath "$OutputDir/deploy-all.ps1" -Encoding UTF8
    
    # Validation script
    $validationScript = @"
# Validate all Bicep modules
param(
    [Parameter(Mandatory=`$true)]
    [string]`$ResourceGroupName
)

Write-Host "Validating all Bicep modules..." -ForegroundColor Cyan

`$allValid = `$true
`$modules = Get-ChildItem -Path "." -Filter "*.bicep" | Where-Object { `$_.Name -ne "main.bicep" }

foreach (`$module in `$modules) {
    Write-Host "Validating `$(`$module.BaseName)..." -ForegroundColor Yellow
    
    try {
        `$paramFile = "`$(`$module.BaseName).parameters.json"
        if (Test-Path `$paramFile) {
            az deployment group validate ``
                --resource-group `$ResourceGroupName ``
                --template-file `$module.Name ``
                --parameters @`$paramFile
        } else {
            az deployment group validate ``
                --resource-group `$ResourceGroupName ``
                --template-file `$module.Name
        }
        
        if (`$LASTEXITCODE -eq 0) {
            Write-Host "`$(`$module.BaseName) validation: PASSED" -ForegroundColor Green
        } else {
            Write-Host "`$(`$module.BaseName) validation: FAILED" -ForegroundColor Red
            `$allValid = `$false
        }
    }
    catch {
        Write-Host "`$(`$module.BaseName) validation: FAILED - `$_" -ForegroundColor Red
        `$allValid = `$false
    }
}

Write-Host "`nValidating main orchestration file..." -ForegroundColor Yellow
try {
    az deployment group validate ``
        --resource-group `$ResourceGroupName ``
        --template-file "main.bicep"
        
    if (`$LASTEXITCODE -eq 0) {
        Write-Host "Main orchestration validation: PASSED" -ForegroundColor Green
    } else {
        Write-Host "Main orchestration validation: FAILED" -ForegroundColor Red
        `$allValid = `$false
    }
}
catch {
    Write-Host "Main orchestration validation: FAILED - `$_" -ForegroundColor Red
    `$allValid = `$false
}

if (`$allValid) {
    Write-Host "`nAll validations PASSED!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nSome validations FAILED!" -ForegroundColor Red
    exit 1
}
"@
    
    $validationScript | Out-File -FilePath "$OutputDir/validate-all.ps1" -Encoding UTF8
    
    Write-Host "Created deployment scripts:" -ForegroundColor Green
    Write-Host "  - deploy-module.ps1 (deploy individual modules)" -ForegroundColor White
    Write-Host "  - deploy-all.ps1 (deploy complete solution)" -ForegroundColor White
    Write-Host "  - validate-all.ps1 (validate all modules)" -ForegroundColor White
}

# Function to create main parameter file
function New-MainParameterFile {
    $paramEntries = @()
    foreach ($paramName in $globalParameters.Keys) {
        $param = $globalParameters[$paramName]
        $paramEntries += @"
    "$paramName": {
      "value": "// TODO: Set value for $paramName (type: $($param.type))"
    }
"@
    }
    
    $paramFile = @"
{
  "`$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
$($paramEntries -join ",`r`n")
  }
}
"@
    
    $paramFileName = "$OutputDir/main.parameters.json"
    $paramFile | Out-File -FilePath $paramFileName -Encoding UTF8
    Write-Host "Created main parameter file: $paramFileName" -ForegroundColor Green
}

# Main execution starts here
Write-Host "Starting enhanced Bicep file analysis and modularization..." -ForegroundColor Cyan

# Step 1: Parse the entire file and extract all components
Write-Host "`n=== STEP 1: PARSING BICEP FILE ===" -ForegroundColor Cyan
$globalParameters = Get-Parameters -content $bicepContent
$globalVariables = Get-Variables -content $bicepContent
$globalOutputs = Get-Outputs -content $bicepContent
$allResourceDeclarations = Get-AllResources -content $bicepContent

Write-Host "Parsed $($globalParameters.Count) parameters, $($globalVariables.Count) variables, $($globalOutputs.Count) outputs, $($allResourceDeclarations.Count) resources" -ForegroundColor Green

# Step 2: Analyze cross-module dependencies
Write-Host "`n=== STEP 2: ANALYZING DEPENDENCIES ===" -ForegroundColor Cyan
$crossModuleDependencies = Get-CrossModuleDependencies -allResources $allResourceDeclarations

# Step 3: Group resources by category and create modules
Write-Host "`n=== STEP 3: CREATING MODULES ===" -ForegroundColor Cyan

$createdModules = @()

# Sort categories by deployment order
$sortedCategories = $resourceCategories.Keys | Sort-Object { $resourceCategories[$_].order }

foreach ($category in $sortedCategories) {
    # Get resources for this category
    $categoryResources = @{}
    foreach ($resourceName in $allResourceDeclarations.Keys) {
        $resource = $allResourceDeclarations[$resourceName]
        if ($resource.category -eq $category) {
            $categoryResources[$resourceName] = $resource
        }
    }
    
    if ($categoryResources.Count -gt 0) {
        Write-Host "Processing category: $category ($($categoryResources.Count) resources)" -ForegroundColor Yellow
        
        # Determine required parameters for this module
        $requiredParams = @{}
        $requiredVars = @{}
        
        # Analyze which parameters and variables are used by resources in this category
        foreach ($resourceName in $categoryResources.Keys) {
            $resourceContent = $categoryResources[$resourceName].content
            
            # Check parameter usage
            foreach ($paramName in $globalParameters.Keys) {
                if ($resourceContent -match "\b$paramName\b") {
                    $requiredParams[$paramName] = $globalParameters[$paramName]
                }
            }
            
            # Check variable usage
            foreach ($varName in $globalVariables.Keys) {
                if ($resourceContent -match "\b$varName\b") {
                    $requiredVars[$varName] = $globalVariables[$varName]
                }
            }
        }
        
        # Get dependent categories (categories this module depends on)
        $dependentCategories = if ($crossModuleDependencies.ContainsKey($category)) { 
            $crossModuleDependencies[$category].dependsOn 
        } else { 
            @() 
        }
        
        # Create the module
        New-ModuleFile -category $category -categoryResources $categoryResources -requiredParameters $requiredParams -requiredVariables $requiredVars -dependentCategories $dependentCategories
        
        # Create parameter file for this module
        $allRequiredParams = $requiredParams.Keys
        # Add cross-module parameters
        foreach ($depCategory in $dependentCategories) {
            $crossRefs = Get-CrossModuleReferences -category $category -dependencyCategory $depCategory -allResources $allResourceDeclarations
            $allRequiredParams += ($crossRefs | ForEach-Object { $_.paramName })
        }
        
        if ($allRequiredParams.Count -gt 0) {
            New-ModuleParameterFile -category $category -requiredParams $allRequiredParams
        }
        
        $createdModules += $category
    }
}

# Step 4: Create main orchestration file
Write-Host "`n=== STEP 4: CREATING ORCHESTRATION FILE ===" -ForegroundColor Cyan
New-OrchestrationFile -crossModuleDeps $crossModuleDependencies

# Step 5: Create parameter file for main orchestration
New-MainParameterFile

# Step 6: Create deployment scripts
Write-Host "`n=== STEP 5: CREATING DEPLOYMENT SCRIPTS ===" -ForegroundColor Cyan
New-DeploymentScripts

# Step 7: Create README file
$readmeContent = @"
# Modularized Bicep Deployment

This directory contains a modularized version of your original Bicep file, split into logical modules with proper dependency management.

## Files Created

### Module Files
$($createdModules | ForEach-Object { "- **$_.bicep** - $_ resources" } | Out-String)

### Configuration Files
- **main.bicep** - Main orchestration file that deploys all modules
- **main.parameters.json** - Parameters for main deployment
$($createdModules | ForEach-Object { "- **$_.parameters.json** - Parameters for $_ module" } | Out-String)

### Deployment Scripts
- **deploy-all.ps1** - Deploy the complete solution using main.bicep
- **deploy-module.ps1** - Deploy individual modules
- **validate-all.ps1** - Validate all modules before deployment

## Deployment Order

The modules are deployed in the following order to handle dependencies:
$($sortedCategories | ForEach-Object { 
    $order = $resourceCategories[$_].order
    if ($createdModules -contains $_) {
        "$order. $_"
    }
} | Where-Object { $_ } | Out-String)

## Usage

### Option 1: Deploy Complete Solution
``````powershell
# Update main.parameters.json with your values
./deploy-all.ps1 -ResourceGroupName "your-resource-group"
``````

### Option 2: Deploy Individual Modules
``````powershell
# Deploy modules one by one (useful for testing)
./deploy-module.ps1 -ResourceGroupName "your-resource-group" -ModuleName "networking"
./deploy-module.ps1 -ResourceGroupName "your-resource-group" -ModuleName "compute"
``````

### Validation
``````powershell
# Validate all modules before deployment
./validate-all.ps1 -ResourceGroupName "your-resource-group"
``````

## Cross-Module Dependencies

The following dependencies have been identified and handled:
$($crossModuleDependencies.Keys | ForEach-Object {
    $category = $_
    $deps = $crossModuleDependencies[$category].dependsOn
    if ($deps.Count -gt 0) {
        "- **$category** depends on: $($deps -join ', ')"
    }
} | Where-Object { $_ } | Out-String)

## Next Steps

1. **Review Parameters**: Update all .parameters.json files with your actual values
2. **Test Validation**: Run validate-all.ps1 to check for any issues
3. **Deploy**: Use deploy-all.ps1 for full deployment or deploy-module.ps1 for individual modules
4. **Monitor**: Check Azure portal for deployment status and any issues

## Troubleshooting

- If you get dependency errors, ensure modules are deployed in the correct order
- Check parameter files for missing or incorrect values
- Use validate-all.ps1 to identify syntax or configuration issues before deployment
- Individual modules can be deployed separately for easier debugging
"@

$readmeContent | Out-File -FilePath "$OutputDir/README.md" -Encoding UTF8

# Final summary
Write-Host "`n=== MODULARIZATION COMPLETE ===" -ForegroundColor Green
Write-Host "Output directory: $OutputDir" -ForegroundColor Cyan
Write-Host "`nFiles created:" -ForegroundColor Cyan
Get-ChildItem $OutputDir | Sort-Object Name | ForEach-Object { 
    $size = [math]::Round($_.Length / 1KB, 1)
    Write-Host "  - $($_.Name) ($size KB)" -ForegroundColor White 
}

Write-Host "`nModule Summary:" -ForegroundColor Yellow
foreach ($category in $createdModules) {
    $resourceCount = ($allResourceDeclarations.Values | Where-Object { $_.category -eq $category }).Count
    $dependencies = if ($crossModuleDependencies.ContainsKey($category)) { $crossModuleDependencies[$category].dependsOn.Count } else { 0 }
    Write-Host "  - $category`: $resourceCount resources, $dependencies dependencies" -ForegroundColor White
}

Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Review and update parameter files with actual values" -ForegroundColor White
Write-Host "2. Run validation: powershell $OutputDir/validate-all.ps1 -ResourceGroupName 'your-rg'" -ForegroundColor White
Write-Host "3. Deploy: powershell $OutputDir/deploy-all.ps1 -ResourceGroupName 'your-rg'" -ForegroundColor White
Write-Host "4. Check $OutputDir/README.md for detailed instructions" -ForegroundColor White

Write-Host "`nKey Improvements:" -ForegroundColor Green
Write-Host "✓ Proper cross-module dependency management" -ForegroundColor Green
Write-Host "✓ Resource references converted to module parameters" -ForegroundColor Green
Write-Host "✓ Outputs created for inter-module communication" -ForegroundColor Green
Write-Host "✓ Deployment order based on dependencies" -ForegroundColor Green
Write-Host "✓ Comprehensive validation and deployment scripts" -ForegroundColor Green