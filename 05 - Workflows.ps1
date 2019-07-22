# Do not run the whole script at once
break

# May need to run in a fresh ISE host session if you get an error "ResetRunspaceState".

# Workflow -- long running capability and reliability
#  "Workflows are typically long-running scripts that are designed to survive
#  component or network errors and reboots."
#  "Reliably executing long-running tasks across multiple computers, devices or IT processes"
#  long-running, repeatable, frequent, parallelizable, interruptible, suspendable, and/or restartable
#  -Parallel processes
#  -Configurable retries
#  -Progress bar
# Requires WinRM 3.0 (OOB or installed on 7/2008R2)
# http://technet.microsoft.com/en-us/library/jj134242   Introducing Windows PowerShell Workflow
# http://technet.microsoft.com/en-us/library/jj149010   about_Workflows
# http://blogs.msdn.com/b/powershell/archive/2012/03/17/when-windows-powershell-met-workflow.aspx
# http://blogs.msdn.com/b/powershell/archive/2012/06/15/high-level-architecture-of-windows-powershell-workflow-part-1.aspx
# http://blogs.msdn.com/b/powershell/archive/2012/06/19/high-level-architecture-of-windows-powershell-workflow-part-2.aspx
# http://blogs.technet.com/b/windowsserver/archive/2012/05/30/windows-server-2012-powershell-3-0-and-devops-part-2.aspx



# Basic Workflow

workflow HelloWorkflow
{
    Write-Output -InputObject "Hello From Workflow"
}

HelloWorkflow

Get-Command HelloWorkflow



# Checkpoint, Suspend and Resume Demo

workflow LongWorkflow {
    Write-Output -InputObject "Loading some information..."
    Suspend-Workflow
    Write-Output -InputObject "Performing some action..."
    Start-Sleep -Seconds 15
    Checkpoint-Workflow
    Write-Output -InputObject "Cleaning up..."
}

LongWorkflow -AsJob -JobName LongWF
Get-Job LongWF
Receive-Job LongWF -Keep
Resume-Job LongWF
Get-Job LongWF
Suspend-Job LongWF
Get-Job LongWF
Resume-Job LongWF
Get-Job LongWF
Receive-Job LongWF
Get-Job LongWF | Remove-Job



# ForEach Parallel
# Example of massive parallel data collection across a group of workstations or servers.

workflow get-InventoryWF
{
    $classes = "Win32_OperatingSystem","Win32_Processor","Win32_DiskDrive","Win32_Process","Win32_Service"
    foreach -parallel ($c in $classes)
    {
        Get-CimInstance -Class $c -CimSession $s
    }
}

$s = New-CimSession -ComputerName client1, cvweb1, cvmember1
get-InventoryWF
















# ForEach Parallel and Retry demo

Workflow Get-Inventory
{   foreach -parallel ($c in $PSComputerName)
    {
        parallel {
            $workflow:net   += Get-NetAdapter -CimSession $c
            $workflow:disks += Get-Disk -CimSession $c
        }
    }
@"
<html>
<h1>Inventory $(Get-Date)</h1>
<h2>Network</h2>
    $($net | ConvertTo-Html -Fragment -Property pscomputername,Name,MacAddress)
<br>
<h2>Disks</h2>
    $($disks | ConvertTo-Html -Fragment -Property pscomputername,FriendlyName,Size)
</html>
"@
}


Set-Location \\cvweb1\Demos\

# Call the workflow
# Pass a list of computers from a text file
# Collect x*y data all in parallel
# Notice progress bar is automatic
Get-Inventory -PSComputerName (Get-Content \\cvweb1\demos\Computers.txt) `
    -PSConnectionRetryCount 2 -PSConnectionRetryIntervalSec 2 `
    > .\Inventory.html

Start-Process .\Inventory.html
