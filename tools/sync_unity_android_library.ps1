param(
    [Parameter(Mandatory = $true)]
    [string]$ExportPath
)

$ErrorActionPreference = 'Stop'
$resolvedExport = (Resolve-Path -LiteralPath $ExportPath).Path
$source = Join-Path $resolvedExport 'unityLibrary'
$sourceBuildFile = Join-Path $source 'build.gradle'
if (-not (Test-Path -LiteralPath $sourceBuildFile)) {
    throw "Unity export is missing unityLibrary/build.gradle: $resolvedExport"
}
$sharedSource = Join-Path $resolvedExport 'shared'
$propertiesSource = Join-Path $resolvedExport 'gradle.properties'
$requiredSharedFiles = @('common.gradle', 'keepUnitySymbols.gradle')
foreach ($requiredSharedFile in $requiredSharedFiles) {
    if (-not (Test-Path -LiteralPath (Join-Path $sharedSource $requiredSharedFile))) {
        throw "Unity export is missing shared/$requiredSharedFile`: $resolvedExport"
    }
}
if (-not (Test-Path -LiteralPath $propertiesSource)) {
    throw "Unity export is missing gradle.properties: $resolvedExport"
}

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$androidRoot = Join-Path $repositoryRoot 'flutter\android'
$destination = Join-Path $androidRoot 'unityLibrary'
$sharedDestination = Join-Path $androidRoot 'shared'
$propertiesDestination = Join-Path $androidRoot 'unity-export.properties'
$resolvedAndroidRoot = (Resolve-Path -LiteralPath $androidRoot).Path

foreach ($generatedDestination in @($destination, $sharedDestination, $propertiesDestination)) {
    if (Test-Path -LiteralPath $generatedDestination) {
        $resolvedDestination = (Resolve-Path -LiteralPath $generatedDestination).Path
        if (-not $resolvedDestination.StartsWith($resolvedAndroidRoot, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to replace generated Unity files outside Flutter Android: $resolvedDestination"
        }
        Remove-Item -LiteralPath $resolvedDestination -Recurse -Force
    }
}

Copy-Item -LiteralPath $source -Destination $destination -Recurse
Copy-Item -LiteralPath $sharedSource -Destination $sharedDestination -Recurse
Copy-Item -LiteralPath $propertiesSource -Destination $propertiesDestination
Write-Output "Unity Library synced to $destination"
Write-Output "Unity shared Gradle scripts synced to $sharedDestination"
Write-Output "Unity export properties synced to $propertiesDestination"
