[CmdletBinding()]
param([switch]$CheckOnly,[switch]$Diagnose)
$ErrorActionPreference='Stop'

function Read-LauncherSettings([string]$Directory) {
    $path=Join-Path $Directory 'launcher.local.json'
    $settings=[pscustomobject]@{proxyPort=7890;executablePath=''}
    if(Test-Path -LiteralPath $path){
        $inputSettings=Get-Content -LiteralPath $path -Raw|ConvertFrom-Json
        foreach($property in $inputSettings.PSObject.Properties){
            if($property.Name -notin @('proxyPort','executablePath')){throw 'Unknown configuration field.'}
            $settings.($property.Name)=$property.Value
        }
    }
    if($settings.proxyPort -isnot [int] -and $settings.proxyPort -isnot [long]){throw 'proxyPort must be an integer.'}
    if($settings.proxyPort -lt 1 -or $settings.proxyPort -gt 65535){throw 'proxyPort must be between 1 and 65535.'}
    if($settings.executablePath -isnot [string]){throw 'executablePath must be a string.'}
    return $settings
}

function Find-Antigravity([string]$ExplicitPath) {
    if($ExplicitPath){
        if(-not [IO.Path]::IsPathRooted($ExplicitPath) -or [IO.Path]::GetFileName($ExplicitPath) -ine 'Antigravity.exe'){throw 'Use an absolute path to Antigravity.exe.'}
        if(-not(Test-Path -LiteralPath $ExplicitPath -PathType Leaf)){throw 'Configured executable not found.'}
        return (Get-Item -LiteralPath $ExplicitPath).FullName
    }
    $candidates=@((Join-Path $env:LOCALAPPDATA 'Programs\antigravity\Antigravity.exe'),(Join-Path $env:ProgramFiles 'Antigravity\Antigravity.exe'))
    if(${env:ProgramFiles(x86)}){$candidates+=Join-Path ${env:ProgramFiles(x86)} 'Antigravity\Antigravity.exe'}
    foreach($candidate in $candidates){if(Test-Path -LiteralPath $candidate -PathType Leaf){return $candidate}}
    throw 'Antigravity not found. Set executablePath in launcher.local.json.'
}

function New-ProxyStartInfo([string]$Executable,[int]$Port) {
    if($Port -lt 1 -or $Port -gt 65535){throw 'Invalid proxy port.'}
    $proxy='http://127.0.0.1:'+ $Port
    $psi=[Diagnostics.ProcessStartInfo]::new()
    $psi.FileName=$Executable
    $psi.WorkingDirectory=Split-Path -Parent $Executable
    $psi.UseShellExecute=$false
    $psi.Arguments='--proxy-server='+$proxy
    foreach($key in @('HTTP_PROXY','HTTPS_PROXY','ALL_PROXY')){$psi.EnvironmentVariables[$key]=$proxy}
    $psi.EnvironmentVariables['NO_PROXY']='localhost,127.0.0.1,::1'
    return $psi
}

function Test-ProxyPort([int]$Port) {
    $client=[Net.Sockets.TcpClient]::new()
    try{
        $task=$client.ConnectAsync('127.0.0.1',$Port)
        if(-not $task.Wait(3000) -or -not $client.Connected){throw 'Proxy port not reachable.'}
    }finally{$client.Dispose()}
}

function Invoke-PublicDiagnostics([int]$Port) {
    $curl=(Get-Command curl.exe -ErrorAction Stop).Source
    foreach($url in @('https://www.googleapis.com/oauth2/v2/userinfo','https://daily-cloudcode-pa.googleapis.com/')){
        $result=& $curl -q --silent --noproxy localhost --proxy ('http://127.0.0.1:'+$Port) --connect-timeout 5 --max-time 15 --output NUL --write-out '%{http_code}' $url
        [pscustomobject]@{host=([uri]$url).Host;curlExit=$LASTEXITCODE;httpStatus=$result;authenticated=$false}
    }
}

function Invoke-Launcher {
    $settings=Read-LauncherSettings $PSScriptRoot
    $exe=Find-Antigravity $settings.executablePath
    $psi=New-ProxyStartInfo $exe $settings.proxyPort
    if($Diagnose){Test-ProxyPort $settings.proxyPort;Invoke-PublicDiagnostics $settings.proxyPort;return}
    if($CheckOnly){[pscustomobject]@{executable=$exe;proxyPort=$settings.proxyPort;arguments=$psi.Arguments;launchPerformed=$false;networkRequests=$false};return}
    if(@(Get-Process -Name Antigravity -ErrorAction SilentlyContinue).Count){throw 'Fully quit Antigravity (including its tray icon), then launch again. No tasks were stopped.'}
    Test-ProxyPort $settings.proxyPort
    $p=[Diagnostics.Process]::Start($psi)
    Write-Output ('Started with explicit HTTP proxy. PID: '+$p.Id)
    Write-Output 'Process start is not proof of successful login.'
}

if($MyInvocation.InvocationName -ne '.'){
    try{Invoke-Launcher}catch{Write-Error $_;exit 1}
}
