#Create VM
$cred = Get-Credential
#Create VM, Resource group, location.  If you want to change them, change what's inside quotes
New-AzVm `
    -ResourceGroupName "myResourceGroupMonitor" `
    -Name "myVM" `
    -Location "East US" `
    -Credential $cred

#View boot diagnostics
Get-AzVMBootDiagnosticsData -ResourceGroupName "myResourceGroupMonitor" -Name "myVM" -Windows -LocalPath "c:\"

