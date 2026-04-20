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

# Oppretter objekter for å samle funn
$AuditResults = [PSCustomObject]@{
    ChecksRun  = 0
    IssueCount = 0
    Findings   = @()
}

Write-Host "--- $($Settings.ProjectName) Framework: Oppstarter full skanning ---" -ForegroundColor Cyan

# Kjør skanninger basert på konfigurasjon
foreach ($Target in $Settings.ScanPaths) {
    Write-Host "`nArbeider med: $($Target.Description) [$($Target.Path)]" -ForegroundColor White
    
    $BaselineFile = Join-Path $Settings.Storage.BaselineFolder "FileBaseline.json"
    $ACLBaseline  = Join-Path $Settings.Storage.BaselineFolder "ACLBaseline.json"

    # Kjører Filintegritetssjekk
    if (Test-Path .\Core\Compare-FileIntegrity.ps1) {
        Write-Host "[1/2] Starter filskanning..." -ForegroundColor White
        # For enkelhet i denne versjonen simulerer vi innsamlingen av objekter:
        .\Core\Compare-FileIntegrity.ps1 -SourcePath $Target.Path -BaselinePath $BaselineFile
        $AuditResults.ChecksRun++
    }

    # Kjør Rettighetssjekk
    if (Test-Path .\Core\Watch-SecurityPermissions.ps1) {
        Write-Host "[2/2] Analyserer NTFS-rettigheter..." -ForegroundColor White
        .\Core\Watch-SecurityPermissions.ps1 -SourcePath $Target.Path -BaselinePath $ACLBaseline
        $AuditResults.ChecksRun++
    }
}

# Generer Rapport
# For at rapporten skal bli fyldig, må vi sende faktiske funn inn i $AuditResults.Findings.
# Dette kan vi utvide etter hvert som vi finjusterer integrasjonen mellom modulene.
Write-Host "`nKlargjør sluttrapport..." -ForegroundColor Yellow

if ($Settings.Reporting.GenerateHtml) {
    $ReportFile = Join-Path $Settings.Storage.ReportFolder "Sentinel_Full_Audit.html"
    .\Modules\New-SentinelReport.ps1 -ReportData $AuditResults -OutputPath $ReportFile
    
    if ($Settings.Reporting.AutoOpenReport) {
        Invoke-Item $ReportFile
    }
}

Write-Host "--- Skanning fullført! Sjekk rapporten i $ReportFile ---" -ForegroundColor Green