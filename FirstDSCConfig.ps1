<#
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║		  
║                        PowerShell Conference Asia 2017                       ║
╟──────────────────────────────────────────────────────────────────────────────╢
║	                      Your First DSC Configuration                         ║
║	                             Jason A Yoder                                 ║
║	                                                                           ║
╚══════════════════════════════════════════════════════════════════════════════╝
#>


# ▶▶▶▶ ▶▶▶ ▶▶ ▶   DSC vs. GPO   ◀ ◀◀ ◀◀◀ ◀◀◀◀

# Download GPO Settings
Start-Process -FilePath "https://www.microsoft.com/en-us/download/details.aspx?id=25250"

# Article by Ashley McGlone : 
# Compare Group Policy (GPO) and PowerShell Desired State Configuration (DSC)

Start-Process -FilePath "https://blogs.technet.microsoft.com/ashleymcglone/2017/02/27/compare-group-policy-gpo-and-powershell-desired-state-configuration-dsc/"


# ▶▶▶▶ ▶▶▶ ▶▶ ▶   When to use what Technology   ◀ ◀◀ ◀◀◀ ◀◀◀◀

# ▶▶▶▶ ▶▶▶ ▶▶ ▶  Article by Jeremy Moskowitz
Start-Process -FilePath "http://windowsitpro.com/windows/why-group-policy-not-dead"


# ▶▶▶▶ ▶▶▶ ▶▶ ▶  Local Configuration Manager   ◀ ◀◀ ◀◀◀ ◀◀◀◀

Get-DscLocalConfigurationManager

# Class information for MSFT_DSCLocalConfigurationManager
Start-Process -FilePath "https://docs.microsoft.com/en-us/powershell/dsc/msft-dsclocalconfigurationmanager"
Start-Process -FilePath "https://docs.microsoft.com/en-us/powershell/dsc/metaconfig"


# ▶▶▶▶ ▶▶▶ ▶▶ ▶  Meta-Configuration MOF   ◀ ◀◀ ◀◀◀ ◀◀◀◀

# Check some values ofthe LCM on SVR1
Get-DscLocalConfigurationManager -CimSession SVR1 |
    Select-Object -Property ConfigurationMode, RebootNodeIfNeeded

# Create a directory structure to hold your configurations.
If (Test-path -Path C:\DSC\LCM)
{ Set-Location c:\DSC\LCM}
Else
{
    New-Item -Path c:\DSC\LCM -ItemType Directory
    Set-Location c:\DSC\LCM
}

# Create an LCM Configuration
Configuration NewServerLCMConfiguration {
    Param($Node)

    Node $Node {
        LocalConfigurationManager
        {
            ConfigurationMode              = "ApplyAndAutoCorrect"
            ConfigurationModeFrequencyMins = 15
            RefreshMode                    = "Push"
            RefreshFrequencyMins           = 30
            RebootNodeIfNeeded             = $True
        } # END: LocalConfigurationManager
    } # END: Node $Node
}# END: Configuration LCMConfiguration


# ▶▶▶▶ ▶▶▶ ▶▶ ▶  Meta-Configuration MOF   ◀ ◀◀ ◀◀◀ ◀◀◀◀

# Build the Meta-MOF file
NewServerLCMConfiguration -Node SVR1 -Verbose

# View the Meta-MOF file.
Notepad C:\DSC\LCM\NewServerLCMConfiguration\SVR1.meta.mof


# ▶▶▶▶ ▶▶▶ ▶▶ ▶  Getting the MOF to the LCM   ◀ ◀◀ ◀◀◀ ◀◀◀◀

# Push the Configuration.
Set-DSCLocalCOnfigurationManager -Path .\NewServerLCMConfiguration -ComputerName SVR1 -Verbose

# Re-check some values of the LCM on SVR1
Get-DscLocalConfigurationManager -CimSession SVR1 |
    Select-Object -Property ConfigurationMode, RebootNodeIfNeeded

# ▶▶▶▶ ▶▶▶ ▶▶ ▶  Who Changed the LCM ???   ◀ ◀◀ ◀◀◀ ◀◀◀◀

# Determine who updated an LCM

Function Get-LCMLastestAuthor {
Param (
    [String]
    $ComputerName
)
Invoke-Command `
    -ComputerName $ComputerName `
    -ScriptBlock {
        Get-WinEvent -FilterHashtable @{Logname="Microsoft-Windows-DSC/Operational" ;
                              ID=4102}} |
        Where-Object Message -like "*Operation Set-DscLocalConfigurationManager started*" |
        Select-Object -Property TimeCreated, @{
            N="Sid"
            E={$Sid = $_.Message.Split("`n")[1].
                Remove($_.Message.Split("`n")[1].LastIndexOf("from"),
                        $_.Message.Split("`n")[1].Length - $_.Message.Split("`n")[1].LastIndexOf("from")).
                Replace("Operation Set-DscLocalConfigurationManager started by user sid ",$Null).
                Trim() 
                  
            Get-ADUser -Identity "$Sid" |
                Select-Object -ExpandProperty Name
                }}

} # END: Function Get-LCMLastestAuthor 

Get-LCMLastestAuthor -ComputerName SVR1


# ▶▶▶▶ ▶▶▶ ▶▶ ▶  Building a Configuration: Basic Configuration   ◀ ◀◀ ◀◀◀ ◀◀◀◀

Configuration NewServerBuild {

} # END: Configuration NewServerBuild



# ▶▶▶▶ ▶▶▶ ▶▶ ▶  Building a Configuration: Static Node Assignment   ◀ ◀◀ ◀◀◀ ◀◀◀◀

Configuration NewServerBuild {

    Node Server001 {

    } # END: Node Server001

} # END: Configuration NewServerBuild



# ▶▶▶▶ ▶▶▶ ▶▶ ▶  Building a Configuration: Dynamic Node Assignment   ◀ ◀◀ ◀◀◀ ◀◀◀◀

Configuration NewServerBuild {

    Param (
        [String[]]$Computername
    )
    
    Node $ComputerName {

    } # END: Node $ComputerName

} # END: Configuration NewServerBuild


# ▶▶▶▶ ▶▶▶ ▶▶ ▶  DSC Resources   ◀ ◀◀ ◀◀◀ ◀◀◀◀

#  Show the default DSC Resources
Get-DscResource

# Display the syntax for the [WindowsFeature] resource.
Get-DscResource -Name WindowsFeature -Syntax

# +++++ Add a link to the online documentation for WindowsFeature +++++++++++++

Get-DscResource -Name group -Syntax

# +++++ Add a link to the online documentation for Group ++++++++++++++++++++++


# ▶▶▶▶ ▶▶▶ ▶▶ ▶  Add a Setting   ◀ ◀◀ ◀◀◀ ◀◀◀◀

Configuration NewServerBuild {

    Param (
        [String[]]$Computername
    )

    node $ComputerName {
        
        Group SuperUsers
        {
            GroupName = "SuperUsers"
            Ensure = "Present"
            MembersToInclude = "Adatum\AdminUser"
        } # END: Group SuperUsers

    } # END: Node $ComputerName

} # END: Configuration NewServerBuild

# ▶▶▶▶ ▶▶▶ ▶▶ ▶  Making Your Code a Bit Smarter   ◀ ◀◀ ◀◀◀ ◀◀◀◀

Configuration NewServerBuild {

    Param (
        [String[]]$Computername
    )
    
    Import-DscResource –ModuleName PSDesiredStateConfiguration
    node $ComputerName {
        
        Group SuperUsers
        {
            GroupName = "SuperUsers"
            Ensure = "Present"
            MembersToInclude = "Adatum\AdminUser"
        } # END: Group SuperUsers

        $Features = @('dns', 'dhcp')
        ForEach ($Feature in $Features)
        {
            WindowsFeature $Feature {
                Ensure = "Present"
                Name = $Feature
                DependsOn = "[Group]SuperUsers"
            }
        }
    } # END: Node $ComputerName

} # END: Configuration NewServerBuild



# Build the configuration file.
NewServerBuild -ComputerName SVR1 -OutputPath C:\dsc\NewServerBuild -Verbose

# View the MOF files.
Get-ChildItem -Path C:\dsc\NewServerBuild\

# View the configuration file.
Notepad C:\DSC\NewServerBuild\SVR1.mof


# ▶▶▶▶ ▶▶▶ ▶▶ ▶  Test Your Configuration   ◀ ◀◀ ◀◀◀ ◀◀◀◀

# Push the configuration
Start-DscConfiguration -Path C:\DSC\NewServerBuild -Verbose -Force

# Check the LCM State.
Get-DscLocalConfigurationManager -CimSession SVR1 |
    Select-Object -Property LCMState, LCMStateDetail

# This command will test the DSC configuration.
Test-DscConfiguration -CimSession SVR1 -Verbose

Get-DscConfiguration -CimSession SVR1

# Check for the groups on SVR1 to verify that SuperUsers is not present.
Get-CimInstance -Query "SELECT * FROM Win32_Group WHERE Name LIKE 'S%'" -CimSession SVR1

# Check SVR1 to verify that the features Windows-backup, dns-server, dhcp-server are
# not installed.
Invoke-command -ComputerName SVR1 -ScriptBlock {
    Get-WindowsFeature -Name dns, dhcp} |
    Select-Object -Property DisplayName, InstallState

# Verify that SVR1 is configured to 'ApplyAndAutoCorrect'.

Get-DscLocalConfigurationManager -CimSession SVR1

# Cause on of the servers to "Drift"
Invoke-Command -ComputerName SVR1 `
    -ScriptBlock {
        Remove-WindowsFeature -Name DHCP -Verbose -Restart
    }

# Allow SVR1 to restart.
# Verify the drift.
Invoke-command -ComputerName SVR1 -ScriptBlock {
    Get-WindowsFeature -Name dns, dhcp} |
    Select-Object -Property DisplayName, InstallState


# Check the LCM State.
Get-DscLocalConfigurationManager -CimSession SVR1 |
    Select-Object -Property LCMState, LCMStateDetail

# To speed up the fixing of the "drift", run the command below.
Start-DscConfiguration -CimSession SVR1 -UseExisting -Verbose

# If this errors, give it a few seconds.
Test-DscConfiguration -CimSession SVR1 -Verbose

# Verify the drift has been corrected.
Invoke-command -ComputerName SVR1 -ScriptBlock {
    Get-WindowsFeature -Name dns, dhcp} |
    Select-Object -Property DisplayName, InstallState


# ▶▶▶▶ ▶▶▶ ▶▶ ▶  Adding DSC Resources from the Internet   ◀ ◀◀ ◀◀◀ ◀◀◀◀

# List all modules from the PSGallery
Find-Module

# List all resources with "dsc" in the 'tag' property.
Find-Module -tag dsc | Sort-Object -Property Name

# Look for the module xTimeZone
Find-Module -Name xTimeZone

# Explore the properties of the xTimeZone resource.
Find-Module -Name xTimeZone | Select-Object -Property *
Find-Module -Name xTimeZone | Select-Object -ExpandProperty Tags
Find-Module -Name xTimeZone | Select-Object -ExpandProperty Description
Find-Module -Name xTimeZone | Select-Object -ExpandProperty ReleaseNotes
Find-Module -Name xTimeZone | Select-Object -expandProperty ProjectUri

# Look at the online documentation
Start-Process -File "$((Find-Module -Name xTimeZone).ProjectUri.AbsoluteUri)"

# Discover the correct time zone ID for Singapore using the information from the
# Readme file.
[System.TimeZoneInfo]::GetSystemTimeZones().ID

[System.TimeZoneInfo]::GetSystemTimeZones() |
    Select-Object -Property ID, DisplayName |
    Where id -like "*Singapore*"


# Install the xTimeZone module
Find-Module -Name xTimeZone | Install-Module -Verbose

# Verify that the module has been installed.
Get-DSCResource -Name xTimeZone

# Verify that the module has been installed.
ii "C:\Program Files\WindowsPowerShell\Modules"


# Modules can be updated.
Update-Module   # Updates all modules.
Update-Module -Name xTimeZone  -Verbose  # Updates a specific module.


# ▶▶▶▶ ▶▶▶ ▶▶ ▶  Viewing Documentation   ◀ ◀◀ ◀◀◀ ◀◀◀◀

ISE "C:\Program Files\WindowsPowerShell\Modules\xTimeZone\1.6.0.0\Examples\SetTimeZone.ps1"

# ▶▶▶▶ ▶▶▶ ▶▶ ▶  Deploying the Resources to your Nodes   ◀ ◀◀ ◀◀◀ ◀◀◀◀

Invoke-Command `
    -ComputerName SVR1, DC1 `
    -ScriptBlock {
        Install-PackageProvider –Name Nuget -Force
        Install-Module –Name xTimeZone –Repository PSGallery -Force -Confirm:$False -Verbose
    }

# ▶▶▶▶ ▶▶▶ ▶▶ ▶  Add a Setting   ◀ ◀◀ ◀◀◀ ◀◀◀◀

Configuration NewServerBuild {

    Param (
        [String[]]$Computername
    )
    Import-DscResource –ModuleName PSDesiredStateConfiguration
    Import-DSCResource -ModuleName xTimeZone

    node $ComputerName {
        
        Group SuperUsers
        {
            GroupName = "SuperUsers"
            Ensure = "Present"
            MembersToInclude = "Adatum\AdminUser"
        } # END: Group SuperUsers

        $Features = @('dns', 'dhcp')
        ForEach ($Feature in $Features)
        {
            WindowsFeature $Feature {
                Ensure = "Present"
                Name = $Feature
                DependsOn = "[Group]SuperUsers"
            }
        }

        xTimeZone SetTimeZone
        {
            IsSingleInstance = "Yes"
            TimeZone = "Singapore Standard Time"
        } # END: xTimeZone SetTimeZone

    } # END: Node $ComputerName

} # END: Configuration NewServerBuild

# ▶▶▶▶ ▶▶▶ ▶▶ ▶  Deploy your new configuration   ◀ ◀◀ ◀◀◀ ◀◀◀◀
NewServerBuild -ComputerName DC1, SVR1 -OutputPath C:\dsc\NewServerBuild -Verbose
Start-DscConfiguration -Path C:\DSC\NewServerBuild -Verbose -Force

Get-DscLocalConfigurationManager -CimSession SVR1 |
    Select-Object -Property LCMState, LCMStateDetail

# If this errors, give it a few seconds.
Test-DscConfiguration -CimSession SVR1 -Verbose

# ▶▶▶▶ ▶▶▶ ▶▶ ▶  Configuration Data   ◀ ◀◀ ◀◀◀ ◀◀◀◀

Configuration ServerDeployment {

    # Your configuration information.

} # END: Configuration ServerDeployment {

$ConfigData = @{} # A hash table.


ServerDeployment -ConfigurationData $ConfigData


# ▶▶▶▶ ▶▶▶ ▶▶ ▶  Building your Configuration Data   ◀ ◀◀ ◀◀◀ ◀◀◀◀

$ConfigData = @{

    AllNodes = @(

    ) <# END: AllNodes#>;

    NonNodeData = ''

} # END: $ConfigData


$ConfigData = @{

    AllNodes = @(

        @{
            NodeName = 'SVR1'
            Role     = 'WebServer'
            Site     = 'CustomApp'
            SitePath = 'C:\inetpub\approot'
        },

        @{
            NodeName = 'DC1'
            Role     = 'DomainController'
        }

    ) <# END: AllNodes#>;



} # END: $ConfigData

# View the contents of the file.
$ConfigData

$ConfigData.Values

# ▶▶▶▶ ▶▶▶ ▶▶ ▶  Deploying more resources   ◀ ◀◀ ◀◀◀ ◀◀◀◀

# The above configuration will use the xWebAdministration DSC Resource.
# We need to make sure that xTimeZone is deployed to all servers and
# xWebAdministration is deployed to all servers with the role of 'WebServer'.
# Since DC1 is the server we are authoring the configuration on, it also
# needs a copy of xWebAdministration.

# Deploying the Resources to your Nodes   ◀ ◀◀ ◀◀◀ ◀◀◀◀

Invoke-Command `
    -ComputerName SVR1, DC1 `
    -ScriptBlock {
        Install-PackageProvider –Name Nuget -Force
        Install-Module –Name xTimeZone –Repository PSGallery -Force -Confirm:$False -Verbose
        Install-Module –Name xWebAdministration –Repository PSGallery -Force -Confirm:$False -Verbose
    }



# Verify the deployment of xWebAdministration.
Invoke-Command -ComputerName SVR1 -ScriptBlock {
    Get-ChildItem -Path 'C:\Program Files\WindowsPowerShell\Modules'}

# View the syntax for xWebSite
Get-dscresource -name xwebsite -Syntax


# ▶▶▶▶ ▶▶▶ ▶▶ ▶  Build the new configuration   ◀ ◀◀ ◀◀◀ ◀◀◀◀
# NOTE:  This section of the class will deliberately introduce an error.

Configuration NewServerBuild {

    Import-DSCResource -ModuleName xWebAdministration
    Import-DSCResource -ModuleName xWebAdministration -Name xWebSite
    Import-DSCResource -ModuleName xTimeZone
    Import-DscResource –ModuleName PSDesiredStateConfiguration

   Node $AllNodes.Where({$_.NodeName -like "*"}).NodeName {
        
        Group SuperUsers
        {
            GroupName = "SuperUsers"
            Ensure = "Present"
            MembersToInclude = "Adatum\Administrator"
        } # END: Group SuperUsers

        $Features = @('DNS', 'dhcp')
        ForEach ($Feature in $Features)
        {
            WindowsFeature $Feature {
                Ensure = "Present"
                Name = $Feature
                DependsOn = "[Group]SuperUsers"
            }
        }

        xTimeZone SingaporeTimeZone
        {
            TimeZone = 'Singapore Standard Time'
            IsSingleInstance = 'Yes'
        } # END: xTimeZone SetTimeZone

    } # END: Node $AllNodes.Where({$_.NodeName -like "*").NodeName

    Node $AllNodes.Where({$_.Role -eq 'WebServer'}).NodeName {
            
  
        $Features = @('Web-Server', 'Web-Mgmt-Console')
        ForEach ($Feature in $Features)
        {
            WindowsFeature $Feature {
                Ensure = "Present"
                Name = $Feature
                DependsOn = "[Group]SuperUsers"
            }
        }

        File MyWebSiteDirectory {
            DestinationPath = $Node.SitePath
            Ensure = 'Present'
            Type = 'Directory'
        }

        xWebSite MyWebSite {
            Name = $Node.Site
            PhysicalPath = $Node.SitePath
            Ensure = 'Present'
            Dependson = "[WindowsFeature]Web-Server","[File]MyWebSiteDirectory"



        } # END" xWebSite MyWebSite
    } #END: Node $AllNodes.Where({$_.Role -eq 'WebServer'}).NodeName

} # END: Configuration NewServerBuild


# Build the configuration file using your configuration data.
NewServerBuild `
    -OutputPath C:\dsc\NewServerBuild `
    -ConfigurationData $ConfigData `
    -Verbose

# View the MOF files.
Get-ChildItem -Path C:\dsc\NewServerBuild\

# View the configuration file.
Notepad C:\DSC\NewServerBuild\SVR1.mof
Notepad C:\DSC\NewServerBuild\DC1.mof

# Push the configuration
Start-DscConfiguration -Path C:\DSC\NewServerBuild -Verbose -Force

# Check the LCM State.
Get-DscLocalConfigurationManager -CimSession SVR1 |
    Select-Object -Property LCMState, LCMStateDetail

Get-WindowsFeature -ComputerName SVR1 -Name 'Web-Server'

<# Debug ---------------------------------------------------------------------
WARNING: SVR1: LCM state is changed by non-DSC operations. If you wish to change the state of LCM,
 please use Remove-DscConfigurationDocument cmdlet.

Cause, you have an issue in your configuration.  Check the local event logs
Run this command: #>

Invoke-Command -ComputerName SVR1 -ScriptBlock {
    Get-WinEvent `
        -FilterHashtable @{Logname="Microsoft-Windows-DSC/Operational"; ID=4250}  |
    Select-Object -First 1 -ExpandProperty Message
    }

<#
Run this command to clear the warning. 
#>
Remove-DscConfigurationDocument -CimSession SVR1 -Stage Pending -Force

<# 
Fix your configuration and execute it again.
End Debug ------------------------------------------------------------------#>

# Deploy the corrected configuration.
Configuration NewServerBuild {

    Import-DSCResource -ModuleName xWebAdministration
    Import-DSCResource -ModuleName xWebAdministration -Name xWebSite
    Import-DSCResource -ModuleName xTimeZone
    Import-DscResource –ModuleName PSDesiredStateConfiguration

   Node $AllNodes.Where({$_.NodeName -like "*"}).NodeName {
        
        Group SuperUsers
        {
            GroupName = "SuperUsers"
            Ensure = "Present"
            MembersToInclude = "Adatum\Adminuser"
        } # END: Group SuperUsers

        $Features = @('DNS', 'dhcp')
        ForEach ($Feature in $Features)
        {
            WindowsFeature $Feature {
                Ensure = "Present"
                Name = $Feature
                DependsOn = "[Group]SuperUsers"
            }
        }

        xTimeZone SingaporeTimeZone
        {
            TimeZone = 'Singapore Standard Time'
            IsSingleInstance = 'Yes'
        } # END: xTimeZone SetTimeZone

    } # END: Node $AllNodes.Where({$_.NodeName -like "*").NodeName

    Node $AllNodes.Where({$_.Role -eq 'WebServer'}).NodeName {
            
  
        $Features = @('Web-Server', 'Web-Mgmt-Console')
        ForEach ($Feature in $Features)
        {
            WindowsFeature $Feature {
                Ensure = "Present"
                Name = $Feature
                DependsOn = "[Group]SuperUsers"
            }
        }

        File MyWebSiteDirectory {
            DestinationPath = $Node.SitePath
            Ensure = 'Present'
            Type = 'Directory'
        }

        xWebSite MyWebSite {
            Name = $Node.Site
            PhysicalPath = $Node.SitePath
            Ensure = 'Present'
            Dependson = "[WindowsFeature]Web-Server","[File]MyWebSiteDirectory"



        } # END" xWebSite MyWebSite
    } #END: Node $AllNodes.Where({$_.Role -eq 'WebServer'}).NodeName

} # END: Configuration NewServerBuild


# Build the configuration file using your configuration data.
NewServerBuild `
    -OutputPath C:\dsc\NewServerBuild `
    -ConfigurationData $ConfigData `
    -Verbose

# Push the configuration
Start-DscConfiguration -Path C:\DSC\NewServerBuild -Verbose -Force

# Check the LCM State.
Get-DscLocalConfigurationManager -CimSession SVR1 |
    Select-Object -Property LCMState, LCMStateDetail

Get-WindowsFeature -ComputerName SVR1 -Name 'Web-Server' 

