param (
    [Parameter(Mandatory=$true)]
    [string]$SourcePath,

    [Parameter(Mandatory=$false)]
    [string]$BaselinePath = ".\Config\ACL_Baseline.json"
)

function Write-SentinelLog {
    param([string]$Message, [string]$Color = "White")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$Timestamp] $Message" -ForegroundColor $Color
}

try {
    if (-not (Test-Path $SourcePath)) { throw "Kildestien $SourcePath ble ikke funnet." }

    Write-SentinelLog "Analyserer ACL for: $SourcePath"
    
    # Hent nåværende rettigheter
    $ACL = Get-Acl -Path $SourcePath
    $CurrentACL = $ACL.Access | Select-Object IdentityReference, FileSystemRights, AccessControlType, IsInherited

    # Hvis baseline ikke finnes, lag en ny
    if (-not (Test-Path $BaselinePath)) {
        Write-SentinelLog "Ingen eksisterende ACL-baseline funnet. Oppretter ny baseline..." -Color Cyan
        $CurrentACL | ConvertTo-Json | Out-File -FilePath $BaselinePath
        Write-SentinelLog "ACL-baseline lagret til: $BaselinePath"
        return
    }

    # Sammenlign med eksisterende baseline
    Write-SentinelLog "Sammenligner nåværende rettigheter med baseline..."
    $BaselineACL = Get-Content $BaselinePath | ConvertFrom-Json
    
    $Diff = Compare-Object -ReferenceObject $BaselineACL -DifferenceObject $CurrentACL -Property IdentityReference, FileSystemRights, AccessControlType

    if ($null -eq $Diff) {
        Write-SentinelLog "INGEN ENDRINGER: Rettighetene samsvarer med baseline." -Color Green
    }
    else {
        Write-SentinelLog "ADVARSEL: Endringer i rettigheter oppdaget!" -Color Red
        foreach ($Change in $Diff) {
            $Side = if ($Change.SideIndicator -eq "=>") { "Lagt til" } else { "Fjernet" }
            Write-SentinelLog "[$Side] Bruker/Gruppe: $($Change.IdentityReference) - Rettighet: $($Change.FileSystemRights)" -Color Yellow
        }
    }

}
catch {
    Write-SentinelLog "FEIL: $($_.Exception.Message)" -Color Red
}