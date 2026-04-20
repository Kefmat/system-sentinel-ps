<#
.SYNOPSIS
    System Sentinel - HTML Report Generator
.DESCRIPTION
    Genererer en profesjonell HTML-rapport basert på funn fra integritetskontroller.
    Benytter ekstern CSS for styling.
#>

param (
    [Parameter(Mandatory=$true)]
    [PSCustomObject]$ReportData,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\Reports\System_Sentinel_Report.html"
)

function Get-SentinelReportHTML {
    param($Data)
    
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Hent CSS fra Config-mappen
    $CssPath = ".\Config\ReportTemplate.css"
    $CssContent = ""
    if (Test-Path $CssPath) {
        $CssContent = Get-Content $CssPath -Raw
    } else {
        Write-Warning "CSS-mal ikke funnet på $CssPath. Bruker standard styling."
    }

    # Definer statusklasse for fargekoding (PS 5.1 kompatibel logikk)
    $StatusClass = "status-ok"
    if ($Data.IssueCount -gt 0) {
        $StatusClass = "status-critical"
    }

    $HTML = @"
<!DOCTYPE html>
<html lang="no">
<head>
    <meta charset="UTF-8">
    <title>System Sentinel Rapport</title>
    <style>
    $CssContent
    </style>
</head>
<body>
    <div class="container">
        <h1>System Sentinel Audit Report</h1>
        <p><strong>Generert:</strong> $Timestamp</p>

        <div class="summary-box">
            <div class="stat status-ok">Sjekker utført: $($Data.ChecksRun)</div>
            <div class="stat $StatusClass">Avvik funnet: $($Data.IssueCount)</div>
        </div>

        <h2>Detaljerte funn</h2>
        <table>
            <thead>
                <tr>
                    <th>Type</th>
                    <th>Objekt</th>
                    <th>Status / Endring</th>
                </tr>
            </thead>
            <tbody>
"@

    foreach ($Finding in $Data.Findings) {
        $HTML += "<tr><td>$($Finding.Type)</td><td>$($Finding.Object)</td><td>$($Finding.Status)</td></tr>"
    }

    $HTML += @"
            </tbody>
        </table>
        <div class="footer">
            System Sentinel Framework - Automatisert Sikkerhetskontroll og Systemovervåking
        </div>
    </div>
</body>
</html>
"@
    return $HTML
}

# Opprett mappen hvis den ikke finnes
$ReportDir = Split-Path $OutputPath
if (-not (Test-Path $ReportDir)) { 
    New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null
}

$FullHTML = Get-SentinelReportHTML -Data $ReportData
$FullHTML | Out-File -FilePath $OutputPath -Encoding utf8

Write-Host "[Audit] Rapport er generert og lagret: $OutputPath" -ForegroundColor Green