# Invoke-RebootAudit

## Purpose

I wrote this script to quickly assess a few logs and conditions to determine the responsible party and cause of a reboot. The script checks Windows eventlog as well as CCM logs.

## Usage

.EXAMPLE
    Invoke-RebootAudit -ComputerName WIN10ETL

.EXAMPLE
    Invoke-RebootAudit -ComputerName WIN10ETL -Start "03/21/2018" -End "03/22/2018"

## Need more?

Get-Help Invoke-RebootAudit.ps1