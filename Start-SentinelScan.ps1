<#
.SYNOPSIS
    System Sentinel - Master Control Script
.DESCRIPTION
    Hovedskriptet som koordinerer integritetskontroll, rettighetssjekk 
    og generering av sluttrapport.
#>

# Last inn konfigurasjon (Dette var tidligere hardkodede stier)
$ConfigPath = ".\Config\Settings.json"
if (-not (Test-Path $ConfigPath)) {
    Write-Error "Konfigurasjonsfil ikke funnet på $ConfigPath. Avbryter."
    exit
}

$Config = Get-Content $ConfigPath | ConvertFrom-Json
$Settings = $Config.SystemSettings
$LogFile = Join-Path $Settings.Storage.LogFolder "Sentinel_Execution.log"

# --- HJELPEFUNKSJONER ---

function Write-SentinelLog {
    param(
        [Parameter(Mandatory=$true)] [string]$Message,
        [Parameter(Mandatory=$false)] [string]$Level = "INFO"
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Level] $Message"
    
    $Color = switch ($Level) {
        "INFO" { "Cyan" }
        "WARN" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        Default { "White" }
    }

    Write-Host $LogEntry -ForegroundColor $Color
    $LogEntry | Out-File -FilePath $LogFile -Append -Encoding utf8
}

function Test-IsAdmin {
    $Identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $Principal = New-Object Security.Principal.WindowsPrincipal($Identity)
    return $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# --- MILJØSJEKK ---

if (-not (Test-IsAdmin)) {
    Write-Host "FEIL: Skriptet må kjøres som ADMINISTRATOR for å lese systemrettigheter." -ForegroundColor Red
    exit
}

# Sikre at mapper eksisterer
$Folders = @($Settings.Storage.LogFolder, $Settings.Storage.ReportFolder, $Settings.Storage.BaselineFolder)
foreach ($Folder in $Folders) {
    if (-not (Test-Path $Folder)) { New-Item -ItemType Directory -Path $Folder -Force | Out-Null }
}

# Oppretter objekter for å samle funn
$AuditResults = [PSCustomObject]@{
    ChecksRun  = 0
    IssueCount = 0
    Findings   = @()
}

Write-SentinelLog "--- $($Settings.ProjectName) Framework: Oppstarter full skanning ---"

# Kjør skanninger basert på konfigurasjon
foreach ($Target in $Settings.ScanPaths) {
    Write-SentinelLog "Arbeider med: $($Target.Description) [$($Target.Path)]"
    
    $BaselineFile = Join-Path $Settings.Storage.BaselineFolder "FileBaseline.json"
    $ACLBaseline  = Join-Path $Settings.Storage.BaselineFolder "ACLBaseline.json"

    # Kjører Filintegritetssjekk
    if (Test-Path .\Core\Compare-FileIntegrity.ps1) {
        Write-SentinelLog "[1/2] Starter filskanning..."
        # For enkelhet i denne versjonen simulerer vi innsamlingen av objekter:
        .\Core\Compare-FileIntegrity.ps1 -SourcePath $Target.Path -BaselinePath $BaselineFile
        $AuditResults.ChecksRun++
    }

    # Kjør Rettighetssjekk
    if (Test-Path .\Core\Watch-SecurityPermissions.ps1) {
        Write-SentinelLog "[2/2] Analyserer NTFS-rettigheter..."
        .\Core\Watch-SecurityPermissions.ps1 -SourcePath $Target.Path -BaselinePath $ACLBaseline
        $AuditResults.ChecksRun++
    }
}

# Generer Rapport
# For at rapporten skal bli fyldig, må vi sende faktiske funn inn i $AuditResults.Findings.
# Dette kan vi utvide etter hvert som vi finjusterer integrasjonen mellom modulene.
Write-SentinelLog "Klargjør sluttrapport..." -Level "WARN"

if ($Settings.Reporting.GenerateHtml) {
    $ReportFile = Join-Path $Settings.Storage.ReportFolder "Sentinel_Full_Audit.html"
    .\Modules\New-SentinelReport.ps1 -ReportData $AuditResults -OutputPath $ReportFile
    
    if ($Settings.Reporting.AutoOpenReport) {
        Invoke-Item $ReportFile
    }
}

Write-SentinelLog "--- Skanning fullført! Sjekk rapporten i $ReportFile ---" -Level "SUCCESS"