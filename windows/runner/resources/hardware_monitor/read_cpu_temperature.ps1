$ErrorActionPreference = "Stop"

$root = $PSScriptRoot

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal -ArgumentList $identity
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    "ERROR|ADMIN_REQUIRED"
    exit 2
}

$assemblyResolveHandler = [System.ResolveEventHandler] {
    param($sender, $eventArgs)

    $assemblyName = New-Object System.Reflection.AssemblyName -ArgumentList $eventArgs.Name
    $path = Join-Path $root ($assemblyName.Name + ".dll")
    if (Test-Path $path) {
        return [System.Reflection.Assembly]::LoadFrom($path)
    }

    return $null
}
[AppDomain]::CurrentDomain.add_AssemblyResolve($assemblyResolveHandler)

try {
    $libraryPath = Join-Path $root "LibreHardwareMonitorLib.dll"
    [System.Reflection.Assembly]::LoadFrom($libraryPath) | Out-Null

    $computer = New-Object LibreHardwareMonitor.Hardware.Computer
    $computer.IsCpuEnabled = $true
    $computer.Open()

    try {
        foreach ($hardware in $computer.Hardware) {
            $hardware.Update()

            foreach ($sensor in $hardware.Sensors) {
                if (
                    $sensor.SensorType -eq
                    [LibreHardwareMonitor.Hardware.SensorType]::Temperature -and
                    $null -ne $sensor.Value
                ) {
                    [string]::Format(
                        "{0}|{1}|{2}|{3}",
                        $hardware.HardwareType,
                        $hardware.Name,
                        $sensor.Name,
                        $sensor.Value
                    )
                }
            }

            foreach ($subHardware in $hardware.SubHardware) {
                $subHardware.Update()

                foreach ($sensor in $subHardware.Sensors) {
                    if (
                        $sensor.SensorType -eq
                        [LibreHardwareMonitor.Hardware.SensorType]::Temperature -and
                        $null -ne $sensor.Value
                    ) {
                        [string]::Format(
                            "{0}|{1}|{2}|{3}",
                            $subHardware.HardwareType,
                            $subHardware.Name,
                            $sensor.Name,
                            $sensor.Value
                        )
                    }
                }
            }
        }
    } finally {
        $computer.Close()
    }
} catch {
    [string]::Format("ERROR|{0}", $_.Exception.Message)
    exit 2
}
