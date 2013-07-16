<#
.SYNOPSIS
   A CloudStack/CloudPlatform Volume Snapshot History Manager.
.DESCRIPTION
   A feature-rich Apache CloudStack/Citrix CloudPlatform API client for issuing commands to the Cloud Management system.
.PARAMETER volume
   The volume parameter is MANDATORY and specifies which volume you are wanting to manage the snapshots of.
.PARAMETER days
   The number of days prior to today that you want to keep snapshots for.
.EXAMPLE
   CloudStackSnapshotHistoryManager.ps1 -volume da0018ed-ce52-4d37-a5fb-6f121eb503c3 -days 7
#>
# Writen by Jeff Moody (fifthecho@gmail.com)
#
# 2013/5/15  v1.0 created
# 2013/5/17  v2.0 created to work with CloudStackClient module v 2.0.


Param(
	[Parameter(Mandatory=$true)]
	[String]
    $volume
,
    [Parameter(Mandatory=$true)]
    [Int]
    $days
)

Import-Module CloudStackReportsClient
$parameters = Import-CloudstackReportsConfig
$EMails = $parameters[3]
$mailbody = ""
$hostname = $env:COMPUTERNAME

if ($parameters -ne 1) {
	$cloud = New-CloudStackReports -apiEndpoint $parameters[0] -apiPublicKey $parameters[1] -apiSecretKey $parameters[2]
	$job = Get-CloudStackReports -cloudStack $cloud -command listSnapshots -options volumeid=$volume

	if($snapshots = $job.listsnapshotsresponse.snapshot){
	    $days = 0 - $days

	    $purgeDate = [DateTime]::Today.AddDays($days).DayOfYear

	    foreach($snap in $snapshots){
	        Write-Debug $snap
	        if ([DateTime]::Parse($snap.created).DayOfYear -lt $purgeDate){
	            $snapDate = [DateTime]::Parse($snap.created).ToShortDateString()
	            $snapID = $snap.id
	            $mailbody += "Deleting Snapshot <i>$snapID</i> for volume <i>$volume</i> from $snapDate. <br />`n"
	            $deleteJob = Get-CloudStackReports -cloudStack $cloud -command deleteSnapshot -options id=$snapID
	            Write-Debug "Delete job: $deleteJob"
	            }
	    
	    }
        Write-Debug "Mail body: `n$mailbody"
    
        Send-MailMessage -From "cloud@$hostname" -To $EMails -Body $mailbody -Subject "CloudStack Snapshot History Manager Job for Volume $volume" -BodyAsHtml -SmtpServer localhost
    }
    else {
        $mailbody += "No snapshots to delete for volume $volume"
        Send-MailMessage -From "cloud@$hostname" -To $EMails -Body $mailbody -Subject "CloudStack Snapshot History Manager Job for Volume $volume" -BodyAsHtml -SmtpServer localhost
    }
}
else {
	Write-Error "Please configure the $env:userprofile\cloud-settings.txt file"
}	
