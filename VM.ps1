<#
    .SYNOPSIS
        Manages a MobyLinux VM to run Linux Docker on Hyper-V

    .DESCRIPTION
        Creates/Destroys/Starts/Stops A MobyLinux VM to run Docker on Hyper-V

    .PARAMETER VmName
        If passed, use this name for the MobyLinux VM, otherwise 'MobyLinuxVM'

    .PARAMETER IsoFile
        Path to the MobyLinux ISO image, must be set for Create/ReCreate

    .PARAMETER SwitchName
        If passed, use this name for the Hyper-V virtual switch,
        otherwise 'DockerNAT'

    .PARAMETER Create
        Create a MobyLinux VM

    .PARAMETER SwitchSubnetMaskSize
        Switch subnet mask size (default: 24)

    .PARAMETER SwitchSubnetAddress
        Switch subnet address (default: 10.0.75.0)

    .PARAMETER Memory
        Memory allocated for the VM at start in MB (optional on Create, default: 2048 MB)

    .PARAMETER CPUs
        CPUs used in the VM (optional on Create, default: min(2, number of CPUs on the host))

    .PARAMETER Destroy
        Remove a MobyLinux VM

    .PARAMETER KeepVolume
        if passed, will not delete the vmhd on Destroy

    .PARAMETER Start
        Start an existing MobyLinux VM

    .PARAMETER Stop
        Stop a running MobyLinux VM

    .EXAMPLE
        .\MobyLinux.ps1 -IsoFile .\docker-for-win.iso -Create
        .\MobyLinux.ps1 -Start
#>

Param(
    [string] $VmName = "UbuntuVM",
    [string] $IsoFile = "C:\Users\ebriney\Downloads\ubuntu-18.04.1-live-server-amd64.iso",
    [string] $SwitchName = "UbuntuNAT",
    [string] $VhdPathOverride = $null,
    [long] $VhdSize = 20*1000*1000*1000,
    [string] $confIsoFile = $null,
    [string] $DockerIsoFile = $null,
    [Parameter(ParameterSetName='Create',Mandatory=$false)][switch] $Create,
    [Parameter(ParameterSetName='Create',Mandatory=$false)][int] $CPUs = 2,
    [Parameter(ParameterSetName='Create',Mandatory=$false)][long] $Memory = 2048,
    [Parameter(ParameterSetName='Create',Mandatory=$false)][string] $SwitchSubnetAddress = "10.0.77.0",
    [Parameter(ParameterSetName='Create',Mandatory=$false)][int] $SwitchSubnetMaskSize = 30,
    [Parameter(ParameterSetName='Destroy',Mandatory=$false)][switch] $Destroy,
    [Parameter(ParameterSetName='Destroy',Mandatory=$false)][switch] $KeepVolume,
    [Parameter(ParameterSetName='Start',Mandatory=$false)][switch] $Start,
    [Parameter(ParameterSetName='Stop',Mandatory=$false)][switch] $Stop
)

Write-Output "Script started at $(Get-Date -Format "HH:mm:ss.fff")"

# This makes sure the system modules can be imported
$env:PSModulePath = [Environment]::GetEnvironmentVariable('PSModulePath','Machine')

# Make sure we stop at Errors unless otherwise explicitly specified
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Explicitly disable Module autoloading and explicitly import the
# Modules this script relies on. This is not strictly necessary but
# good practise as it prevents arbitrary errors
$PSModuleAutoloadingPreference = 'None'

Import-Module Microsoft.PowerShell.Utility
Import-Module Microsoft.PowerShell.Management
Import-Module Hyper-V
Import-Module NetAdapter
Import-Module NetTCPIP

Write-Output "Modules loaded at $(Get-Date -Format "HH:mm:ss.fff")"

function Get-Vhd-Root {
    if($VhdPathOverride){
        return $VhdPathOverride
    }
    # Default location for VHDs
    $VhdRoot = "$((Hyper-V\Get-VMHost -ComputerName localhost).VirtualHardDiskPath)".TrimEnd("\")

    # Where we put Moby
    return "$VhdRoot\$VmName.vhdx"
}

function New-Switch {
    $ipParts = $SwitchSubnetAddress.Split('.')
    [int]$switchIp3 = $null
    [int32]::TryParse($ipParts[3] , [ref]$switchIp3 ) | Out-Null
    $Ip0 = $ipParts[0]
    $Ip1 = $ipParts[1]
    $Ip2 = $ipParts[2]
    $Ip3 = $switchIp3 + 1
    $switchAddress = "$Ip0.$Ip1.$Ip2.$Ip3"

    $vmSwitch = Hyper-V\Get-VMSwitch $SwitchName -SwitchType Internal -ea SilentlyContinue
    $vmNetAdapter = Hyper-V\Get-VMNetworkAdapter -ManagementOS -SwitchName $SwitchName -ea SilentlyContinue
    if ($vmSwitch -and $vmNetAdapter) {
        Write-Output "Using existing Switch: $SwitchName"
    } else {
        Write-Output "Creating Switch: $SwitchName..."

        Hyper-V\Remove-VMSwitch $SwitchName -Force -ea SilentlyContinue
        Hyper-V\New-VMSwitch $SwitchName -SwitchType Internal -ea SilentlyContinue | Out-Null
        $vmNetAdapter = Hyper-V\Get-VMNetworkAdapter -ManagementOS -SwitchName $SwitchName

        Write-Output "Switch created."
    }

    # Make sure there are no lingering net adapter
    $netAdapters = Get-NetAdapter | ? { $_.Name.StartsWith("vEthernet ($SwitchName)") }
    if (($netAdapters).Length -gt 1) {
        Write-Output "Disable and rename invalid NetAdapters"

        $now = (Get-Date -Format FileDateTimeUniversal)
        $index = 1
        $invalidNetAdapters =  $netAdapters | ? { $_.DeviceID -ne $vmNetAdapter.DeviceId }

        foreach ($netAdapter in $invalidNetAdapters) {
            $netAdapter `
                | Disable-NetAdapter -Confirm:$false -PassThru `
                | Rename-NetAdapter -NewName "Broken Docker Adapter ($now) ($index)" `
                | Out-Null

            $index++
        }
    }

    # Make sure the Switch has the right IP address
    $networkAdapter = Get-NetAdapter | ? { $_.DeviceID -eq $vmNetAdapter.DeviceId }
    if ($networkAdapter | Get-NetIPAddress -IPAddress $switchAddress -ea SilentlyContinue) {
        $networkAdapter | Disable-NetAdapterBinding -ComponentID ms_server -ea SilentlyContinue
        $networkAdapter | Enable-NetAdapterBinding  -ComponentID ms_server -ea SilentlyContinue
        Write-Output "Using existing Switch IP address"
        return
    }

    $networkAdapter | Remove-NetIPAddress -Confirm:$false -ea SilentlyContinue
    $networkAdapter | Set-NetIPInterface -Dhcp Disabled -ea SilentlyContinue
    $networkAdapter | New-NetIPAddress -AddressFamily IPv4 -IPAddress $switchAddress -PrefixLength ($SwitchSubnetMaskSize) -ea Stop | Out-Null
    
    $networkAdapter | Disable-NetAdapterBinding -ComponentID ms_server -ea SilentlyContinue
    $networkAdapter | Enable-NetAdapterBinding  -ComponentID ms_server -ea SilentlyContinue
    Write-Output "Set IP address on switch"
}

function Remove-Switch {
    Write-Output "Destroying Switch $SwitchName..."

    # Let's remove the IP otherwise a nasty bug makes it impossible
    # to recreate the vswitch
    $vmNetAdapter = Hyper-V\Get-VMNetworkAdapter -ManagementOS -SwitchName $SwitchName -ea SilentlyContinue
    if ($vmNetAdapter) {
        $networkAdapter = Get-NetAdapter | ? { $_.DeviceID -eq $vmNetAdapter.DeviceId }
        $networkAdapter | Remove-NetIPAddress -Confirm:$false -ea SilentlyContinue
    }

    Hyper-V\Remove-VMSwitch $SwitchName -Force -ea SilentlyContinue
}

function New-MobyLinuxVM {
    if (!(Test-Path $IsoFile)) {
        Fatal "ISO file at $IsoFile does not exist"
    }

    $CPUs = [Math]::min((Hyper-V\Get-VMHost -ComputerName localhost).LogicalProcessorCount, $CPUs)

    $vm = Hyper-V\Get-VM $VmName -ea SilentlyContinue
    if ($vm) {
        if ($vm.Length -ne 1) {
            Fatal "Multiple VMs exist with the name $VmName. Delete invalid ones or reset Docker to factory defaults."
        }
    } else {
        Write-Output "Creating VM $VmName..."
        $vm = Hyper-V\New-VM -Name $VmName -Generation 2 -NoVHD
        $vm | Hyper-V\Set-VM -AutomaticStartAction Nothing -AutomaticStopAction ShutDown -CheckpointType Disabled
    }

    if ($vm.Generation -ne 2) {
            Fatal "VM $VmName is a Generation $($vm.Generation) VM. It should be a Generation 2."
    }

    if ($vm.State -ne "Off") {
        Write-Output "VM $VmName is $($vm.State). Cannot change its settings."
        return
    }

    Write-Output "Setting CPUs to $CPUs and Memory to $Memory MB"
    $Memory = ([Math]::min($Memory, ($vm | Hyper-V\Get-VMMemory).MaximumPerNumaNode))
    $vm | Hyper-V\Set-VM -MemoryStartupBytes ($Memory*1024*1024) -ProcessorCount $CPUs -StaticMemory

    Ensure-VHD-Path($vm)

    $vmNetAdapter = $vm | Hyper-V\Get-VMNetworkAdapter
    if (!$vmNetAdapter) {
        Write-Output "Attach Net Adapter"
        $vmNetAdapter = $vm | Hyper-V\Add-VMNetworkAdapter -Passthru
    }

    Write-Output "Connect Internal Switch $SwitchName"
    $vmNetAdapter | Hyper-V\Connect-VMNetworkAdapter -VMSwitch $(Hyper-V\Get-VMSwitch -ComputerName localhost $SwitchName -SwitchType Internal)

    if ($vm.DVDDrives) {
        Write-Output "Remove existing DVDs"
        Hyper-V\Remove-VMDvdDrive $vm.DVDDrives -ea SilentlyContinue
    }

    Write-Output "Attach DVD $IsoFile"
    $vm | Hyper-V\Add-VMDvdDrive -Path $IsoFile
    $iso = $vm | Hyper-V\Get-VMFirmware | select -ExpandProperty BootOrder | ? { $_.FirmwarePath.EndsWith("Scsi(0,1)") }
    $vm | Hyper-V\Set-VMFirmware -EnableSecureBoot Off -FirstBootDevice $iso

    $vm | Hyper-V\Set-VMComPort -number 1 -Path "\\.\pipe\docker$VmName-com1"

    # Enable only required VM integration services
    $intSvc = @()
    $intSvc += "Microsoft:$($vm.Id)\84EAAE65-2F2E-45F5-9BB5-0E857DC8EB47" # Heartbeat
    $intSvc += "Microsoft:$($vm.Id)\9F8233AC-BE49-4C79-8EE3-E7E1985B2077" # Shutdown
    $intSvc += "Microsoft:$($vm.Id)\2497F4DE-E9FA-4204-80E4-4B75C46419C0" # TimeSynch
    $vm | Hyper-V\Get-VMIntegrationService | ForEach-Object {
        if ($intSvc -contains $_.Id) {
            Hyper-V\Enable-VMIntegrationService $_
            Write-Output "Enabled $($_.Name)"
        } else {
            Hyper-V\Disable-VMIntegrationService $_
            Write-Output "Disabled $($_.Name)"
        }
    }
    # $vm | Hyper-V\Disable-VMConsoleSupport

    Write-Output "VM created."
}

function Remove-MobyLinuxVM {
    Write-Output "Removing VM $VmName..."

    Hyper-V\Remove-VM $VmName -Force -ea SilentlyContinue

    if (!$KeepVolume) {
        $VmVhdFile = Get-Vhd-Root
        Write-Output "Delete VHD $VmVhdFile"
        Remove-Item $VmVhdFile -ea SilentlyContinue
    }
}

function Start-MobyLinuxVM {
    Write-Output "Starting VM $VmName..."

    $vm = Hyper-V\Get-VM $VmName -ea SilentlyContinue

    if ($vm.DVDDrives) {
        Write-Output "Remove existing DVDs"
        Hyper-V\Remove-VMDvdDrive $vm.DVDDrives -ea SilentlyContinue
    }

    Write-Output "Attach DVD $IsoFile"
    $vm | Hyper-V\Add-VMDvdDrive -ControllerNumber 0 -ControllerLocation 1 -Path $IsoFile

    # if ((Get-Item $confIsoFile).length -gt 0) {
    #     Write-Output "Attach Config ISO $confIsoFile"
    #     if (($vm | Get-VMScsiController).length -le 1) {
    #         $vm | Add-VMScsiController
    #     }
    #     $vm | Hyper-V\Add-VMDvdDrive -ControllerNumber 1 -ControllerLocation 1 -Path $confIsoFile
    # }
    # if ((Get-Item $DockerIsoFile).length -gt 0) {
    #     Write-Output "Attach Docker ISO $DockerIsoFile"
    #     if (($vm | Get-VMScsiController).length -le 2) {
    #         $vm | Add-VMScsiController
    #     }
    #     $vm | Hyper-V\Add-VMDvdDrive -ControllerNumber 2 -ControllerLocation 1 -Path $DockerIsoFile
    # }

    Ensure-VHD-Path($vm)

    $iso = $vm | Hyper-V\Get-VMFirmware | select -ExpandProperty BootOrder | ? { $_.FirmwarePath.EndsWith("Scsi(0,1)") }

    $vm | Hyper-V\Set-VMFirmware -EnableSecureBoot Off -BootOrder $iso

    Hyper-V\Start-VM -VMName $VmName
}

function Ensure-VHD-Path {
    Param($vm)

    $VmVhdFile = Get-Vhd-Root
    $vhd = Get-VHD -Path $VmVhdFile -ea SilentlyContinue
    if (!$vhd) {
        Write-Output "Creating dynamic VHD: $VmVhdFile"
        $vhd = New-VHD -ComputerName localhost -Path $VmVhdFile -Dynamic -SizeBytes $VhdSize -BlockSizeBytes 1MB
    }

    if ($vm.HardDrives.Path -ne $VmVhdFile) {
        if ($vm.HardDrives) {
            Write-Output "Remove existing VHDs"
            Hyper-V\Remove-VMHardDiskDrive $vm.HardDrives -ea SilentlyContinue
        }

        Write-Output "Attach VHD $VmVhdFile"
        $vm | Hyper-V\Add-VMHardDiskDrive -Path $VmVhdFile
    }
}

function Stop-MobyLinuxVM {
    $vms = Hyper-V\Get-VM $VmName -ea SilentlyContinue
    if (!$vms) {
        Write-Output "VM $VmName does not exist"
        return
    }

    foreach ($vm in $vms) {
        Stop-VM-Force($vm)
    }
}

function Stop-VM-Force {
    Param($vm)

    if ($vm.State -eq 'Off') {
        Write-Output "VM $VmName is stopped"
        return
    }

    $code = {
        Param($vmId) # Passing the $vm ref is not possible because it will be disposed already

        $vm = Hyper-V\Get-VM -Id $vmId -ea SilentlyContinue
        if (!$vm) {
            Write-Output "VM with Id $vmId does not exist"
            return
        }

        $shutdownService = $vm | Hyper-V\Get-VMIntegrationService -Name Shutdown -ea SilentlyContinue
        if ($shutdownService -and $shutdownService.PrimaryOperationalStatus -eq 'Ok') {
            Write-Output "Shutdown VM $VmName..."
            $vm | Hyper-V\Stop-VM -Confirm:$false -Force -ea SilentlyContinue
            if ($vm.State -eq 'Off') {
                return
            }
        }

        Write-Output "Turn Off VM $VmName..."
        $vm | Hyper-V\Stop-VM -Confirm:$false -TurnOff -Force -ea SilentlyContinue
    }

    Write-Output "Stopping VM $VmName..."
    $job = Start-Job -ScriptBlock $code -ArgumentList $vm.VMId.Guid
    if (Wait-Job $job -Timeout 20) { Receive-Job $job }
    Remove-Job -Force $job -ea SilentlyContinue

    if ($vm.State -eq 'Off') {
        Write-Output "VM $VmName is stopped"
        return
    }

    # If the VM cannot be stopped properly after the timeout
    # then we have to kill the process and wait till the state changes to "Off"
    for ($count = 1; $count -le 10; $count++) {
        $ProcessID = (Get-WmiObject -Namespace root\virtualization\v2 -Class Msvm_ComputerSystem -Filter "Name = '$($vm.Id.Guid)'").ProcessID
        if (!$ProcessID) {
            Write-Output "VM $VmName killed. Waiting for state to change"
            for ($count = 1; $count -le 20; $count++) {
                if ($vm.State -eq 'Off') {
                    Write-Output "Killed VM $VmName is off"
                    Remove-Switch
                    $oldKeepVolumeValue = $KeepVolume
                    $KeepVolume = $true
                    Remove-MobyLinuxVM
                    $KeepVolume = $oldKeepVolumeValue
                    return
                }
                Start-Sleep -Seconds 1
            }
            Fatal "Killed VM $VmName did not stop"
        }

        Write-Output "Kill VM $VmName process..."
        Stop-Process $ProcessID -Force -Confirm:$false -ea SilentlyContinue
        Start-Sleep -Seconds 1
    }

    Fatal "Couldn't stop VM $VmName"
}

function Fatal {
    throw "$args"
    Exit 1
}

# Main entry point
Try {
    Switch ($PSBoundParameters.GetEnumerator().Where({$_.Value -eq $true}).Key) {
        'Stop'     { Stop-MobyLinuxVM }
        'Destroy'  { Stop-MobyLinuxVM; Remove-Switch; Remove-MobyLinuxVM }
        'Create'   { New-Switch; New-MobyLinuxVM }
        'Start'    { Start-MobyLinuxVM }
    }
} Catch {
    throw
    Exit 1
}
