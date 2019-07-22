workflow Install-VM
{
    # Parameters
    param(
        # Full path to base Vhd for VMs
        [Parameter(Mandatory=$true)]
        [String]$BaseVhdPath,

        # Prefix for VM names
        [String]$VMNamePrefix = "Demo",
        
        # Number of VMs to create
        [Int]$VMCount = 3,
        
        # Domain credential required to join the VMs to a domain
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.PSCredential] $domainCred,
	    
        # Local credential required to connect to VMs before being joined to domain
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.PSCredential] $localCred,

        # Credential to connect to mail server
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.PSCredential] $mailCred
    )
                    
    # Create VMs in parallel 
    foreach -parallel($i in 1..$VMCount)
    {
        # Create the VM name
        [string]$VMName = $VMNamePrefix+$i

        # Full path to the VHDs
        $BaseVhdFilePath = $BaseVhdPath+"\SvrCore"+$i+".vhd"

        # Full path to the VHDs
        $VhdFilePath = $BaseVhdPath+"\"+$VMName+".vhd"
        
        # Create differencing VHDs
        # NOTE: (Known bug) Ideally, following syntax should be:
        # $DiffVHD = New-VHD -ParentPath $BaseVhdFilePath -Path $VhdFilePath
        $DiffVHD = New-VHD -ParentPath $using:BaseVhdFilePath -Path $using:VhdFilePath
        
        # Create New VM with the differencing VHD etc
        # NOTE: (Known bug) Ideally, following syntax should be:
        # $null = New-VM -MemoryStartupBytes 1GB -Name $VMName `
        #                -VHDPath $DiffVHD.Path -SwitchName "InternalSwitch"
        $null = New-VM -MemoryStartupBytes 512MB -Name $using:VMName `
                        -VHDPath ($using:DiffVHD).Path -SwitchName "InternalSwitch"
    }
                        
    # Save the workflow state
    Checkpoint-Workflow
    
    # Start VMs in parallel and collect their IP addresse 
        $IPAddresses = foreach -parallel($i in 1..$VMCount)
        {        
            # Synthesize the VM name
            $VMName = $VMNamePrefix+$i
    
            # Start the VM
            Start-VM -Name $VMName
    
            # Wait for IP Address to be assigned
            $VMIP = Inlinescript {(Get-VM -Name $using:VMName).NetWorkAdapters.IPAddresses} `
                        -DisplayName "Get-VMIPAddress"
            while($VMIP.count -lt 2) {
                $VMIP = Inlinescript {(Get-VM -Name $using:VMName).NetWorkAdapters.IPAddresses} `
                        -DisplayName "Get-VMIPAddress"
                
                # Write custom progress
                Write-Progress -Id $i -Activity "Get-VMIPAddress on $VMName" `
                        -Status "Waiting for IP Address ..."
         
                Start-Sleep -Seconds 5;
            }
            $VMIP[0]
        }
                        
    # Show the IPs collected
    $IPAddresses

    # Send mail to senior admin notifying the suspended state of workflow 
    Send-MailMessage -from "powershelldemo@hotmail.com" `
            -to "powershelldemo@hotmail.com" `
            -SmtpServer "smtp.live.com" `
            -subject "A suspended workflow requires attention" `
            -useSSL `
            -port 587 `
            -credential $mailCred `
            -body `
             @"
        A workflow requires your attention. Click on the following link to resume this workflow:
        
        http://192.168.0.3:8084/PSWorkflow/psws.svc/ResumeWorkflow(guid'$($parentjobinstanceid.guid)')           
"@
                        
    # Suspend the workflow execution        
    Suspend-Workflow 

    # Join the VMs to the domain 
    Join-Domain -PSComputerName $IPAddresses -PSCredential $localCred -domainCred $domainCred
                        
    # Send mail to senior admin notifying the completion of workflow 
    Send-MailMessage -from "powershelldemo@hotmail.com" `
            -to "powershelldemo@hotmail.com" `
            -SmtpServer "smtp.live.com" `
            -subject "Workflow $parentjobname with InstanceID:$($parentjobinstanceid.guid) has completed" `
            -useSSL `
            -port 587 `
            -credential $mailCred `
            -body `
             @"
        Click on the following link to see the results of this workflow:
               
        http://192.168.0.3:8084/PSWorkflow/psws.svc/ReceiveWorkflow(guid'$($parentjobinstanceid.guid)')           
"@
                    
}

# Join Domain workflow 
workflow Join-Domain
{
    param(
	    [string] $domainName="fourthcoffee.com",
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.PSCredential] $domainCred
    )

    # Joined to WORKGROUP
    Get-CimInstance -ClassName CIM_ComputerSystem

    # Add the machine to domain and restart
    Add-Computer -DomainName $domainName -LocalCredential $PSCredential -Credential $domainCred
    Restart-Computer -Wait -For WinRM -Force -Protocol WSMan

    # Now joined to domain!
    Get-CimInstance -ClassName CIM_ComputerSystem
}
                    