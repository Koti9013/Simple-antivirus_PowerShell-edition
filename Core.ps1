[Console]::OutputEncoding = [System.text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "AVOS: Startup Sentinel - v1.5"

$CurrentProcess = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
$CurrentDir = Split-Path -Parent $CurrentProcess
$MyFileName = [System.IO.Path]::GetFileName($CurrentProcess)

$oldExePath = Join-Path $CurrentDir "$MyFileName.old"
if (Test-Path $oldExePath) { 
    Remove-Item $oldExePath -Force -ErrorAction SilentlyContinue 
}

$baseUrl = "https://raw.githubusercontent.com/Koti9013/AVOS_Startup-Sentinel/refs/heads/main/"
$filesToUpdate = @(
    "README.md",
    "AVOS_Startup-Sentinel.exe",
    "LICENSE",
    "Changelog.txt"
)

Write-Host "--- Simple Antivirus Launcher ---" -ForegroundColor Cyan
Write-Host "[*] Checking for updates..."

foreach ($fileName in $filesToUpdate) {
    $localPath = Join-Path $CurrentDir $fileName
    $tempPath  = "$localPath.tmp"
    $remoteUrl = $baseUrl + $fileName

    try {
        Invoke-WebRequest -Uri $remoteUrl -OutFile $tempPath -UseBasicParsing -ErrorAction Stop -TimeoutSec 10

        $localHash = "NONE"
        if (Test-Path $localPath) { $localHash = (Get-FileHash $localPath).Hash }
        
        $remoteHash = "ERROR"
        if (Test-Path $tempPath) { $remoteHash = (Get-FileHash $tempPath).Hash }

        if ($localHash -ne $remoteHash) {
            Write-Host "[!] Updating: $fileName" -ForegroundColor Yellow
            
            if ($localPath -eq $CurrentProcess) {
                Rename-Item -Path $localPath -NewName "$fileName.old" -Force
                Move-Item -Path $tempPath -Destination $localPath -Force
                Write-Host "[*] EXE updated! Restart the app to apply changes." -ForegroundColor Green
            } else {
                Move-Item -Path $tempPath -Destination $localPath -Force
            }
        } else {
            if (Test-Path $tempPath) { Remove-Item $tempPath -Force }
        }
    } catch {
        Write-Host "[X] Failed to check $fileName (Server unreachable or file missing)" -ForegroundColor Gray
        if (Test-Path $tempPath) { Remove-Item $tempPath -Force -ErrorAction SilentlyContinue }
    }
}


Write-Host "[✓] All files are up to date!" -ForegroundColor Green
Write-Host "---------------------------------"

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Asking for administrator rights..." -ForegroundColor Yellow
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}



Write-Host "==================================================="
Write-Host "             Scanning the system...                "
Write-Host "==================================================="

$tasks = Get-ScheduledTask | Where-Object { $_.State -ne 'Disabled' }
$found = $false


foreach ($task in $tasks) {
    $allActions = @()
    foreach ($act in $Actions) {
        if ($act.Execute) { $allActions += $act.Execute }
        if ($act.Arguments) { $allActions += $act.Arguments }
}
$actionString = $allActions -join  " "

if ($actionString -match 'Appdata|Temp' -and $actionString -notmatch 'OneDrive|Discord|Steam|Zoom') {
   $found = $true
   Write-Host "[!] INTRUDER FOUND!" -ForegroundColor Red
   Write-Host "Task: $($task.TaskName)" -ForegroundColor Yellow
   Write-Host "Path: $actionString" -ForegroundColor White


   $choice = Read-Host "Disable this task? (y/n)"
   if ($choice -eq 'y') {
       Disable-ScheduledTask -TaskName $task.TaskName
       Write-Host "Succesfully disabled!" -ForegroundColor Cyan
   } else {
       Write-Host "Task remains enabled." -ForegroundColor Gray
   }
   Write-Host "---------------------------"
  }
 } 
 if (-not $found) {Write-Host "No threats found."-ForegroundColor Green}
 Write-Host "Scan complete"
 pause
 exit