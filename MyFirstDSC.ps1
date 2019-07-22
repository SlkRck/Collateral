<#
Goal:
Create a registry setting Based on a servers role.
If the role of the server is 'WebServer', then apply this key.
    HKey_Local_Machine\Software\WebCode
    HKey_Local_Machine\Software\WebCode\DataFile = "C:\data"
    Datatype is string.

If the node is not a web server, apply this registry data.
    HKey_Local_Machine\Software\FileData
    HKey_Local_Machine\Software\FileData\DataFile = "D:\AdatumData"
    Datatype is string.
#>


# Discover a DSC Resource that allows you to work withregistry settings.
Get-DSCResource | Where name -like "*reg*" 

# Look at the syntax of the resource.
Get-DscResource -Name Registry -Syntax


# Examin the online documentation for the resource
Start-Process -FilePath "https://docs.microsoft.com/en-us/powershell/dsc/registryresource"

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
            MembersToInclude = "Adatum\AdminUser"
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

    Node $AllNodes.Where({$_.Role -ne 'WebServer'}).NodeName {
        Registry NonWebServerRegValue {
            Key = 'HKey_Local_Machine\Software\FileData'
            ValueName = 'DataFile'
            ValueData = "D:\AdatumData"
        } # END: Registry NonWebServerRegValue

    } # END: Node $AllNodes.Where({$_.Role -ne 'WebServer'}).NodeName {

} # END: Configuration NewServerBuild


# Build the configuration file using your configuration data.
NewServerBuild `
    -OutputPath C:\dsc\NewServerBuild `
    -ConfigurationData $ConfigData `
    -Verbose

Start-DscConfiguration -Path C:\DSC\NewServerBuild -Verbose -Force

# Check the LCM State.
Get-DscLocalConfigurationManager -CimSession DC1, SVR1 |
    Select-Object -Property LCMState, LCMStateDetail, PSComputername

Test-Path 'HKLM:\Software\FileData\DataFile'