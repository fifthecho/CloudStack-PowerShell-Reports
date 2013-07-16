<#
.SYNOPSIS
   A CloudStack/CloudPlatform Volume Snapshot History Listing.
.DESCRIPTION
   Snapshot Counter will iterate through each volume and display a count of the number of snapshots per-volume.
.EXAMPLE
   CloudStackSnapshotCounter.ps1
#>
# Writen by Jeff Moody (fifthecho@gmail.com)
#
# 2013/7/12  v1.0 created


Import-Module CloudStackReportsClient
$parameters = Import-CloudstackReportsConfig
$EMails = $parameters[3]
$mailbody = ""
$hostname = $env:COMPUTERNAME

if ($parameters -ne 1) {
	$cloud = New-CloudStackReports -apiEndpoint $parameters[0] -apiPublicKey $parameters[1] -apiSecretKey $parameters[2]
    $volumeListJob = Get-CloudStackReports -cloudStack $cloud -command listVolumes -options type=ROOT
    $volumes = $volumeListJob.listvolumesresponse.volume 
    foreach($v in $volumes){
        $volumeID = $v.id
        $volumeName = $v.name
        $snapshotListJob = Get-CloudStackReports -cloudStack $cloud -command listSnapshots -options volumeid=$volumeID
        $snaps = $snapshotListJob.listsnapshotresponse
        $count = 0
        if ($snapshotListJob.listsnapshotsresponse.count){
            $count = $snapshotListJob.listsnapshotsresponse.count
        }
        $mailbody += "ROOT Volume $volumeName has $count snapshots<br />`n"
    }
    $mailbody +="<br />`n<br />"
    $volumeListJob = Get-CloudStackReports -cloudStack $cloud -command listVolumes -options type=DATADISK
    $volumes = $volumeListJob.listvolumesresponse.volume 
    foreach($v in $volumes){
        $volumeID = $v.id
        $volumeName = $v.name
        $snapshotListJob = Get-CloudStackReports -cloudStack $cloud -command listSnapshots -options volumeid=$volumeID
        $snaps = $snapshotListJob.listsnapshotresponse
        $count = 0
        if ($snapshotListJob.listsnapshotsresponse.count){
            $count = $snapshotListJob.listsnapshotsresponse.count
        }
        $mailbody += "DATADISK Volume $volumeName has $count snapshots<br />`n"
    }
    Write-Debug "Mail body: `n$mailbody"
    
    Send-MailMessage -From "cloud@$hostname" -To $EMails -Body $mailbody -Subject "CloudStack Snapshot Count" -BodyAsHtml -SmtpServer localhost
}
else {
	Write-Error "Please configure the $env:userprofile\cloud-settings.txt file"
}	