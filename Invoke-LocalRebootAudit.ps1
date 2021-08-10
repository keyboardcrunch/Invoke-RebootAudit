<#
.SYNOPSIS
Quickly audit EventLogs for reboot or login events.

.DESCRIPTION
Quickly audit EventLogs for reboot or login events.

.PARAMETER FolderPath
Folder with evtx files.

.PARAMETER LogTail
Optional. Number of lines to display from end of .log files.
Does not apply to Eventlogs.

.EXAMPLE
Invoke-RebootAudit -FolderPath "C:\Windows\Temp\EventlogDump\"

.NOTES
        File Name: Invoke-LocalRebootAudit.ps1
        Author: keyboardcrunch
        Date Created: 10/08/21

#>

param (
    [string]$FolderPath,
    [string]$LogTail
)

$Banner = "
 _____             _           _____     _           _   _____       _ _ _   
|     |___ _ _ ___| |_ ___ ___| __  |___| |_ ___ ___| |_|  _  |_ _ _| |_| |_ 
|-   -|   | | | . | '_| -_|___|    -| -_| . | . | . |  _|     | | | . | |  _|
|_____|_|_|\_/|___|_,_|___|   |__|__|___|___|___|___|_| |__|__|___|___|_|_|  
                                                                             
"

#Clear-Host
Write-Host $Banner -ForegroundColor Cyan

If (Test-Path $FolderPath) {
    $SystemLog = Join-Path $FolderPath -ChildPath "system.evtx"
    $SecurityLog = Join-Path $FolderPath -ChildPath "security.evtx"
} Else {
    Write-Host "Folder path does not exist or not specified!" -ForegroundColor Red
    Exit
}


If (-Not($LogTail)) {
    $LogTail = 20  
}

Write-Host "============================ Reboot Events ============================" -ForegroundColor Yellow
Try {
    $EVReboot = Get-WinEvent -FilterHashtable @{Path="$SystemLog";ID='6008','1074'} -MaxEvents $LogTail
    If ($EVReboot) {
        $EVReboot | Format-Table TimeCreated, Id, Message -AutoSize
    } Else {
        Write-Host "None" -ForegroundColor White
    }
} Catch {
    Write-Host "Skipped System Eventlog reboot query due to errors." -ForegroundColor Red
}

Write-Host "`n============================ Login  Events ============================" -ForegroundColor Yellow
Try {
    $EVLogin = Get-WinEvent -FilterHashtable @{Path="$SecurityLog";ID='4624','4634','4647'} -MaxEvents $LogTail
    If ($EVLogin) {
        $EVLogin | Format-Table TimeCreated, Id, Message -AutoSize
    } Else {
        Write-Host "None" -ForegroundColor White
    }
} Catch {
    Write-Host "Skipped System Eventlog reboot query due to errors." -ForegroundColor Red
}

Write-Host "`n`n` "
