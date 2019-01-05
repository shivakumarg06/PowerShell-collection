﻿# Invoke-UniFiCidrWorkaround

## SYNOPSIS
IPv4 CIDR Workaround for UBNT USG Firewall Rules

## SYNTAX

### Set 1
```
Invoke-UniFiCidrWorkaround [-CidrList] <PSObject> [<CommonParameters>]
```

## DESCRIPTION
IPv4 CIDR Workaround for UBNT USG Firewall Rules (Single IPv4 has to be without /32)

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
PS C:\\\>
```powershell
Invoke-UniFiCidrWorkaround -CidrList $value1
```

IPv4 CIDR Workaround for UBNT USG Firewall Rules

### -------------------------- EXAMPLE 2 --------------------------
PS C:\\\>
```powershell
$value1 | Invoke-UniFiCidrWorkaround
```

IPv4 CIDR Workaround for UBNT USG Firewall Rules via Pipeline

## PARAMETERS

### CidrList


```yaml
Type: PSObject
Parameter Sets: Set 1
Aliases: UniFiCidrList

Required: true
Position: 1
Default Value: 
Pipeline Input: True (ByPropertyName, ByValue)
```

### \<CommonParameters\>
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Management.Automation.PSObject


## OUTPUTS

### System.Management.Automation.PSObject


## NOTES

This is an internal helper function only

## RELATED LINKS

[Invoke-UniFiCidrWorkaroundV6]()


*Generated by: PowerShell HelpWriter 2019 v2.3.42*