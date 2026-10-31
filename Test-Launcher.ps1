$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Start-AntigravityProxy.ps1')
$before=[Environment]::GetEnvironmentVariable('HTTPS_PROXY','Process')
$psi=New-ProxyStartInfo 'C:\Example App\Antigravity.exe' 12345
if($psi.UseShellExecute -or $psi.Arguments -ne '--proxy-server=http://127.0.0.1:12345'){throw 'Incorrect launch configuration.'}
foreach($key in @('HTTP_PROXY','HTTPS_PROXY','ALL_PROXY')){if($psi.EnvironmentVariables[$key] -ne 'http://127.0.0.1:12345'){throw 'Child environment missing proxy.'}}
if($psi.EnvironmentVariables['NO_PROXY'] -ne 'localhost,127.0.0.1,::1'){throw 'Loopback bypass missing.'}
if([Environment]::GetEnvironmentVariable('HTTPS_PROXY','Process') -ne $before){throw 'Parent environment changed.'}
$dir=Join-Path ([IO.Path]::GetTempPath()) ('antigravity-launcher-test-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $dir|Out-Null
$file=Join-Path $dir 'launcher.local.json'
try{
    if((Read-LauncherSettings $dir).proxyPort -ne 7890){throw 'Default configuration failed.'}
    foreach($bad in @('{"proxyPort":0}','{"proxyPort":65536}','{"proxyPort":"7890 & whoami"}','{"unknown":true}')){
        [IO.File]::WriteAllText($file,$bad)
        $rejected=$false
        try{Read-LauncherSettings $dir|Out-Null}catch{$rejected=$true}
        if(-not $rejected){throw 'Invalid configuration was accepted.'}
    }
    [IO.File]::WriteAllText($file,'{"proxyPort":12345,"executablePath":""}')
    if((Read-LauncherSettings $dir).proxyPort -ne 12345){throw 'Custom port failed.'}
    # Spawn only PowerShell as a test child, never Antigravity or a network client.
    $psi.FileName=Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $psi.WorkingDirectory=$dir
    $psi.Arguments='-NoProfile -NonInteractive -Command "if ($env:HTTPS_PROXY -ne ''http://127.0.0.1:12345'') { exit 9 }"'
    $psi.CreateNoWindow=$true
    $child=[Diagnostics.Process]::Start($psi)
    if(-not $child.WaitForExit(10000)){$child.Kill();throw 'Test child timed out.'}
    if($child.ExitCode -ne 0){throw 'Child did not inherit proxy environment.'}
    Write-Output 'PASS: configuration validation, process-local settings, child inheritance, loopback bypass. No app login tested.'
}finally{
    if(Test-Path -LiteralPath $file){Remove-Item -LiteralPath $file}
    Remove-Item -LiteralPath $dir
}
