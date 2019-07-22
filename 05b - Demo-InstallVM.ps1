# Need domain credential to join VMs to domain 
$domainCred = Get-Credential fourthcoffee\administrator

# Need local credential to talk to machine before joining to domain
$localCred = Get-Credential localhost\administrator

# Credentials to autheticate against SMTP server for sending mail
$mailCred = Get-Credential powershelldemo@hotmail.com

# Create a remote workflow session
$wfSession = New-PSWorkflowSession -ComputerName mgmtsvr.fourthcoffee.com

# Import the workflow module on remote machine
Invoke-Command $wfSession { Import-Module C:\Demo\Install-VM.psm1 -Verbose}

# Invoke the workflow like any other command. Pass appropriate parameters.
Invoke-Command $wfSession { Install-VM -PSComputerName ManagedNode.fourthcoffee.com `
                                        -BaseVhdPath c:\VHDLibrary `
                                        -DomainCred $using:domainCred -LocalCred $using:localCred `
                                        -MailCred $using:mailCred -PSCredential $using:domainCred}

# Check the workflow job state
Invoke-Command $wfSession { Get-Job}









# Demo cleanup
Invoke-Command $wfSession { Get-Job | Resume-job -Wait | Receive-Job -Wait}
Invoke-Command $wfsession { Get-Job | Remove-Job -Force}
Get-PSSession | Remove-PSSession
Restart-Service Winrm
if ((Read-Host "Copy workflow template over Install-VM.psm1 (y/n)?") -eq 'y')
{
    Copy-Item C:\Demo\Install-VMTemplate.psm1 C:\Demo\Install-VM.psm1 -Verbose
} 
else{"not copying"}