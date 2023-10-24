Write-Host "rdp2ngrok by carince"
[System.Security.Principal.WindowsPrincipal] $principal = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$isUserAdmin = $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isUserAdmin) {
    Write-Host 
    Write-Host 'rdp2ngrok needs admin perms'
    Exit 1
}

$pythonUrl = "https://www.python.org/ftp/python/3.12.0/python-3.12.0-amd64.exe"
$pythonInstaller = "$($env:TEMP)\python.exe"
Write-Host 'Downloading Python Installer...'
Start-BitsTransfer -Source $pythonUrl -Destination "$pythonInstaller"

Write-Host "Installing Python..."
try {
    Start-Process -FilePath $pythonInstaller -ArgumentList "/passive InstallAllUsers=1 PrependPath=1" -Wait
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    Write-Host 'Installed Python.'
}
catch {
    Write-Host "Python installation failed:" $_
    Exit 1
}

$pythonExe = where.exe python.exe
$pythonwExe = where.exe pythonw.exe
if ($pythonExe -contains "C:\Program Files\Python312\python.exe" -and $pythonwExe -contains "C:\Program Files\Python312\pythonw.exe") {
    $pythonExe = "C:\Program Files\Python312\python.exe"
    $pythonwExe = "C:\Program Files\Python312\pythonw.exe"
}
else {
    Write-Host "Python was not found at expected directory. `npython.exe: $pythonExe `npythonw.exe: $pythonwExe"
    Exit 1
}

Write-Host
Write-Host "Downloading app script..."
$appDir = "C:\Users\Public\rdp2ngrok"
$appScript = "$appDir\app.py"
New-Item -ItemType Directory -Path $appDir | Out-Null
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/carince/rdp2ngrok/main/app.py" -OutFile $appScript
Start-Process -FilePath $pythonExe -ArgumentList "-m pip install ngrok requests privatebinapi" -WorkingDirectory $appDir -Wait

$appPath = "`"C:\Program Files\Python312\pythonw.exe`""
$taskname = 'rdp2ngrok'
$action = New-ScheduledTaskAction -Execute $appPath -Argument "C:\Users\Public\rdp2ngrok\app.py"
$trigger = New-ScheduledTaskTrigger -AtStartup
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -WakeToRun
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskname -Settings $settings -Force | Write-Verbose
Write-Host 'The install task has been scheduled. Starting the task...'
Start-ScheduledTask -TaskName $taskname

Read-Host "Press enter to exit"