<#
.SYNOPSIS
   A CloudStack/CloudPlatform Volume Snapshot Agent.
.DESCRIPTION
   A feature-rich Apache CloudStack/Citrix CloudPlatform API client for issuing commands to the Cloud Management system.
.PARAMETER volume
   The volume parameter is MANDATORY and specifies which volume you are wanting to take a snapshot of.
.EXAMPLE
   CloudStackSnapshot.ps1 -volume da0018ed-ce52-4d37-a5fb-6f121eb503c3
#>
# Writen by Jeff Moody (fifthecho@gmail.com)
#
# 2011/9/16  v1.0 created
# 2013/5/13  v1.1 created to work with CloudPlatform 3.0.6 and migrated to entirely new codebase for maintainability and readability.
# 2013/5/17  v2.0 created to work with CloudStackClient 2.0 module.

Param(
	[Parameter(Mandatory=$true)]
	[String]
    $volume
)

Import-Module CloudStackReportsClient
$parameters = Import-CloudstackReportsConfig
$EMails = $parameters[3]
$mailbody = ""
$hostname = $env:COMPUTERNAME

if ($parameters -ne 1) {
	$cloud = New-CloudStackReports -apiEndpoint $parameters[0] -apiPublicKey $parameters[1] -apiSecretKey $parameters[2]
	$job = Get-CloudStackReports -cloudStack $cloud -command createSnapshot -options volumeid=$volume
	$jobid = $job.createsnapshotresponse.jobid
    $date = Get-Date
    $startTime = $date.ToShortTimeString()
	$mailbody += "Started snaphsot job <i>$jobid</i> at $startTime for volume <i>$volume</i> <br />`n"
	do {
	    $jobStatus = Get-CloudStackReports -cloudStack $cloud -command queryAsyncJobResult -options jobid=$jobid
	    Start-Sleep -Seconds 5
	    }
	while ($jobStatus.queryasyncjobresultresponse.jobstatus -eq 0)
	$statusCode = $jobStatus.queryasyncjobresultresponse.jobresultcode
	if ($statusCode -ne 0) {
	    $mailbody += "<h1>ERROR</h1> <h2>$jobStatus.queryasyncjobresultresponse.errortext</h2> <br />`n"
	}
    $date = Get-Date
    $endTime = $date.ToShortTimeString()
    $mailbody += "Completed at $endTime"

    Write-Debug "Mail body: `n$mailbody"
    
    Send-MailMessage -From "cloud@$hostname" -To $EMails -Body $mailbody -Subject "CloudStack Snapshot Job" -BodyAsHtml -SmtpServer localhost
}
else {
	Write-Error "Please configure the $env:userprofile\cloud-settings.txt file"
}
