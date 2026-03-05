[Console]::OutputEncoding = [System.text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "AVOS: Startup Sentinel - v1.5"

#in .exe file there was an autoupdate system

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
    foreach ($action in $task.Actions) {
        $rawPath = "$($action.Execute) $($action.Arguments)".Trim()
        if ([string]::IsNullOrWhiteSpace($rawPath)) { continue }

        $cleanPath = $rawPath.Replace('"', '').Trim()

        if ($cleanPath -match 'Appdata|Temp' -and $cleanPath -notmatch 'OneDrive|Discord|Steam|Zoom|Spotify|Teams|Windows\\System32|Windows') {
            $found = $true
            Write-Host "`n[!] SUSPICIOUS FILE!" -ForegroundColor Red
            Write-Host "Task: $($task.TaskName)" -ForegroundColor Yellow
            Write-Host "Full path: $cleanPath" -ForegroundColor White

            $choice = Read-Host "Delete this task & file? (y/n)"
            if ($choice -eq 'y') {
                Unregister-ScheduledTask -TaskName $task.TaskName -Confirm:$false
                
                $filePath = $cleanPath.Split(' ')[0]
                if (Test-Path $filePath) { 
                    Remove-Item $filePath -Force 
                    Write-Host "Deleted!" -ForegroundColor Cyan
                }
            }
            Write-Host "---------------------------"
        }
    }
}

 if (-not $found) {Write-Host "No threats found."-ForegroundColor Green}
 Write-Host "Scan complete"
 pause
 exit