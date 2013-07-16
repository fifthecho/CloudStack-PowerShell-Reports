<#
.SYNOPSIS
   A CloudStack/CloudPlatform Virtual Machine Listing Scriptlet.
.DESCRIPTION
   List all virtual machines running within a CloudStack Cloud.
.PARAMETER zoneid
   The zone ID to list VMs from.
.EXAMPLE
   CloudStackListVirtualMachines.ps1 -zoneid e697daf1-a747-4152-a5ac-992bad096653
#>
# Writen by Jeff Moody (fifthecho@gmail.com)
#
# 2013/5/17  v1.0 created

Param(
	[String]
    $zoneid
)

Import-Module CloudStackReportsClient
$parameters = Import-CloudstackReportsConfig
$EMails = $parameters[3]
$mailbody = ""
$hostname = $env:COMPUTERNAME

if ($parameters -ne 1) {
	$cloud = New-CloudStackReports -apiEndpoint $parameters[0] -apiPublicKey $parameters[1] -apiSecretKey $parameters[2]
	if ($zoneid) {
		$job = Get-CloudStackReports -cloudStack $cloud -command listVirtualMachines -options zoneid=$zoneid
	}
	else {
		$job = Get-CloudStackReports -cloudStack $cloud -command listVirtualMachines 
	}
	$allVMs = $job.listvirtualmachinesresponse

	foreach ($VM in $allVMs.virtualmachine) {
        $VMID = $VM.id
        $VMNAME = $VM.name
        $VMDISPLAYNAME = $VM.displayname
        $VMZONENAME = $VM.zonename
        $VMTEMPLATE = $VM.templatedisplaytext
		$mailbody += "Virtual Machine $VMDISPLAYNAME (ID: $VMID) is running '$VMTEMPLATE' in $VMZONENAME<br />`n"
	}
    Write-Debug "Mail body: `n$mailbody"
    
    Send-MailMessage -From "cloud@$hostname" -To $EMails -Body $mailbody -Subject "CloudStack Instance List" -BodyAsHtml -SmtpServer localhost
}
else {
	Write-Error "Please configure the $env:userprofile\cloud-settings.txt file"
}
