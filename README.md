CloudStack-PowerShell-Reports
=============================

This is a fork of the CloudStack-PowerShell project which includes E-Mailing reports. This requires the machine running the script to have a SMTP listener on the local machine (or for you to hack the code to point to a different SMTP server)

A PowerShell Module for the Apache CloudStack / Citrix CloudPlatform API

This module provides Cmdlets for:
```	
	New-CloudStackReports
	Get-CloudStackReports
	Import-CloudstackReportsConfig
```	

To install the module correctly, run the following in PowerShell:
```
	$PSModulePath = $Env:PSModulePath -split ";" | Select -Index ([int][bool]$Global)
	mkdir $PSModulePath\CloudStackReportsClient
	Copy-Item .\*.psm1 $PSModulePath\CloudStackReportsClient\
```	

Once the module is installed, it can be loaded via ```Import-Module CloudStackReportsClient```

The .ps1 scripts shoud give you an idea of how to interact with the Module.

