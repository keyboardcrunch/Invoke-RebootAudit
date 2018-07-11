﻿<#
.SYNOPSIS
    Quickly audit CCM and EventLogs for reboot or login events.

.DESCRIPTION
    Quickly audit CCM and EventLogs for reboot or login events. 
    Only scans for reboot or login specific events, doesn't included kernel power events or patch install events.

.PARAMETER ComputerName
    The device to investigate.

.PARAMETER Start
    Optional. Start date for EventLogs. 
    If missing Start is last 24 hours.

.PARAMETER End
    Optional. End date for EventLogs. 
    If missing End is current date.

.PARAMETER LogTail
    Optional. Number of lines to display from end of .log files.
    Does not apply to Eventlogs.

.EXAMPLE
    Invoke-RebootAudit -ComputerName WIN10ETL

.EXAMPLE
    Invoke-RebootAudit -ComputerName WIN10ETL -Start "03/21/2018" -End "03/22/2018"

.NOTES
        File Name: Invoke-RebootAudit.ps1
        Author: keyboardcrunch
        Date Created: 28/02/18
        Updated: 20/03/18

#>

param (
    [string]$ComputerName,
    [string]$Start,
    [string]$End,
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


If (-Not($ComputerName)) {
    $ComputerName = $env:COMPUTERNAME
}

If (-not(Test-Connection -ComputerName $ComputerName -Count 3 -Quiet )) { 
    Write-Host "$ComputerName is offline or unreachable." -ForegroundColor Red
    Exit 1
}

If (-Not($Start)) {
    $Start = (Get-Date).AddHours(-24)   
}

If (-Not($End)) {
    $End = Get-Date   
}

If (-Not($LogTail)) {
    $LogTail = 10  
}

Write-Host "============================ Reboot Events ============================" -ForegroundColor Yellow
Try {
    $EVReboot = Get-EventLog -Log System -ComputerName $ComputerName -After $Start -Before $End | Where {$_.EventID -eq 6008 -or $_.EventID -eq 1074} | Format-Table TimeGenerated, EntryType, Message -AutoSize
    If ($EVReboot) {
        $EVReboot
    } Else {
        Write-Host "None" -ForegroundColor White
    }
} Catch {
    Write-Host "Skipped System Eventlog reboot query due to errors." -ForegroundColor Red
}

Write-Host "`n============================ Login  Events ============================" -ForegroundColor Yellow
Try {
    $EVLogin = Get-EventLog -Log Security -ComputerName $ComputerName -After $Start -Before $End | Where {$_.EventID -eq 4624 -or $_.EventID -eq 4634 -or $_.EventID -eq 4647} | Format-Table TimeGenerated, Message -AutoSize
    If ($EVLogin) {
        $EVLogin
    } Else {
        Write-Host "None" -ForegroundColor White
    }
} Catch {
    Write-Host "Skipped System Eventlog reboot query due to errors." -ForegroundColor Red
}

Write-Host "`n========================== CCM Login Events ===========================" -ForegroundColor Yellow
Try {
    $CCMLogin = Select-String -Path "\\$ComputerName\C$\Windows\CCM\Logs\execmgr.log" -Pattern 'The logged on user is' | Select-Object -Last $LogTail
    If ($CCMLogin) {
        $CCMLogin | Write-Host -ForegroundColor White
    } Else {
        Write-Host "None" -ForegroundColor White
    }
} Catch {
    Write-Host "Skipped CCM ExecMgr.log due to errors." -ForegroundColor Red
}

Write-Host "`n========================= CCM Reboot Events ===========================" -ForegroundColor Yellow
Try {
    $CCMReboot = Select-String -Path "\\$ComputerName\C$\Windows\CCM\Logs\RebootCoordinator.log" -Pattern 'Reboot initiated' | Select-Object -Last $LogTail
    If ($CCMReboot) {
        $CCMReboot | Write-Host -ForegroundColor White
    } Else {
        Write-Host "None" -ForegroundColor White
    }
} Catch {
    Write-Host "Skipped CCM RebootCoordinator.log due to errors." -ForegroundColor Red
}

Write-Host "`n========================= Registry Settings ===========================" -ForegroundColor Yellow
Try {
    If ($ComputerName -eq $env:COMPUTERNAME) {
        $DualScan = Get-ItemProperty hklm:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate -Name DisableDualScan
    } Else {
        $DualScan = Invoke-Command -ComputerName $ComputerName -ScriptBlock { $(Get-ItemProperty hklm:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate -Name DisableDualScan) }
    }
    
    If ($DualScan.DisableDualScan -eq 1) {
        Write-Host "DualScan = Disabled" -ForegroundColor Green
    } Else {
        Write-Host "DualScan = Enabled" -ForegroundColor Red
    }
} Catch {
    Write-Host "Failed to check registry key disabling Dual Scan." -ForegroundColor Red
}

Try {
    If ($ComputerName -eq $env:COMPUTERNAME) {
        $DualScan = Get-ItemProperty hklm:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU -Name UseWUServer
    } Else {
        $DualScan = Invoke-Command -ComputerName $ComputerName -ScriptBlock { $(Get-ItemProperty hklm:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU -Name UseWUServer) }
    }
    If ($DualScan.UseWUServer -eq 1) {
        Write-Host "SCCM patching = Enabled" -ForegroundColor Green
    } Else {
        Write-Host "SCCM patching = Disabled" -ForegroundColor Red
    }
} Catch {
    Write-Host "Failed to check registry key forcing SCCM patching." -ForegroundColor Red
}

Write-Host "`n`n` "