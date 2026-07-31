@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"
set "REPORT=%~dp0Full_System_Display_Report.txt"

:: Switch to UTF-8 codepage for correct log output
chcp 65001 >nul 2>&1

echo ============================================================ > "%REPORT%"
echo   FULL SYSTEM HARDWARE ^& DISPLAY DIAGNOSTIC REPORT >> "%REPORT%"
echo   Generated: %date% %time% >> "%REPORT%"
echo ============================================================ >> "%REPORT%"
echo. >> "%REPORT%"

:: ===== 0. Administrator privileges check =====
echo [*] Checking administrator privileges... >> "%REPORT%"
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Administrator privileges: No >> "%REPORT%"
    echo Script requires Administrator rights. Exiting. >> "%REPORT%"
    pause
    exit /b 1
)
echo Administrator privileges: Yes >> "%REPORT%"
echo. >> "%REPORT%"

:: ===== 1. SYSTEM OVERVIEW =====
echo ============================================================ >> "%REPORT%"
echo   SECTION 1: SYSTEM OVERVIEW >> "%REPORT%"
echo ============================================================ >> "%REPORT%"
systeminfo | findstr /i /c:"Host Name" /c:"OS Name" /c:"OS Version" /c:"System Type" /c:"BIOS Version" >> "%REPORT%"
echo. >> "%REPORT%"

:: ===== 2. PLATFORM TYPE (DESKTOP / LAPTOP) =====
echo ============================================================ >> "%REPORT%"
echo   SECTION 2: PLATFORM TYPE >> "%REPORT%"
echo ============================================================ >> "%REPORT%"
wmic path Win32_Battery get Status /format:list 2>nul | find /i "OK" >nul
if %errorlevel% equ 0 (
    echo Battery detected: Yes >> "%REPORT%"
    set "TYPE=laptop"
) else (
    echo Battery detected: No >> "%REPORT%"
    set "TYPE=desktop"
)
echo. >> "%REPORT%"

:: ===== 3. HARDWARE INVENTORY (PowerShell CIM) =====
echo ============================================================ >> "%REPORT%"
echo   SECTION 3: HARDWARE INVENTORY >> "%REPORT%"
echo ============================================================ >> "%REPORT%"

echo --- CPU --- >> "%REPORT%"
powershell -NoProfile -Command ^
  "Get-CimInstance Win32_Processor | ForEach-Object { Write-Output ('Name=' + $_.Name); Write-Output ('NumberOfCores=' + $_.NumberOfCores); Write-Output ('NumberOfLogicalProcessors=' + $_.NumberOfLogicalProcessors); Write-Output ('MaxClockSpeed=' + $_.MaxClockSpeed) }" >> "%REPORT%" 2>&1
echo. >> "%REPORT%"

echo --- Motherboard --- >> "%REPORT%"
powershell -NoProfile -Command ^
  "Get-CimInstance Win32_BaseBoard | ForEach-Object { Write-Output ('Manufacturer=' + $_.Manufacturer); Write-Output ('Product=' + $_.Product); Write-Output ('Version=' + $_.Version); Write-Output ('SerialNumber=' + $_.SerialNumber) }" >> "%REPORT%" 2>&1
echo. >> "%REPORT%"

echo --- Physical Memory --- >> "%REPORT%"
powershell -NoProfile -Command ^
  "Get-CimInstance Win32_PhysicalMemory | ForEach-Object { Write-Output ('BankLabel=' + $_.BankLabel); Write-Output ('Capacity=' + $_.Capacity); Write-Output ('Speed=' + $_.Speed); Write-Output ('Manufacturer=' + $_.Manufacturer); Write-Output ('PartNumber=' + $_.PartNumber); Write-Output ('SerialNumber=' + $_.SerialNumber); Write-Output '---' }" >> "%REPORT%" 2>&1
echo. >> "%REPORT%"

echo --- Disk Drives --- >> "%REPORT%"
powershell -NoProfile -Command ^
  "Get-CimInstance Win32_DiskDrive | ForEach-Object { Write-Output ('Model=' + $_.Model); Write-Output ('Size=' + $_.Size); Write-Output ('InterfaceType=' + $_.InterfaceType); Write-Output ('MediaType=' + $_.MediaType); Write-Output ('SerialNumber=' + $_.SerialNumber); Write-Output '---' }" >> "%REPORT%" 2>&1
echo. >> "%REPORT%"

echo --- Logical Volumes --- >> "%REPORT%"
powershell -NoProfile -Command ^
  "Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | ForEach-Object { Write-Output ('DeviceID=' + $_.DeviceID); Write-Output ('FileSystem=' + $_.FileSystem); Write-Output ('FreeSpace=' + $_.FreeSpace); Write-Output ('Size=' + $_.Size); Write-Output '---' }" >> "%REPORT%" 2>&1
echo. >> "%REPORT%"

echo --- Network Adapters (enabled) --- >> "%REPORT%"
powershell -NoProfile -Command ^
  "Get-CimInstance Win32_NetworkAdapter -Filter 'NetEnabled=True' | ForEach-Object { Write-Output ('Name=' + $_.Name); Write-Output ('MACAddress=' + $_.MACAddress); Write-Output ('AdapterType=' + $_.AdapterType); Write-Output ('Speed=' + $_.Speed); Write-Output '---' }" >> "%REPORT%" 2>&1
echo. >> "%REPORT%"

echo --- Audio Devices --- >> "%REPORT%"
powershell -NoProfile -Command ^
  "Get-CimInstance Win32_SoundDevice | ForEach-Object { Write-Output ('Name=' + $_.Name); Write-Output ('Manufacturer=' + $_.Manufacturer); Write-Output ('Status=' + $_.Status); Write-Output '---' }" >> "%REPORT%" 2>&1
echo. >> "%REPORT%"

if "%TYPE%"=="laptop" (
    echo --- Battery --- >> "%REPORT%"
    powershell -NoProfile -Command ^
      "Get-CimInstance Win32_Battery | ForEach-Object { Write-Output ('Name=' + $_.Name); Write-Output ('Status=' + $_.Status); Write-Output ('BatteryStatus=' + $_.BatteryStatus); Write-Output ('EstimatedChargeRemaining=' + $_.EstimatedChargeRemaining) }" >> "%REPORT%" 2>&1
    echo. >> "%REPORT%"
)
echo. >> "%REPORT%"

:: ===== 4. GRAPHICS ADAPTER DETAILS =====
echo ============================================================ >> "%REPORT%"
echo   SECTION 4: GRAPHICS ADAPTER >> "%REPORT%"
echo ============================================================ >> "%REPORT%"
echo --- GPU info --- >> "%REPORT%"
powershell -NoProfile -Command ^
  "Get-CimInstance Win32_VideoController | ForEach-Object { Write-Output ('Name=' + $_.Name); Write-Output ('DriverVersion=' + $_.DriverVersion); Write-Output ('DriverDate=' + $_.DriverDate); Write-Output ('VideoModeDescription=' + $_.VideoModeDescription); Write-Output ('CurrentScanMode=' + $_.CurrentScanMode); Write-Output ('AdapterRAM=' + $_.AdapterRAM); Write-Output ('CurrentRefreshRate=' + $_.CurrentRefreshRate); Write-Output '---' }" >> "%REPORT%" 2>&1
echo. >> "%REPORT%"

echo --- Monitor (Windows) --- >> "%REPORT%"
powershell -NoProfile -Command ^
  "Get-CimInstance Win32_DesktopMonitor | ForEach-Object { Write-Output ('Name=' + $_.Name); Write-Output ('ScreenWidth=' + $_.ScreenWidth); Write-Output ('ScreenHeight=' + $_.ScreenHeight); Write-Output ('MonitorType=' + $_.MonitorType); Write-Output '---' }" >> "%REPORT%" 2>&1
echo. >> "%REPORT%"

:: ===== 5. CONNECTION TYPE ANALYSIS =====
echo ============================================================ >> "%REPORT%"
echo   SECTION 5: DISPLAY CONNECTION TYPE >> "%REPORT%"
echo ============================================================ >> "%REPORT%"

for /f "delims=" %%a in ('powershell -NoProfile -Command ^
  "(Get-CimInstance Win32_VideoController | Select-Object -First 1).CurrentScanMode"') do set "SCANMODE=%%a"
echo CurrentScanMode: !SCANMODE! >> "%REPORT%"
echo. >> "%REPORT%"

:: ===== 6. MONITOR EDID DEEP ANALYSIS =====
echo ============================================================ >> "%REPORT%"
echo   SECTION 6: MONITOR EDID DATA >> "%REPORT%"
echo ============================================================ >> "%REPORT%"
echo --- Basic EDID parameters --- >> "%REPORT%"
powershell -NoProfile -Command ^
  "$m = Get-CimInstance -Namespace root/WMI -ClassName WmiMonitorBasicDisplayParams; " ^
  "if ($m) { " ^
  "  foreach ($i in $m) { " ^
  "    Write-Output ('Monitor: ' + $i.InstanceName); " ^
  "    Write-Output ('  Physical size (cm): ' + $i.MaxHorizontalImageSize + ' x ' + $i.MaxVerticalImageSize); " ^
  "    Write-Output ('  Transfer characteristics: ' + $i.DisplayTransferCharacteristic); " ^
  "  } " ^
  "} else { Write-Output 'No WmiMonitorBasicDisplayParams found.' }" >> "%REPORT%" 2>&1
echo. >> "%REPORT%"

echo --- Raw EDID (hex) --- >> "%REPORT%"
powershell -NoProfile -Command ^
  "$edid = Get-CimInstance -Namespace root/WMI -ClassName WmiMonitorDescriptorMethods; " ^
  "if ($edid) { " ^
  "  foreach ($e in $edid) { " ^
  "    $result = Invoke-CimMethod -InputObject $e -MethodName WmiGetMonitorRawEEdidV1Block -Arguments @{BlockId=0} -ErrorAction SilentlyContinue; " ^
  "    if ($result -and $result.ReturnValue -eq 0) { " ^
  "      $hex = [System.BitConverter]::ToString($result.BlockContent) -replace '-',''; " ^
  "      Write-Output $hex; " ^
  "    } else { Write-Output 'Raw EDID could not be retrieved.' } " ^
  "  } " ^
  "} else { Write-Output 'No EDID retrieval methods available.' }" >> "%REPORT%" 2>&1
echo. >> "%REPORT%"

:: ===== 7. DDC/CI BRIGHTNESS CONTROL CAPABILITY =====
echo ============================================================ >> "%REPORT%"
echo   SECTION 7: DDC/CI BRIGHTNESS CONTROL >> "%REPORT%"
echo ============================================================ >> "%REPORT%"
powershell -NoProfile -Command ^
  "$b = Get-CimInstance -Namespace root/WMI -ClassName WmiMonitorBrightness -ErrorAction SilentlyContinue; " ^
  "if ($b) { " ^
  "  foreach ($item in $b) { Write-Output ('Current Brightness: ' + $item.CurrentBrightness) } " ^
  "} else { Write-Output 'WmiMonitorBrightness class not found.' }" >> "%REPORT%" 2>&1
echo. >> "%REPORT%"

:: ===== 8. INTEL GRAPHICS REGISTRY & DPST =====
echo ============================================================ >> "%REPORT%"
echo   SECTION 8: INTEL HD GRAPHICS REGISTRY SETTINGS >> "%REPORT%"
echo ============================================================ >> "%REPORT%"
echo --- Full igfxcui tree --- >> "%REPORT%"
reg query "HKCU\Software\Intel\Display\igfxcui" /s >> "%REPORT%" 2>&1
echo. >> "%REPORT%"

echo --- DPST (Display Power Saving Technology) raw values --- >> "%REPORT%"
reg query "HKLM\SOFTWARE\Intel\Display\igfxcui\profiles\Media\DPST" /s >> "%REPORT%" 2>&1
reg query "HKCU\Software\Intel\Display\igfxcui\profiles\Media\DPST" /s >> "%REPORT%" 2>&1
echo. >> "%REPORT%"

:: ===== 9. WINDOWS COLOR MANAGEMENT =====
echo ============================================================ >> "%REPORT%"
echo   SECTION 9: WINDOWS COLOR MANAGEMENT >> "%REPORT%"
echo ============================================================ >> "%REPORT%"
echo --- Night Light --- >> "%REPORT%"
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\Cache\DefaultAccount\$$windows.data.bluelightreduction.bluelightreductionstate" /ve 2>nul >> "%REPORT%"
echo. >> "%REPORT%"

echo --- Color profiles --- >> "%REPORT%"
powershell -NoProfile -Command ^
  "Get-CimInstance Win32_ColorProfile -ErrorAction SilentlyContinue | ForEach-Object { Write-Output $_.Filename }; if (-not (Get-CimInstance Win32_ColorProfile -ErrorAction SilentlyContinue)) { Write-Output 'No color profiles installed.' }" >> "%REPORT%" 2>&1
echo. >> "%REPORT%"

:: ===== 10. SCREEN-ALTERING SOFTWARE =====
echo ============================================================ >> "%REPORT%"
echo   SECTION 10: POTENTIAL SCREEN-ALTERING SOFTWARE >> "%REPORT%"
echo ============================================================ >> "%REPORT%"
tasklist /v /fo csv 2>nul | findstr /i "f.lux flux twinkletray clickmonitorddc dimscreen sunset gamma nightlight" >> "%REPORT%" 2>&1
if %errorlevel% neq 0 echo No known screen-altering software found. >> "%REPORT%"
echo. >> "%REPORT%"

:: ===== 11. RECENT DISPLAY-RELATED EVENTS (expanded scope) =====
echo ============================================================ >> "%REPORT%"
echo   SECTION 11: SYSTEM EVENTS (DISPLAY/PNP) >> "%REPORT%"
echo ============================================================ >> "%REPORT%"
powershell -NoProfile -Command ^
  "$events = Get-WinEvent -LogName System -MaxEvents 100 -ErrorAction SilentlyContinue | Where-Object { $_.ProviderName -in @('Microsoft-Windows-Kernel-PnP','Display') }; " ^
  "if ($events) { " ^
  "  $i = 0; " ^
  "  foreach ($evt in $events) { " ^
  "    Write-Output (\"Event[$i]:\"); " ^
  "    Write-Output (\"  Log Name: System\"); " ^
  "    Write-Output (\"  Source: \" + $evt.ProviderName); " ^
  "    Write-Output (\"  Date: \" + $evt.TimeCreated); " ^
  "    Write-Output (\"  Event ID: \" + $evt.Id); " ^
  "    Write-Output (\"  Level: \" + $evt.LevelDisplayName); " ^
  "    $desc = $evt.Message; " ^
  "    if ($desc) { Write-Output (\"  Description: \" + $desc.Substring(0, [Math]::Min(300, $desc.Length))) } " ^
  "    Write-Output ''; " ^
  "    $i++; " ^
  "  } " ^
  "} else { Write-Output 'No relevant display/PNP events found in the last 100 system events.' }" >> "%REPORT%" 2>&1
echo. >> "%REPORT%"

:: ===== 12. POWER PLAN DISPLAY SETTINGS =====
echo ============================================================ >> "%REPORT%"
echo   SECTION 12: POWER PLAN DISPLAY SETTINGS >> "%REPORT%"
echo ============================================================ >> "%REPORT%"
powercfg /query SCHEME_CURRENT SUB_VIDEO aded5e82-b909-4619-9949-f5d71dac0bcb >> "%REPORT%" 2>&1
echo. >> "%REPORT%"

:: ===== 13. LAPTOP-SPECIFIC CHECKS (facts only) =====
if "%TYPE%"=="laptop" (
    echo ============================================================ >> "%REPORT%"
    echo   SECTION 13: LAPTOP-SPECIFIC DATA >> "%REPORT%"
    echo ============================================================ >> "%REPORT%"
    echo --- WMI Brightness Methods --- >> "%REPORT%"
    powershell -NoProfile -Command ^
      "$w = Get-CimInstance -Namespace root/WMI -ClassName WmiMonitorBrightnessMethods -ErrorAction SilentlyContinue; " ^
      "if ($w) { Write-Output 'Available' } else { Write-Output 'Not found' }" >> "%REPORT%" 2>&1
    echo. >> "%REPORT%"
    echo --- Services status --- >> "%REPORT%"
    sc query "HidServ" >> "%REPORT%" 2>&1
    echo. >> "%REPORT%"
    sc query "igfxCUIService2.0.0.0" >> "%REPORT%" 2>&1
    echo. >> "%REPORT%"
    echo --- ACPI driver state --- >> "%REPORT%"
    powershell -NoProfile -Command ^
      "Get-CimInstance Win32_SystemDriver -Filter \"Name='Acpi'\" | Select-Object -ExpandProperty State" >> "%REPORT%" 2>&1
    echo. >> "%REPORT%"
)

echo ============================================================ >> "%REPORT%"
echo   END OF REPORT >> "%REPORT%"
echo ============================================================ >> "%REPORT%"

echo.
echo Diagnostic complete. Full report saved to:
echo   %REPORT%
echo.
echo Please open with Notepad++ or your web browser for correct UTF-8 display.
echo For any further analysis, share the contents of the report file.
pause