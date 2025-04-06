$env:artemis.instance = "C:\Apps/apartemisapache-artemis-2.40.0\instance"
# Define the paths for templates and output
$templateDir = "./artemis"
$outputDir = "./artemis/tmp/spoke-03"

# Make sure the output directory exists
if (-Not (Test-Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory
}

# Perform environment variable substitution using PowerShell

# Login config
Get-Content "$templateDir\login.config" | ForEach-Object { $_ -replace '\${artemis.instance}', $env:artemis.instance } | Set-Content "$outputDir\login.config"

# Keycloak bearer token JSON
Get-Content "$templateDir\keycloak-bearer-token.template.json" | ForEach-Object { $_ -replace '\${artemis.instance}', $env:artemis.instance } | Set-Content "$outputDir\keycloak-bearer-token.json"

# Keycloak direct access JSON
Get-Content "$templateDir\keycloak-direct-access.template.json" | ForEach-Object { $_ -replace '\${artemis.instance}', $env:artemis.instance } | Set-Content "$outputDir\keycloak-direct-access.json"

# Keycloak JS client JSON
Get-Content "$templateDir\keycloak-js-client.template.json" | ForEach-Object { $_ -replace '\${artemis.instance}', $env:artemis.instance } | Set-Content "$outputDir\keycloak-js-client.json"

# Spoke broker properties
Get-Content "$templateDir\spoke-03-broker.template.properties" | ForEach-Object { $_ -replace '\${artemis.instance}', $env:artemis.instance } | Set-Content "$outputDir\spoke-03-broker.properties"
