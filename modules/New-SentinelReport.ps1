<#
.SYNOPSIS
    System Sentinel - HTML Report Generator
.DESCRIPTION
    Genererer en profesjonell HTML-rapport med interaktivt dashboard (Chart.js)
    basert på funn fra integritetskontroller.
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

    # Definer statusklasse for fargekoding
    $StatusClass = "status-ok"
    if ($Data.IssueCount -gt 0) {
        $StatusClass = "status-critical"
    }

    # Beregn suksess-rate for diagrammet
    $OkCount = $Data.ChecksRun - $Data.IssueCount
    if ($OkCount -lt 0) { $OkCount = 0 }

    $HTML = @"
<!DOCTYPE html>
<html lang="no">
<head>
    <meta charset="UTF-8">
    <title>System Sentinel Dashboard</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
    $CssContent
    </style>
</head>
<body>
    <div class="container">
        <h1>System Sentinel Audit Report</h1>
        <p><strong>Generert:</strong> $Timestamp</p>

        <div class="dashboard-grid" style="display: flex; justify-content: space-around; align-items: center; flex-wrap: wrap; margin-bottom: 30px;">
            <div class="summary-box" style="flex: 1; min-width: 250px;">
                <div class="stat status-ok">Sjekker utført: $($Data.ChecksRun)</div>
                <div class="stat $StatusClass">Avvik funnet: $($Data.IssueCount)</div>
            </div>
            
            <div class="chart-container" style="width: 250px; height: 250px;">
                <canvas id="statusChart"></canvas>
            </div>
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

    if ($Data.Findings.Count -eq 0) {
        $HTML += "<tr><td colspan='3' style='text-align:center;'>Ingen avvik funnet under denne skanningen.</td></tr>"
    } else {
        foreach ($Finding in $Data.Findings) {
            $HTML += "<tr><td>$($Finding.Type)</td><td>$($Finding.Object)</td><td>$($Finding.Status)</td></tr>"
        }
    }

    $HTML += @"
            </tbody>
        </table>

        <script>
            const ctx = document.getElementById('statusChart').getContext('2d');
            new Chart(ctx, {
                type: 'doughnut',
                data: {
                    labels: ['OK', 'Avvik'],
                    datasets: [{
                        data: [$OkCount, $($Data.IssueCount)],
                        backgroundColor: ['#27ae60', '#e74c3c'],
                        borderWidth: 2,
                        hoverOffset: 4
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { position: 'bottom' }
                    }
                }
            });
        </script>

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

Write-Host "[Audit] Visuell rapport er generert: $OutputPath" -ForegroundColor Green