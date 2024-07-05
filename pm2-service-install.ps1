
# check Administrator privileges
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin=$currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if($isAdmin -eq $true){
    Write-host "Script is running with Administrator privileges!"
}
else {
    Write-host "Script is not running with Administrator privileges,cannot be process."
    return
}

# Allow Execution of Foreign Scripts
Set-ExecutionPolicy Bypass -Scope Process -Force;

# Use TLS 1.2
[System.Net.ServicePointManager]::SecurityProtocol = 3072;

# refreshenv (an alias for Update-SessionEnvironment) is generally the right 
# command to use to update the current session with environment-variable changes
# after a choco install ... command.
# https://stackoverflow.com/questions/46758437/how-to-refresh-the-environment-of-a-powershell-session-after-a-chocolatey-instal
try
{
    Write-host "Downloading choco ..."
    Set-ExecutionPolicy Bypass -Scope Process -Force; 
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; 
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    $env:ChocolateyInstall = Convert-Path "$((Get-Command choco).Path)\..\.."   
    Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"  
    # Disable Chocolatey's Confirmation Prompt
    choco feature enable -n allowGlobalConfirmation  
} catch {
    Write-Host "download chocolatey failed,check you network pls."
    return
}

$nodeversion=$null
try { $nodeversion=node -v } catch {}
if($null -eq $nodeversion){
    # Write-host "Node.js must be installed. "
    Write-host "installing Node.js ..."
    choco install nodejs-lts
}
refreshenv

try { $nodeversion=node -v } catch {}
if($null -eq $nodeversion){
    Write-host "Node.js must be installed. "
    return
}
refreshenv


Set-Location -Path $PSScriptRoot
$winVersion = [System.Environment]::OSVersion.Version.Major
Write-host "Windws Version: $winVersion"

# install pm2
$pm2version=$null
$pm2Path="$env:ProgramData\pm2-etc"
try { $pm2version=pm2 -v } catch {}

if($null -eq $pm2version){
    Write-host "online install pm2 ..."

    if(-not (Test-Path $pm2Path) ){
        mkdir -Path "$pm2Path"
        # Grant Full Control permissions to the folder. 
        $newAcl = Get-Acl -Path "$pm2Path"
        $aclRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Users", "FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")
        $newAcl.AddAccessRule($aclRule)
        Set-Acl -Path "$pm2Path" -AclObject $newAcl        
    }
    Set-Location -Path $pm2Path
    
    Write-host "npm config get registry"
    & npm config get registry

    Write-host "npm install pm2"
    & npm install pm2
    refreshenv    

    $sysPath = [Environment]::GetEnvironmentVariable('Path','Machine')
    $newPath="$pm2Path\node_modules\.bin"
    if ($Paths -notcontains $newPath) {
        $sysPath += ";$newPath"
        [Environment]::SetEnvironmentVariable('Path', $sysPath, 'Machine')
    }
    refreshenv

    & pm2
    Copy-Item "$($HOME)\.pm2" -Destination "$pm2Path\.pm2" -Force
    [Environment]::SetEnvironmentVariable('PM2_HOME', "$pm2Path\.pm2", 'Machine')
    refreshenv

    if(-not (Test-Path "$pm2Path\npm") ){
        mkdir -Path "$pm2Path\npm"
        # todo auth
    }  
    if(-not (Test-Path "$pm2Path\npm-cache") ){
        mkdir -Path "$pm2Path\npm-cache"
        # todo auth
    }      
    refreshenv
    & npm config --global set prefix ("$pm2Path\npm" -replace '\\','/')
    & npm config --global set cache  ("$pm2Path\npm-cache" -replace '\\','/')

    Write-host "pm2 install @jessety/pm2-logrotate"
    & pm2 install @jessety/pm2-logrotate
}
else {
    Write-host "PM2 $pm2version is already installed. You must uninstall PM2 to proceed."
}

Set-Location -Path $PSScriptRoot

# create windows service
if(-not (Test-Path "$pm2Path\service") ){
    mkdir -Path "$pm2Path\service"
}

# pm2 service code
$serviceCode=@'
pm2 kill
pm2 resurrect
while ($true) {
    Start-Sleep -Seconds 60
    # do nothing
}
'@
Add-Content -Path "$pm2Path\service\pm2service.ps1" -Value $serviceCode


# download WinSW (Windows Service Wrapper)
Write-Host "downloading WinSW ..."
try
{
    Invoke-WebRequest "https://github.com/winsw/winsw/releases/download/v2.12.0/WinSW.NET4.exe" -OutFile "$pm2Path\service\pm2service.exe"
} catch {
    $StatusCode = $_.Exception.Response.StatusCode.value__
    Write-Host "download StatusCode code: $StatusCode"
}

if(-not(Test-Path "$pm2Path\service\pm2service.exe")){
    Write-Host "download failed,check you network pls."
    return
}


# config WinSW for PM2 (Windows Service Wrapper)
$serviceConfig=@"
<service>
    <id>PM2</id>
    <name>PM2</name>
    <description>PM2 Admin Service</description>
    <logmode>roll</logmode>
    <depend></depend>
    <executable>pwsh.exe</executable>
    <arguments>-File "%BASE%\pm2service.ps1"</arguments>
</service>
"@
Add-Content -Path "$pm2Path\service\pm2service.xml" -Value $serviceConfig

Set-Location "$pm2Path\service"
& ./pm2service.exe Install
& ./pm2service.exe Start

Set-Location -Path $PSScriptRoot

refreshenv
