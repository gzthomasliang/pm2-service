# win21012 update powershell 4 to 5
$PSVersionTable.PSVersion
[System.Environment]::OSVersion.Version.Major

$winVersionMajor = [System.Environment]::OSVersion.Version.Major
$winVersionMinor = [System.Environment]::OSVersion.Version.Minor
Write-host "Windws version: $winVersionMajor.$winVersionMinor"
if(($winVersionMajor -eq 6) -and ($winVersionMinor -ge 3)) {
    if(($PSVersionTable.PSVersion).Major -lt 5) {
        Write-Host "installing Powershell 5.1(Windows Management Framework 5.1) ..."
        Set-ExecutionPolicy Bypass -Scope Process -Force;
        [System.Net.ServicePointManager]::SecurityProtocol = 3072;
        $url='https://go.microsoft.com/fwlink/?linkid=839516'
        Invoke-WebRequest -URI $url -OutFile "$env:tmp\ps5.1.msu"
        & wusa.exe "$env:tmp\ps5.1.msu" /quiet /promptrestart
    }	
}
Write-host ""
