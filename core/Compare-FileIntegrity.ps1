param (
    [Parameter(Mandatory=$true)]
    [string]$SourcePath,

    [Parameter(Mandatory=$true)]
    [string]$BaselinePath
)

function Write-SentinelLog {
    param([string]$Message, [string]$Color = "White")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$Timestamp] $Message" -ForegroundColor $Color
}

try {
    if (-not (Test-Path $BaselinePath)) { throw "Baseline-fil ble ikke funnet på $BaselinePath" }
    if (-not (Test-Path $SourcePath)) { throw "Kildestien $SourcePath ble ikke funnet." }

    Write-SentinelLog "Laster inn baseline fra: $BaselinePath"
    $Baseline = Get-Content $BaselinePath | ConvertFrom-Json
    
    # Konverter baseline til et hashtable for raskere oppslag
    $BaselineLookup = @{}
    foreach ($Item in $Baseline) {
        $BaselineLookup[$Item.RelativePath] = $Item
    }

    Write-SentinelLog "Skanner nåværende tilstand for: $SourcePath"
    $CurrentFiles = Get-ChildItem -Path $SourcePath -File -Recurse
    $CurrentPaths = @()

    $Findings = @{
        Modified = @()
        Added    = @()
        Deleted  = @()
    }

    foreach ($File in $CurrentFiles) {
        $RelativePath = $File.FullName.Replace($SourcePath, "")
        $CurrentPaths += $RelativePath
        
        $CurrentHash = (Get-FileHash -Path $File.FullName -Algorithm SHA256).Hash

        if ($BaselineLookup.ContainsKey($RelativePath)) {
            # Sjekk om filen er endret
            if ($CurrentHash -ne $BaselineLookup[$RelativePath].SHA256) {
                $Findings.Modified += $RelativePath
                Write-SentinelLog "ADVARSEL: Fil endret: $RelativePath" -Color Yellow
            }
        }
        else {
            # Ny fil oppdaget
            $Findings.Added += $RelativePath
            Write-SentinelLog "VARSEL: Ny fil oppdaget: $RelativePath" -Color Cyan
        }
    }

    # Sjekk for slettede filer
    foreach ($Path in $BaselineLookup.Keys) {
        if ($Path -notin $CurrentPaths) {
            $Findings.Deleted += $Path
            Write-SentinelLog "KRITISK: Fil slettet: $Path" -Color Red
        }
    }

    # Oppsummering
    Write-SentinelLog "--- Skanning fullført ---" -Color Green
    Write-SentinelLog "Endret: $($Findings.Modified.Count)"
    Write-SentinelLog "Nye:    $($Findings.Added.Count)"
    Write-SentinelLog "Slettet: $($Findings.Deleted.Count)"

}
catch {
    Write-SentinelLog "FEIL: $($_.Exception.Message)" -Color Red
}