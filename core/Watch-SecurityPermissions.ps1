param (
    [Parameter(Mandatory=$true)]
    [string]$SourcePath,

    [Parameter(Mandatory=$false)]
    [string]$BaselinePath = ".\Config\ACL_Baseline.json"
)

# Henter innstillinger for å sjekke om AutoRepair er på
$Settings = (Get-Content ".\Config\Settings.json" | ConvertFrom-Json).SystemSettings

function Write-SentinelLog {
    param([string]$Message, [string]$Color = "White")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$Timestamp] $Message" -ForegroundColor $Color
}

try {
    if (-not (Test-Path $SourcePath)) { throw "Kildestien $SourcePath ble ikke funnet." }

    Write-SentinelLog "Analyserer ACL for: $SourcePath"
    
    # Hent nåværende rettigheter som SDDL (for reparasjon) og objekt-liste (for sammenligning)
    $ACLObject = Get-Acl -Path $SourcePath
    $CurrentSDDL = $ACLObject.Sddl
    $CurrentAccessList = $ACLObject.Access | Select-Object IdentityReference, FileSystemRights, AccessControlType

    # Hvis baseline ikke finnes, lag en ny med SDDL-støtte
    if (-not (Test-Path $BaselinePath)) {
        Write-SentinelLog "Ingen eksisterende ACL-baseline funnet. Oppretter ny baseline..." -Color Cyan
        $BaselineData = [PSCustomObject]@{
            Path = $SourcePath
            Sddl = $CurrentSDDL
            Access = $CurrentAccessList
        }
        $BaselineData | ConvertTo-Json -Depth 4 | Out-File -FilePath $BaselinePath
        Write-SentinelLog "ACL-baseline lagret til: $BaselinePath"
        return
    }

    # Last inn baseline
    $BaselineData = Get-Content $BaselinePath | ConvertFrom-Json
    $Findings = @()

    # Sammenlign SDDL-strenger (raskeste måte å se om NOE er endret)
    if ($CurrentSDDL -ne $BaselineData.Sddl) {
        Write-SentinelLog "ADVARSEL: Endringer i rettigheter oppdaget!" -Color Red
        
        # Finn detaljene for rapporten
        $Diff = Compare-Object -ReferenceObject $BaselineData.Access -DifferenceObject $CurrentAccessList -Property IdentityReference, FileSystemRights, AccessControlType

        foreach ($Change in $Diff) {
            $Side = if ($Change.SideIndicator -eq "=>") { "Lagt til" } else { "Fjernet" }
            $StatusMsg = "[$Side] $($Change.IdentityReference): $($Change.FileSystemRights)"
            Write-SentinelLog $StatusMsg -Color Yellow
            
            $Findings += [PSCustomObject]@{
                Type   = "Sikkerhet"
                Object = $SourcePath
                Status = $StatusMsg
            }
        }

        # --- AUTO-REPAIR LOGIKK ---
        if ($Settings.AutoRepair -eq $true) {
            Write-SentinelLog "AutoRepair er aktiv. Tilbakestiller rettigheter til baseline..." -Color Blue
            try {
                $RestoredACL = New-Object Security.AccessControl.DirectorySecurity
                $RestoredACL.SetSecurityDescriptorSddlForm($BaselineData.Sddl)
                Set-Acl -Path $SourcePath -AclObject $RestoredACL -ErrorAction Stop
                
                Write-SentinelLog "SUKSESS: Rettighetene er gjenopprettet for $SourcePath" -Color Green
                foreach ($F in $Findings) { $F.Status += " (AUTOMATISK RETTET)" }
            }
            catch {
                Write-SentinelLog "FEIL: Kunne ikke utføre AutoRepair: $($_.Exception.Message)" -Color Red
            }
        }
    }
    else {
        Write-SentinelLog "INGEN ENDRINGER: Rettighetene samsvarer med baseline." -Color Green
    }

    # Returner funn til Master-skriptet
    return $Findings
}
catch {
    Write-SentinelLog "FEIL: $($_.Exception.Message)" -Color Red
}