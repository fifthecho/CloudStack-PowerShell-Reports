<#
.SYNOPSIS
    A CloudStack/CloudPlatform Virtual Machine Desployment Scriptlet
.DESCRIPTION
    Use this script to deploy a virtual machine in a CloudStack Cloud.
.PARAMETER templateid
    The template ID for the VM.
.PARAMETER zoneid
    The zone for the VM
.PARAMETER serviceofferingid
    The Service offering ID for the VM
.PARAMETER securitygroupids
    The Security Group IDs for the VM
.PARAMETER networkids
    The Security Group IDs for the VM
#>
# Writen by Jeff Moody (fifthecho@gmail.com)
#
# 2013/7/19  v1.0 created

Param(
[Parameter(Mandatory=$true)]
  [String]
  $templateid
,
[Parameter(Mandatory=$true)]
  [String]
  $zoneid
,
[Parameter(Mandatory=$true)]
  [String]
  $serviceofferingid
,
[Parameter(Mandatory=$false)]
  [Array]
  $securitygroupids
,
[Parameter(Mandatory=$false)]
  [Array]
  $networkids
)

Import-Module CloudStackReportsClient
$parameters = Import-CloudstackReportsConfig
$EMails = $parameters[3]
$mailbody = ""
$hostname = $env:COMPUTERNAME

if ($parameters -ne 1) {
  $cloud = New-CloudStack -apiEndpoint $parameters[0] -apiPublicKey $parameters[1] -apiSecretKey $parameters[2]
  $date = Get-Date
  $startTime = $date.ToShortTimeString()
  if($securitygroupids) {
    $sids = $securitygroupids | Sort-Object
    $sids = $sids -join "%2c"
    $job = Get-CloudStack -cloudStack $cloud -command deployVirtualMachine -options serviceofferingid=$serviceofferingid,zoneid=$zoneid,securitygroupids=$sids,templateid=$templateid
  }
  elseif($networkids) {
    $nids = $networkids | Sort-Object
    $nids = $nids -join "%2c"
    $job = Get-CloudStack -cloudStack $cloud -command deployVirtualMachine -options serviceofferingid=$serviceofferingid,zoneid=$zoneid,networkids=$nids,templateid=$templateid
  }
  else {
    Write-Error "No network or security groups specified."
  }

  if($job){
    $jobid = $job.deployvirtualmachineresponse.jobid
    $mailbody += "Started VM Deployment job <i>$jobid</i> at $startTime for template <i>$templateid</i>.<br />`n"
    do {
      Write-Host -NoNewline "."
      $jobStatus = Get-CloudStack -cloudStack $cloud -command queryAsyncJobResult -options jobid=$jobid
      Start-Sleep -Seconds 2
    }
    Write-Host " "
    while ($jobStatus.queryasyncjobresultresponse.jobstatus -eq 0)
    $statusCode = $jobStatus.queryasyncjobresultresponse.jobresultcode
    if ($statusCode -ne 0) {
      Write-Error $jobStatus.queryasyncjobresultresponse.errortext
    }
    else {
      $vm = $jobStatus.queryasyncjobresultresponse.jobresult.virtualmachine
      $vmid = $vm.id
      $ip = $vm.nic.ipaddress
      $password = $vm.password
      
      $date = Get-Date
      $endTime = $date.ToShortTimeString()
      $mailbody += "`nCompleted at $endTime.<br /><br />"
      $mailbody += "`nVM $vmid deployed. VM IP Address is <b>$ip</b> and Administrator password is <i>$password</i> <br />"

      Write-Debug "Mail body: `n$mailbody"
    
      Send-MailMessage -From "cloud@$hostname" -To $EMails -Body $mailbody -Subject "CloudStack Snapshot Count" -BodyAsHtml -SmtpServer localhost
    }

  }
  
	
}
else {
	Write-Error "Please configure the $env:userprofile\cloud-settings.txt file"
}
# SIG # Begin signature block
# MIIRpQYJKoZIhvcNAQcCoIIRljCCEZICAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUkjyk8hf23NGLKsuG3FlHFy7B
# qqOggg3aMIIGcDCCBFigAwIBAgIBJDANBgkqhkiG9w0BAQUFADB9MQswCQYDVQQG
# EwJJTDEWMBQGA1UEChMNU3RhcnRDb20gTHRkLjErMCkGA1UECxMiU2VjdXJlIERp
# Z2l0YWwgQ2VydGlmaWNhdGUgU2lnbmluZzEpMCcGA1UEAxMgU3RhcnRDb20gQ2Vy
# dGlmaWNhdGlvbiBBdXRob3JpdHkwHhcNMDcxMDI0MjIwMTQ2WhcNMTcxMDI0MjIw
# MTQ2WjCBjDELMAkGA1UEBhMCSUwxFjAUBgNVBAoTDVN0YXJ0Q29tIEx0ZC4xKzAp
# BgNVBAsTIlNlY3VyZSBEaWdpdGFsIENlcnRpZmljYXRlIFNpZ25pbmcxODA2BgNV
# BAMTL1N0YXJ0Q29tIENsYXNzIDIgUHJpbWFyeSBJbnRlcm1lZGlhdGUgT2JqZWN0
# IENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAyiOLIjUemqAbPJ1J
# 0D8MlzgWKbr4fYlbRVjvhHDtfhFN6RQxq0PjTQxRgWzwFQNKJCdU5ftKoM5N4YSj
# Id6ZNavcSa6/McVnhDAQm+8H3HWoD030NVOxbjgD/Ih3HaV3/z9159nnvyxQEckR
# ZfpJB2Kfk6aHqW3JnSvRe+XVZSufDVCe/vtxGSEwKCaNrsLc9pboUoYIC3oyzWoU
# TZ65+c0H4paR8c8eK/mC914mBo6N0dQ512/bkSdaeY9YaQpGtW/h/W/FkbQRT3sC
# pttLVlIjnkuY4r9+zvqhToPjxcfDYEf+XD8VGkAqle8Aa8hQ+M1qGdQjAye8OzbV
# uUOw7wIDAQABo4IB6TCCAeUwDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMC
# AQYwHQYDVR0OBBYEFNBOD0CZbLhLGW87KLjg44gHNKq3MB8GA1UdIwQYMBaAFE4L
# 7xqkQFulF2mHMMo0aEPQQa7yMD0GCCsGAQUFBwEBBDEwLzAtBggrBgEFBQcwAoYh
# aHR0cDovL3d3dy5zdGFydHNzbC5jb20vc2ZzY2EuY3J0MFsGA1UdHwRUMFIwJ6Al
# oCOGIWh0dHA6Ly93d3cuc3RhcnRzc2wuY29tL3Nmc2NhLmNybDAnoCWgI4YhaHR0
# cDovL2NybC5zdGFydHNzbC5jb20vc2ZzY2EuY3JsMIGABgNVHSAEeTB3MHUGCysG
# AQQBgbU3AQIBMGYwLgYIKwYBBQUHAgEWImh0dHA6Ly93d3cuc3RhcnRzc2wuY29t
# L3BvbGljeS5wZGYwNAYIKwYBBQUHAgEWKGh0dHA6Ly93d3cuc3RhcnRzc2wuY29t
# L2ludGVybWVkaWF0ZS5wZGYwEQYJYIZIAYb4QgEBBAQDAgABMFAGCWCGSAGG+EIB
# DQRDFkFTdGFydENvbSBDbGFzcyAyIFByaW1hcnkgSW50ZXJtZWRpYXRlIE9iamVj
# dCBTaWduaW5nIENlcnRpZmljYXRlczANBgkqhkiG9w0BAQUFAAOCAgEAcnMLA3Va
# N4OIE9l4QT5OEtZy5PByBit3oHiqQpgVEQo7DHRsjXD5H/IyTivpMikaaeRxIv95
# baRd4hoUcMwDj4JIjC3WA9FoNFV31SMljEZa66G8RQECdMSSufgfDYu1XQ+cUKxh
# D3EtLGGcFGjjML7EQv2Iol741rEsycXwIXcryxeiMbU2TPi7X3elbwQMc4JFlJ4B
# y9FhBzuZB1DV2sN2irGVbC3G/1+S2doPDjL1CaElwRa/T0qkq2vvPxUgryAoCppU
# FKViw5yoGYC+z1GaesWWiP1eFKAL0wI7IgSvLzU3y1Vp7vsYaxOVBqZtebFTWRHt
# XjCsFrrQBngt0d33QbQRI5mwgzEp7XJ9xu5d6RVWM4TPRUsd+DDZpBHm9mszvi9g
# VFb2ZG7qRRXCSqys4+u/NLBPbXi/m/lU00cODQTlC/euwjk9HQtRrXQ/zqsBJS6U
# J+eLGw1qOfj+HVBl/ZQpfoLk7IoWlRQvRL1s7oirEaqPZUIWY/grXq9r6jDKAp3L
# ZdKQpPOnnogtqlU4f7/kLjEJhrrc98mrOWmVMK/BuFRAfQ5oDUMnVmCzAzLMjKfG
# cVW/iMew41yfhgKbwpfzm3LBr1Zv+pEBgcgW6onRLSAn3XHM0eNtz+AkxH6rRf6B
# 2mYhLEEGLapH8R1AMAo4BbVFOZR5kXcMCwowggdiMIIGSqADAgECAgIKdjANBgkq
# hkiG9w0BAQUFADCBjDELMAkGA1UEBhMCSUwxFjAUBgNVBAoTDVN0YXJ0Q29tIEx0
# ZC4xKzApBgNVBAsTIlNlY3VyZSBEaWdpdGFsIENlcnRpZmljYXRlIFNpZ25pbmcx
# ODA2BgNVBAMTL1N0YXJ0Q29tIENsYXNzIDIgUHJpbWFyeSBJbnRlcm1lZGlhdGUg
# T2JqZWN0IENBMB4XDTEzMDcxNzIyMzE1NloXDTE1MDcxODE2MDgzN1owgY4xGTAX
# BgNVBA0TEHE3cWM5c0FUQ3l5eXJyMzMxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpO
# ZXcgSmVyc2V5MRQwEgYDVQQHEwtKZXJzZXkgQ2l0eTEVMBMGA1UEAxMMUm9iZXJ0
# IE1vb2R5MSIwIAYJKoZIhvcNAQkBFhNmaWZ0aGVjaG9AZ21haWwuY29tMIICIjAN
# BgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAwVK+tPtCqiB8S9diZaP6N3PeSw8M
# LE+/xTVl3zo5XsUkou7EDsOO9GduH9wtKuDRwnhgbVKi9Rn+SS7WaYpIAel0UCye
# 3iIilkx02bWfjwi/MIdHKUjEJDHj/D3Js4tT2lz4pUO/YTM3e2mtjqAJ12f0wZnc
# Q0R65gHaPLsMMhj3mOZ7K9HHZAHvCKjrh5ZWDm6ma8zm+SMx8f22i/cxbIis5j7A
# 8EBu0AOvxiDCCj0ed7cF5N2aRpq9xFuqLXEGeGh0rCjt1CExKWXBdY8jXdg9YYWU
# Zo7kc/ZlekZVrSw3i1FG0rCDQKtACb8ZtEpf+qUZeNkIRbn1bZL1fWxWbZSu1j9S
# QVS2ppfUIZCiK8SE9RfKr0onUtTjSNG7QsPZbKFsbOU3zNFwpTsxiFRz+G9Lo3IK
# 01Cv2K2bBmaY0+uOGI8C00jd6dsSdctuEm1pdxVhhQTeoZlMVjTSP9AFeCWZmwh0
# to2DVLoZM5FwTRLmp3BR49URgHxbaOdZ7V0XQdAGzt2CT2ajAAO89lA0ThAU+eTt
# cSMVrCbnHN/92UgDD7ducn/VfoviKue3ni6zIF3a+V9EabhEVrpfgb9cksLSSPlI
# m16X/xkZS7aM0lM7pP+hJl7WbXhuQ8FZYP2O+ojYHluZxOFMOdFgktpbcJ5mZmsK
# YAsB9pZxbMaRjaECAwEAAaOCAsgwggLEMAkGA1UdEwQCMAAwDgYDVR0PAQH/BAQD
# AgeAMC4GA1UdJQEB/wQkMCIGCCsGAQUFBwMDBgorBgEEAYI3AgEVBgorBgEEAYI3
# CgMNMB0GA1UdDgQWBBTufJ1HUVFvYEYOZO4GqloTYH3huzAfBgNVHSMEGDAWgBTQ
# Tg9AmWy4SxlvOyi44OOIBzSqtzCCAUwGA1UdIASCAUMwggE/MIIBOwYLKwYBBAGB
# tTcBAgMwggEqMC4GCCsGAQUFBwIBFiJodHRwOi8vd3d3LnN0YXJ0c3NsLmNvbS9w
# b2xpY3kucGRmMIH3BggrBgEFBQcCAjCB6jAnFiBTdGFydENvbSBDZXJ0aWZpY2F0
# aW9uIEF1dGhvcml0eTADAgEBGoG+VGhpcyBjZXJ0aWZpY2F0ZSB3YXMgaXNzdWVk
# IGFjY29yZGluZyB0byB0aGUgQ2xhc3MgMiBWYWxpZGF0aW9uIHJlcXVpcmVtZW50
# cyBvZiB0aGUgU3RhcnRDb20gQ0EgcG9saWN5LCByZWxpYW5jZSBvbmx5IGZvciB0
# aGUgaW50ZW5kZWQgcHVycG9zZSBpbiBjb21wbGlhbmNlIG9mIHRoZSByZWx5aW5n
# IHBhcnR5IG9ibGlnYXRpb25zLjA2BgNVHR8ELzAtMCugKaAnhiVodHRwOi8vY3Js
# LnN0YXJ0c3NsLmNvbS9jcnRjMi1jcmwuY3JsMIGJBggrBgEFBQcBAQR9MHswNwYI
# KwYBBQUHMAGGK2h0dHA6Ly9vY3NwLnN0YXJ0c3NsLmNvbS9zdWIvY2xhc3MyL2Nv
# ZGUvY2EwQAYIKwYBBQUHMAKGNGh0dHA6Ly9haWEuc3RhcnRzc2wuY29tL2NlcnRz
# L3N1Yi5jbGFzczIuY29kZS5jYS5jcnQwIwYDVR0SBBwwGoYYaHR0cDovL3d3dy5z
# dGFydHNzbC5jb20vMA0GCSqGSIb3DQEBBQUAA4IBAQBlwx5+nm+gS06O8axJTEyU
# 6oeUrrB1RhN8YrJPnXDIM7GwP0B1YoxXYqQdU+k/PHpLxHKSs7wF3GxeOCsfhJfQ
# GzGqrsQ5AQz4WbHl9kdpJG5678aDv5yWyuJrhwMIQJQKxgGZRaM/I0rzeOSUAO6E
# ePjxQMhWDtaHay9ZwQ7T226bFhhZa4Tplyv4okT16QLfqWiXtNDQM9CHapKw8c6s
# IVrEkglhB2/A3JbNrStIeB4H002jSsW5uZqQlWE80oUl5ViaroCd5J+NeXLrta1y
# ZYel/EOVw7uObqw9Bvl1w05jRhEd3+ujmvOPBK/fKXUeWhI41xGbHueUdVjn9Iqq
# MYIDNTCCAzECAQEwgZMwgYwxCzAJBgNVBAYTAklMMRYwFAYDVQQKEw1TdGFydENv
# bSBMdGQuMSswKQYDVQQLEyJTZWN1cmUgRGlnaXRhbCBDZXJ0aWZpY2F0ZSBTaWdu
# aW5nMTgwNgYDVQQDEy9TdGFydENvbSBDbGFzcyAyIFByaW1hcnkgSW50ZXJtZWRp
# YXRlIE9iamVjdCBDQQICCnYwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwxCjAI
# oAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIB
# CzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFP1GYyh/sUQ8dS2Yutdh
# O11F3O3dMA0GCSqGSIb3DQEBAQUABIICAEwOmVHJ+Th6vCY0vuGNP5URGbSElXZB
# tmTo1Mzkqvw8YRnlBJ/YRZFMuZ0HPplT/RmSrMtJ7BUS02pZIWpyF1aIWoSzu+/S
# Z85mSf4AoQnefIlZxRvORyTKFw1Qxv5+en2oX2UVkyoEbrGZjzOAQ6X7WrgfM8c0
# pFv6ndBxP+Ys+nj3T48fhf2G0hi5GrhkFJtmp6ZRhPu7N7jy1Tc3WBUN/Z3NF1ct
# dSuo/JDkaENGMoWqYdkAt/z0A+Ktyguf0O9x5Zs7xNLC4Oy3tdxme332vJsAs8QJ
# 4RCvylD0JagR07cLNfhtIW+niK9UECN6DJ8T99s30PfKujwmE25iju7vTpTyPJX3
# AgtJWwXC7weQrURYJ0Lt9tMep6JUhEkOIrI23QeLGlCndGC807jLbDE0XY5DOMV9
# R4F9xNkHIaq0GeQMh8R7WDUpBnMvdYFkWWcDapKudyUYcyth9sFc426e8eL/gdp2
# d8wK+fXjZAGVNpq1OhhBbrcK8BD+nn3WiWa0Z9E+51oLTflyYhMe+0HVII10evyV
# sVb71sj5qQwyv8iwlahfz3/4ob6dGixeCfH1YuL1W5nzbcm7w8K+JCRxEWDyhEXQ
# 3B8/pqdnFhZq6DUmKrGDhC0o/Q2HODwhGJhsGjAPK/tN62gzKc/cxDnGCGJjtTff
# AWqSweMRk+fC
# SIG # End signature block
