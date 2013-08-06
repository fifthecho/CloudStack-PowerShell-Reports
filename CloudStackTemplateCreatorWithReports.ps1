<#
.SYNOPSIS
   A CloudStack/CloudPlatform Template Creation script.
.DESCRIPTION
   A feature-rich Apache CloudStack/Citrix CloudPlatform API client for issuing commands to the Cloud Management system.
.PARAMETER volume
   The volume parameter specifies which volume to create a template from.
.PARAMETER snapshot
   The snapshot parameter specifies which snapshot to create a template from.
.PARAMETER displaytext
   The volume parameter is MANDATORY and specifies which volume or snapshot to create a template from.
.PARAMETER name
   The volume parameter is MANDATORY and specifies which volume or snapshot to create a template from.
.PARAMETER ostypeid
   The volume parameter is MANDATORY and specifies which volume or snapshot to create a template from.   
.EXAMPLE
   CloudStackSnapshot.ps1 -volume da0018ed-ce52-4d37-a5fb-6f121eb503c3
#>
# Writen by Jeff Moody (fifthecho@gmail.com)
#
# 2013/8/6  v1.0 created


Param(
	[Parameter(Mandatory=$false)]
	[String]
    $volume
    ,
    [Parameter(Mandatory=$false)]
	[String]
    $snapshot
    ,
    [Parameter(Mandatory=$true)]
	[String]
    $name
    ,
    [Parameter(Mandatory=$true)]
	[String]
    $ostypeid
    ,
    [Parameter(Mandatory=$false)]
	[String]
    $displaytext
    ,
    [Parameter(Mandatory=$false)]
	[Bool]
    $passwordenabled
)

Import-Module CloudStackReportsClient
$parameters = Import-CloudstackReportsConfig
$EMails = $parameters[3]
$mailbody = ""
$hostname = $env:COMPUTERNAME
$displayname = ""
$optionsArray = @()
$continue = $false
$error = ""
$vstring = ""

if ($parameters -ne 1) {
	$cloud = New-CloudStackReports -apiEndpoint $parameters[0] -apiPublicKey $parameters[1] -apiSecretKey $parameters[2]
    $optionsArray += "ostypeid=$ostypeid"
    $optionsArray += "name=$name"
    if ($displaytext) {
	    $optionsArray += "displaytext=$displaytext"
    }
    else {
        $optionsArray += "displaytext=$name"
    }
    
    if ($passwordenabled) {
        $optionsArray += "passwordenabled=$passwordenabled"
    }

    if ($volume) {
        $optionsArray += "volumeid=$volume"
        $vstring = "volume <i>$volume</i>"
    }
    if ($snapshot) {
        $optionsArray += "snapshotid=$snapshot"
        $vstring = "snapshot <i>$snapshot</i> "
    }
    
    Write-Debug "Options: $optionsArray"
    
    if ($snapshot -or $volume){
        $continue = $true
    }
    else{
        $error = "Neither a snapshot ID or volume ID was specified. Job can not continue."
    }

    if ($continue -eq $true) {
	    $job = Get-CloudStackReports -cloudStack $cloud -command createTemplate -options $optionsArray
	    $jobid = $job.createtemplateresponse.jobid
        $date = Get-Date
        $startTime = $date.ToShortTimeString()
	    $mailbody += "Started template creation job <i>$jobid</i> at $startTime for $vstring<br />`n"
	    do {
	        $jobStatus = Get-CloudStackReports -cloudStack $cloud -command queryAsyncJobResult -options jobid=$jobid
	        Start-Sleep -Seconds 5
            Write-Host -NoNewline "."
	        }
	    while ($jobStatus.queryasyncjobresultresponse.jobstatus -eq 0)
        Write-Host " "   
	    $statusCode = $jobStatus.queryasyncjobresultresponse.jobresultcode
	    if ($statusCode -ne 0) {
	        $mailbody += "<h1>ERROR</h1> <h2>$jobStatus.queryasyncjobresultresponse.errortext</h2> <br />`n"
	    }
        $date = Get-Date
        $endTime = $date.ToShortTimeString()
        $mailbody += "Completed at $endTime"

        Write-Debug "Mail body: `n$mailbody"
    
        Send-MailMessage -From "cloud@$hostname" -To $EMails -Body $mailbody -Subject "CloudStack Templating Job" -BodyAsHtml -SmtpServer localhost
    }
    else {
        Write-Error "ERROR: $error"
    }
}
else {
	Write-Error "Please configure the $env:userprofile\cloud-settings.txt file"
}
