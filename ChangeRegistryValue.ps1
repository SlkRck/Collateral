$regpath = read-host "What is the registry path (e.g. HKLM:\Software\Policies\Microsoft\) ?" #Do NOT include KEY!
$regkey= Read-Host "What is the key you want to change?"
$regval= read-host "What is the key value (0 or 1)?"
Set-ItemProperty -Path $regpath -Name $regkey -Value $regval |Out-Null