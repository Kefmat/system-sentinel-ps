
param (
    [Parameter(Mandatory=$true)]
    [string]$SourcePath,

    [Parameter(Mandatory=$false)]
    [string]$ExportPath = ".\Baseline_Snapshot.json"
)

# Opprett logg-funksjon for Audit Trail
function Write-SentinelLog {
    param([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$Timestamp] $Message" -ForegroundColor Cyan
}

try {
    if (-not (Test-Path $SourcePath)) {
        throw "Kildestien $SourcePath ble ikke funnet."
    }

    Write-SentinelLog "Starter generering av baseline for: $SourcePath"

    # Hent alle filer rekursivt
    $Files = Get-ChildItem -Path $SourcePath -File -Recurse

    $FileInventory = @()

    foreach ($File in $Files) {
        Write-SentinelLog "Behandler: $($File.Name)"
        
        # Generer SHA256 hash for filen
        $FileHash = Get-FileHash -Path $File.FullName -Algorithm SHA256
        
        # Opprett et objekt for hver fil
        $FileInfo = [PSCustomObject]@{
            FileName     = $File.Name
            RelativePath = $File.FullName.Replace($SourcePath, "")
            SHA256       = $FileHash.Hash
            LastModified = $File.LastWriteTime
            Size         = $File.Length
        }
        $FileInventory += $FileInfo
    }

    # Eksporter til JSON
    $FileInventory | ConvertTo-Json | Out-File -FilePath $ExportPath
    Write-SentinelLog "Baseline lagret til: $ExportPath"
    Write-SentinelLog "Totalt antall filer registrert: $($FileInventory.Count)"

}
catch {
    Write-SentinelLog "FEIL: $($_.Exception.Message)"
}