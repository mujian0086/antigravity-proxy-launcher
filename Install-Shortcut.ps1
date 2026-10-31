[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
$script=Join-Path $PSScriptRoot 'Start-AntigravityProxy.ps1'
if(-not(Test-Path -LiteralPath $script)){throw 'Keep this script in the launcher folder.'}
$shell=New-Object -ComObject WScript.Shell
foreach($directory in @([Environment]::GetFolderPath('Desktop'),[Environment]::GetFolderPath('Programs'))){
    $path=Join-Path $directory 'Antigravity - HTTP Proxy.lnk'
    if(Test-Path -LiteralPath $path){Write-Warning ('Already exists; left unchanged: '+$path);continue}
    $shortcut=$shell.CreateShortcut($path)
    $shortcut.TargetPath=Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $shortcut.Arguments='-NoLogo -NoProfile -File "'+$script+'"'
    $shortcut.WorkingDirectory=$PSScriptRoot
    $shortcut.Description='Launch Antigravity through your local HTTP proxy'
    $shortcut.Save()
    $saved=$shell.CreateShortcut($path)
    if($saved.Arguments -ne $shortcut.Arguments){throw 'Shortcut verification failed.'}
    Write-Output ('Created: '+$path)
}
