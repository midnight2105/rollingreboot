# -- Connect to vCenter --

Write-Host "Connecting to VI Server"
$global:DefaultVIServer

$newServer = "false"
if ($global:DefaultVIServer) {
    $viserver = $global:DefaultVIServer.Name
    Write-Host "$VIServer is connected." -ForegroundColor green -BackgroundColor blue
    $in = Read-Host "If you want to connect again/another vCenter? Yes[Y] or No[N](Default: N)"
	if($in -eq "Y"){
	$newServer = "true"
	}
	if ($newServer -eq "true") {
    Disconnect-VIServer -Server "$viserver" -Confirm:$False
	$VCServer = Read-Host "Enter the vCenter server name" 
	$viserver = Connect-VIServer $VCServer  
		if ($VIServer -eq ""){
		Write-Host
		Write-Host "Please input a valid credential"
		Write-Host
		exit
		}	
    }
}else{
	$VCServer = Read-Host "Enter the vCenter server name" 
	$VIServer = Connect-VIServer $VCServer  
	if ($VIServer -eq ""){
		Write-Host
		Write-Host "Please input a valid credential"
		Write-Host
		exit
	}
}

$vmcluster = Read-Host -Prompt 'Input Cluster Name for Rolling Reboot'

$VMHosts = Get-Cluster $vmcluster | Get-VMHost

foreach($VMhost in $VMhosts)   
{
    Write-Host REBOOTING $VMhost.Name
    Set-vmhost $VMhost -State Maintenance -Evacuate -VsanDataMigrationMode EnsureAccessibility

    Restart-VMHost $vmhost -Confirm:$false

    do {
        sleep 15
        $VMhostState = (Get-VMHost $VMhost).ConnectionState
    }
    while ($VMhostState -ne "NotResponding")
    Write-Host "$VMhost is Down"

    do {
        sleep 60
        $VMhostState = (Get-vmhost $vmhost).ConnectionState
        Write-Host "Waiting"
    }
    While ($VMhostState -ne "Maintenance")
    
    Write-host "Exit Maintenance mode"
    Set-VMHost $VMhost -State Connected
    Write-host "Reboot of $vmhost Complete"
}

Write-Host "Script Complete"
