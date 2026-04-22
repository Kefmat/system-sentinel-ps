<#
.SYNOPSIS
    System Sentinel - Setup & Initialization
.DESCRIPTION
    Klargjør miljøet for System Sentinel. Oppretter nødvendige mapper,
    validerer konfigurasjon og genererer den første sikkerhets-baselinen.
#>

$ConfigPath = ".\Config\Settings.json"

function Write-SetupLog {
    param([string]$Message, [string]$Color = "White")
    Write-Host "[SETUP] $Message" -ForegroundColor $Color
}

Write-SetupLog "--- Starter initialisering av System Sentinel ---" "Cyan"

$Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object Security.Principal.WindowsPrincipal($Identity)
if (-not $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-SetupLog "FEIL: Installasjon krever Administrator-rettigheter." "Red"
    exit
}
if (-not (Test-Path $ConfigPath)) {
    Write-SetupLog "FEIL: Finner ikke $ConfigPath. Kontroller at du har klonet alle filer." "Red"
    exit
}
$Settings = (Get-Content $ConfigPath | ConvertFrom-Json).SystemSettings

Write-SetupLog "Oppretter mappestruktur..."
$Folders = @($Settings.Storage.LogFolder, $Settings.Storage.ReportFolder, $Settings.Storage.BaselineFolder)
foreach ($Folder in $Folders) {
    if (-not (Test-Path $Folder)) {
        New-Item -ItemType Directory -Path $Folder -Force | Out-Null
        Write-SetupLog "Opprettet mappe: $Folder" "Gray"
    }
}

Write-SetupLog "Genererer første sikkerhets-baseline (dette kan ta litt tid)..." "Yellow"

foreach ($Target in $Settings.ScanPaths) {
    if (Test-Path $Target.Path) {
        Write-SetupLog "Skanner: $($Target.Description)..."
        
        if (Test-Path .\Core\Compare-FileIntegrity.ps1) {
            .\Core\Compare-FileIntegrity.ps1 -SourcePath $Target.Path -BaselinePath (Join-Path $Settings.Storage.BaselineFolder "FileBaseline.json")
        }
        
        if (Test-Path .\Core\Watch-SecurityPermissions.ps1) {
            .\Core\Watch-SecurityPermissions.ps1 -SourcePath $Target.Path -BaselinePath (Join-Path $Settings.Storage.BaselineFolder "ACLBaseline.json")
        }
    }
}

Write-SetupLog "--- Initialisering fullført! ---" "Green"
Write-SetupLog "Du kan nå kjøre '.\Start-SentinelScan.ps1' for å overvåke systemet." "Cyan"