# Do not run the whole script at once
break

# *** Requires run as Admin ***

# Background Scheduled Jobs
Import-Module PSScheduledJob
Get-Command -Module PSScheduledJob | Sort-Object Noun | Format-Table Verb, Noun, Name, Module -AutoSize

#New-Job Trigger
Get-Command New-JobTrigger -Syntax
# http://blogs.msdn.com/b/powershell/archive/2012/03/19/scheduling-background-jobs-in-windows-powershell-3-0.aspx

# Once, Daily, Weekly Triggers
$trigger = New-JobTrigger -Once -At 3am
$trigger = New-JobTrigger -Once -At (Get-Date).AddSeconds(30)
$trigger = New-JobTrigger -Daily -At 12:15pm
$trigger = New-JobTrigger -Weekly -DaysOfWeek Friday -At 6pm

Register-ScheduledJob -Name RecentErrors -Trigger $trigger -ScriptBlock {
    Get-EventLog -LogName System -EntryType Error -Newest 5
}
Start-Job -DefinitionName RecentErrors
Get-Job
Get-Job RecentErrors | Select-Object Name,PSBeginTime,PSEndTime
Receive-Job -Name RecentErrors

# Run a regular job for comparison
Start-Job -ScriptBlock {Get-NetAdapter}

# Notice the PSJobTypeNames: PSScheduledJob and BackgroundJob
Get-Job

# Unregister is the verb to remove a registered scheduled job
Get-ScheduledJob | Unregister-ScheduledJob

# Unregister also clears the job queue
Get-ScheduledJob

# Now remove the background job also
Get-Job | Remove-Job

# Now imagine what you can do for your weekly reports.
#  1. Get-CIMInstance - collect free disk space from all your servers
#  2. Export-CSV - with date stamp on filename
#  3. Send-MailMessage - email the report to your manager as an attachment
#  4. Register-ScheduledJob - to run weekly












# Set advanced options using Get-ScheduledJobOption cmdlet
Get-ScheduledJobOption -Name RecentErrors

# Only run one backup at a time
Get-ScheduledJobOption -Name RecentErrors | Set-ScheduledJobOption -MultipleInstancePolicy Queue
Get-ScheduledJobOption -Name RecentErrors

# By default, Windows PowerShell keeps the results of the last 32 instances of each scheduled job.
# After 32 results are stored for a particular scheduled job, the oldest ones are overwritten by
# subsequent executions. To change the number of results saved for each scheduled job, use the
# MaxResultCount parameter of the Set-ScheduledJob cmdlet.
Get-ScheduledJob -Name RecentErrors | Set-ScheduledJob -MaxResultCount 100

# Transcript Cleaner Job (when profile includes Start-Transcript)
#New-Item -ItemType directory 'C:\Users\Administrator.COHOVINEYARD\Documents\PowerShell\_Transcripts'
$trigger = New-JobTrigger -Daily -At 12pm
Register-ScheduledJob -Name CleanOutPowerShellTranscripts -Trigger $trigger -ScriptBlock {
    Get-ChildItem 'C:\Users\Administrator.COHOVINEYARD\Documents\PowerShell\_Transcripts' |
    Where-Object {$_.Length -le 1kb} |
    Remove-Item
}

# Run on demand
Start-Job -DefinitionName CleanOutPowerShellTranscripts

# Simple example
Register-ScheduledJob -Name UpdateHelpJob  `
    -ScriptBlock {Update-Help} -Trigger (New-JobTrigger -Daily -At 12PM)


# Notice the PSJobTypeNames: PSScheduledJob and BackgroundJob
Get-Job
Get-Job | Receive-Job

# Only shows scheduled jobs for my profile
Get-ScheduledJob
