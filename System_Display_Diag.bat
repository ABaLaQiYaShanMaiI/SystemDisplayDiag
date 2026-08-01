@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"
set "REPORT=%~dp0Full_System_Display_Report.txt"

chcp 65001 >nul 2>&1

echo ============================================================ > "%REPORT%"
echo   FULL SYSTEM HARDWARE ^& DISPLAY DIAGNOSTIC REPORT >> "%REPORT%"
echo   Generated: %date% %time% >> "%REPORT%"
echo ============================================================ >> "%REPORT%"
echo. >> "%REPORT%"

:: ===== 0. ADMIN CHECK =====
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

:: ===== 2. PLATFORM TYPE =====
echo ============================================================ >> "%REPORT%"
echo   SECTION 2: PLATFORM TYPE >> "%REPORT%"
echo ============================================================ >> "%REPORT%"
powershell -NoProfile -Command "if (Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue) { exit 0 } else { exit 1 }" >nul 2>&1
if !errorlevel! equ 0 (
    echo Battery detected: Yes >> "%REPORT%"
    set "TYPE=laptop"
) else (
    echo Battery detected: No >> "%REPORT%"
    set "TYPE=desktop"
)
echo. >> "%REPORT%"

:: ===== 3. HARDWARE INVENTORY =====
echo ============================================================ >> "%REPORT%"
echo   SECTION 3: HARDWARE INVENTORY >> "%REPORT%"
echo ============================================================ >> "%REPORT%"

echo --- CPU --- >> "%REPORT%"
powershell -NoProfile -Command "Get-CimInstance Win32_Processor | ForEach-Object { Write-Output ('Name=' + $_.Name); Write-Output ('Cores=' + $_.NumberOfCores); Write-Output ('Logical=' + $_.NumberOfLogicalProcessors); Write-Output ('MaxClock=' + $_.MaxClockSpeed) }" >> "%REPORT%" 2>&1
echo. >> "%REPORT%"

echo --- Motherboard --- >> "%REPORT%"
powershell -NoProfile -Command "Get-CimInstance Win32_BaseBoard | ForEach-Object { Write-Output ('Mfr=' + $_.Manufacturer); Write-Output ('Product=' + $_.Product); Write-Output ('Version=' + $_.Version); Write-Output ('SN=' + $_.SerialNumber) }" >> "%REPORT%" 2>&1
echo. >> "%REPORT%"

echo --- Physical Memory --- >> "%REPORT%"
powershell -NoProfile -Command "Get-CimInstance Win32_PhysicalMemory | ForEach-Object { Write-Output ('Bank=' + $_.BankLabel); Write-Output ('CapacityGB=' + ([math]::Round($_.Capacity/1GB,1))); Write-Output ('Speed=' + $_.Speed); Write-Output ('Mfr=' + $_.Manufacturer); Write-Output ('PartNo=' + $_.PartNumber); Write-Output '---' }" >> "%REPORT%" 2>&1
echo. >> "%REPORT%"
echo --- Disk Drives --- >> "%REPORT%"
powershell -NoProfile -Command ^
  "Get-CimInstance Win32_DiskDrive | ForEach-Object { Write-Output ('Model=' + $_.Model); Write-Output ('SizeGB=' + ([math]::Round($_.Size/1GB,1))); Write-Output ('Interface=' + $_.InterfaceType); Write-Output ('Media=' + $_.MediaType); Write-Output '---' }" >> "%REPORT%" 2>&1
echo. >> "%REPORT%"

echo --- Logical Volumes --- >> "%REPORT%"
powershell -NoProfile -Command ^
  "Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | ForEach-Object { Write-Output ('Drive=' + $_.DeviceID); Write-Output ('FS=' + $_.FileSystem); Write-Output ('FreeGB=' + ([math]::Round($_.FreeSpace/1GB,1))); Write-Output ('TotalGB=' + ([math]::Round($_.Size/1GB,1))); Write-Output '---' }" >> "%REPORT%" 2>&1
echo. >> "%REPORT%"

echo --- Network Adapters --- >> "%REPORT%"
powershell -NoProfile -Command ^
  "Get-CimInstance Win32_NetworkAdapter -Filter 'NetEnabled=True' | ForEach-Object { Write-Output ('Name=' + $_.Name); Write-Output ('MAC=' + $_.MACAddress); Write-Output ('Speed=' + $_.Speed); Write-Output '---' }" >> "%REPORT%" 2>&1
echo. >> "%REPORT%"

echo --- Audio Devices --- >> "%REPORT%"
powershell -NoProfile -Command ^
  "Get-CimInstance Win32_SoundDevice | ForEach-Object { Write-Output ('Name=' + $_.Name); Write-Output ('Status=' + $_.Status); Write-Output '---' }" >> "%REPORT%" 2>&1
echo. >> "%REPORT%"

if "!TYPE!"=="laptop" (
    echo --- Battery --- >> "%REPORT%"
    powershell -NoProfile -Command ^
      "Get-CimInstance Win32_Battery | ForEach-Object { Write-Output ('Name=' + $_.Name); Write-Output ('Status=' + $_.Status); Write-Output ('Charge=' + $_.EstimatedChargeRemaining) }" >> "%REPORT%" 2>&1
    echo. >> "%REPORT%"
)
echo. >> "%REPORT%"
:: ===== 4. GRAPHICS ADAPTER DETAILS =====
echo ============================================================ >> "%REPORT%"
echo   SECTION 4: GRAPHICS ADAPTER >> "%REPORT%"
echo ============================================================ >> "%REPORT%"
echo --- GPU Info --- >> "%REPORT%"
powershell -NoProfile -Command ^
  "$gpus=Get-CimInstance Win32_VideoController; $idx=0; foreach($g in $gpus){Write-Output ('GPU['+$idx+']:'); Write-Output ('  Name: '+$g.Name); Write-Output ('  PNPDeviceID: '+$g.PNPDeviceID); Write-Output ('  Status: '+$g.Status); Write-Output ('  AdapterRAM: '+$g.AdapterRAM); Write-Output ('  DriverVersion: '+$g.DriverVersion); Write-Output ('  DriverDate: '+$g.DriverDate); Write-Output ('  VideoProcessor: '+$g.VideoProcessor); Write-Output ('  VideoMode: '+$g.VideoModeDescription); Write-Output ('  RefreshRate: '+$g.CurrentRefreshRate); $ver=$g.DriverVersion; if($ver -match '^\d+\.\d+'){$p=$ver.Split('.'); Write-Output ('  EstWDDM: WDDM '+([int]$p[0]-20)+'.'+$p[1])}else{Write-Output '  EstWDDM: Unknown'}; Write-Output '---'; $idx++}" >> "%REPORT%" 2>&1
echo. >> "%REPORT%"

echo --- Monitor (WMI) --- >> "%REPORT%"
powershell -NoProfile -Command ^
  "Get-CimInstance Win32_DesktopMonitor | ForEach-Object { Write-Output ('Name=' + $_.Name); Write-Output ('Width=' + $_.ScreenWidth); Write-Output ('Height=' + $_.ScreenHeight); Write-Output '---' }" >> "%REPORT%" 2>&1
echo. >> "%REPORT%"

:: ===== 5. DISPLAY CONNECTION TYPE =====
echo ============================================================ >> "%REPORT%"
echo   SECTION 5: DISPLAY CONNECTION TYPE >> "%REPORT%"
echo ============================================================ >> "%REPORT%"
echo --- Video Output Technology (WMI) --- >> "%REPORT%"
powershell -NoProfile -Command ^
  "$conn=Get-CimInstance -Namespace root/WMI -ClassName WmiMonitorConnectionParams -ErrorAction SilentlyContinue;" ^
  "if($conn){$techMap=@{0='VGA';1='S-Video';2='Composite';3='Component';4='DVI';5='HDMI';6='LVDS(eDP)';8='DisplayPort';9='8P9C_Digital';10='DisplayPort(e)'};" ^
  "foreach($c in $conn){$t=if($techMap[$c.VideoOutputTechnology]){$techMap[$c.VideoOutputTechnology]}else{'Unknown('+$c.VideoOutputTechnology+')'};Write-Output('Monitor: '+$c.InstanceName);Write-Output('  ConnectionType: '+$t)}}" ^
  "else{Write-Output 'WmiMonitorConnectionParams not available.'}" >> "%REPORT%" 2>&1
echo. >> "%REPORT%"
echo --- CurrentScanMode --- >> "%REPORT%"
powershell -NoProfile -Command ^
  "Get-CimInstance Win32_VideoController | ForEach-Object { Write-Output ('GPU: ' + $_.Name); Write-Output ('  ScanMode: ' + $_.CurrentScanMode); Write-Output ('  DACType: ' + $_.AdapterDACType) }" >> "%REPORT%" 2>&1
echo. >> "%REPORT%"

:: ===== 6. MONITOR EDID DATA =====
echo ============================================================ >> "%REPORT%"
echo   SECTION 6: MONITOR EDID DATA >> "%REPORT%"
echo ============================================================ >> "%REPORT%"
echo --- Basic EDID Parameters --- >> "%REPORT%"
powershell -NoProfile -Command ^
  "$m=Get-CimInstance -Namespace root/WMI -ClassName WmiMonitorBasicDisplayParams;" ^
  "if($m){foreach($i in $m){Write-Output('Monitor: '+$i.InstanceName);Write-Output('  Physical(cm): '+$i.MaxHorizontalImageSize+' x '+$i.MaxVerticalImageSize);Write-Output('  TransferChar: '+$i.DisplayTransferCharacteristic)}}else{Write-Output 'Not found.'}" >> "%REPORT%" 2>&1
echo. >> "%REPORT%"
echo --- Raw EDID (Hex) --- >> "%REPORT%"
powershell -NoProfile -Command ^
  "$e=Get-CimInstance -Namespace root/WMI -ClassName WmiMonitorDescriptorMethods;" ^
  "if($e){foreach($d in $e){$r=Invoke-CimMethod -InputObject $d -MethodName WmiGetMonitorRawEEdidV1Block -Arguments @{BlockId=0} -ErrorAction SilentlyContinue;if($r -and $r.ReturnValue -eq 0){Write-Output([System.BitConverter]::ToString($r.BlockContent)-replace'-','')}else{Write-Output 'Not retrievable.'}}}else{Write-Output 'No EDID methods.'}" >> "%REPORT%" 2>&1
echo. >> "%REPORT%"

:: ===== 7. DDC/CI BRIGHTNESS =====
echo ============================================================ >> "%REPORT%"
echo   SECTION 7: DDC/CI BRIGHTNESS CONTROL >> "%REPORT%"
echo ============================================================ >> "%REPORT%"
powershell -NoProfile -Command ^
  "$b=Get-CimInstance -Namespace root/WMI -ClassName WmiMonitorBrightness -ErrorAction SilentlyContinue;if($b){foreach($i in $b){Write-Output('Current Brightness: '+$i.CurrentBrightness)}}else{Write-Output 'WmiMonitorBrightness not found.'}" >> "%REPORT%" 2>&1
echo. >> "%REPORT%"
:: ===== 8. INTEL GRAPHICS REGISTRY =====
echo ============================================================ >> "%REPORT%"
echo   SECTION 8: INTEL GRAPHICS REGISTRY >> "%REPORT%"
echo ============================================================ >> "%REPORT%"
echo --- igfxcui tree --- >> "%REPORT%"
reg query "HKCU\Software\Intel\Display\igfxcui" /s >> "%REPORT%" 2>&1
echo. >> "%REPORT%"
echo --- DPST --- >> "%REPORT%"
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
echo --- Color Profiles --- >> "%REPORT%"
powershell -NoProfile -Command "Get-CimInstance Win32_ColorProfile -ErrorAction SilentlyContinue | ForEach-Object { Write-Output $_.Filename }; if (-not (Get-CimInstance Win32_ColorProfile -ErrorAction SilentlyContinue)) { Write-Output 'No color profiles installed.' }" >> "%REPORT%" 2>&1
echo. >> "%REPORT%"

:: ===== 10. SCREEN-ALTERING SOFTWARE =====
echo ============================================================ >> "%REPORT%"
echo   SECTION 10: SCREEN-ALTERING SOFTWARE >> "%REPORT%"
echo ============================================================ >> "%REPORT%"
tasklist /v /fo csv 2>nul | findstr /i "f.lux flux twinkletray clickmonitorddc dimscreen sunset gamma nightlight" >> "%REPORT%" 2>&1
if !errorlevel! neq 0 echo No known screen-altering software found. >> "%REPORT%"
echo. >> "%REPORT%"

:: ===== 11. SYSTEM EVENTS (TDR) =====
echo ============================================================ >> "%REPORT%"
echo   SECTION 11: SYSTEM EVENTS (DISPLAY/PNP/TDR) >> "%REPORT%"
echo ============================================================ >> "%REPORT%"
powershell -NoProfile -Command ^
  "$evts=Get-WinEvent -LogName System -MaxEvents 200 -ErrorAction SilentlyContinue|Where-Object{$_.Id -in @(4101,4109,4110,4114,5010,5011) -or $_.ProviderName -in @('Microsoft-Windows-Kernel-PnP','Display')};" ^
  "if($evts){$i=0;foreach($e in $evts){Write-Output('Event['+$i+']:');Write-Output('  Source: '+$e.ProviderName);Write-Output('  Date: '+$e.TimeCreated);Write-Output('  EventID: '+$e.Id);Write-Output('  Level: '+$e.LevelDisplayName);$d=$e.Message;if($d){Write-Output('  Desc: '+$d.Substring(0,[Math]::Min(300,$d.Length)))};Write-Output '';$i++}}else{Write-Output 'No relevant display/PNP/TDR events found in last 200.'}" >> "%REPORT%" 2>&1
echo. >> "%REPORT%"

:: ===== 12. POWER PLAN DISPLAY SETTINGS =====
echo ============================================================ >> "%REPORT%"
echo   SECTION 12: POWER PLAN DISPLAY SETTINGS >> "%REPORT%"
echo ============================================================ >> "%REPORT%"
powercfg /query SCHEME_CURRENT SUB_VIDEO aded5e82-b909-4619-9949-f5d71dac0bcb >> "%REPORT%" 2>&1
echo. >> "%REPORT%"
:: ===== 13. LAPTOP-SPECIFIC =====
if "!TYPE!"=="laptop" (
    echo ============================================================ >> "%REPORT%"
    echo   SECTION 13: LAPTOP-SPECIFIC DATA >> "%REPORT%"
    echo ============================================================ >> "%REPORT%"
    echo --- WMI Brightness Methods --- >> "%REPORT%"
    powershell -NoProfile -Command "$w=Get-CimInstance -Namespace root/WMI -ClassName WmiMonitorBrightnessMethods -ErrorAction SilentlyContinue;if($w){Write-Output 'Available'}else{Write-Output 'Not found'}" >> "%REPORT%" 2>&1
    echo. >> "%REPORT%"
    echo --- Services --- >> "%REPORT%"
    sc query "HidServ" >> "%REPORT%" 2>&1
    echo. >> "%REPORT%"
    sc query "igfxCUIService2.0.0.0" >> "%REPORT%" 2>&1
    echo. >> "%REPORT%"
    echo --- ACPI driver --- >> "%REPORT%"
    powershell -NoProfile -Command "Get-CimInstance Win32_SystemDriver -Filter 'Name=''Acpi''' | Select-Object -ExpandProperty State" >> "%REPORT%" 2>&1
    echo. >> "%REPORT%"
)

:: ===== 14. DEVICE MANAGER PROBLEM DEVICES =====
echo ============================================================ >> "%REPORT%"
echo   SECTION 14: PROBLEM DEVICES >> "%REPORT%"
echo ============================================================ >> "%REPORT%"
powershell -NoProfile -Command ^
  "$err=Get-CimInstance Win32_PnPEntity|Where-Object{$_.ConfigManagerErrorCode -ne 0};" ^
  "if($err){$codes=@{1='Not configured';2='Disabled';3='Driver error';9='BIOS error';10='Failed start';12='No driver';14='Service fail';18='Reinstall';19='Registry corrupt';21='Removing';22='Disabled(user)';24='Not present';28='No driver';29='Disabled(fw)';31='Load fail';32='Removed'};" ^
  "foreach($d in $err){$m=if($codes[$d.ConfigManagerErrorCode]){$codes[$d.ConfigManagerErrorCode]}else{'Code '+$d.ConfigManagerErrorCode};Write-Output('Device: '+$d.Name);Write-Output('  Error: '+$m+' ('+$d.ConfigManagerErrorCode+')');Write-Output('  PNPID: '+$d.PNPDeviceID);Write-Output '---'}}" ^
  "else{Write-Output 'No problem devices found.'}" >> "%REPORT%" 2>&1
echo. >> "%REPORT%"

:: ===== 15. MULTI-MONITOR TOPOLOGY =====
echo ============================================================ >> "%REPORT%"
echo   SECTION 15: MULTI-MONITOR TOPOLOGY >> "%REPORT%"
echo ============================================================ >> "%REPORT%"
echo --- Screen Info --- >> "%REPORT%"
powershell -NoProfile -Command ^
  "Add-Type -AssemblyName System.Windows.Forms;" ^
  "$sc=[System.Windows.Forms.Screen]::AllScreens;" ^
  "Write-Output('Monitor count: '+$sc.Count);" ^
  "foreach($s in $sc){Write-Output('  Device: '+$s.DeviceName);Write-Output('  Primary: '+$s.Primary);Write-Output('  Resolution: '+$s.Bounds.Width+'x'+$s.Bounds.Height);Write-Output('  Position: ('+$s.Bounds.X+','+$s.Bounds.Y+')');Write-Output('  BitsPerPixel: '+$s.BitsPerPixel);Write-Output ''}" >> "%REPORT%" 2>&1
echo. >> "%REPORT%"
echo --- Monitor ID (WMI) --- >> "%REPORT%"
powershell -NoProfile -Command ^
  "$ids=Get-CimInstance -Namespace root/WMI -ClassName WmiMonitorID -ErrorAction SilentlyContinue;" ^
  "if($ids){foreach($m in $ids){$n=($m.UserFriendlyName -ne 0|%{[char]$_})-join'';$sn=($m.SerialNumberID -ne 0|%{[char]$_})-join'';Write-Output('Monitor: '+$n);Write-Output('  Serial: '+$sn);Write-Output('  Week: '+$m.WeekOfManufacture);Write-Output('  Year: '+$m.YearOfManufacture);Write-Output '---'}}else{Write-Output 'WmiMonitorID not available.'}" >> "%REPORT%" 2>&1
echo. >> "%REPORT%"

:: ===== 16. GPU DRIVER CRASH HISTORY (TDR) =====
echo ============================================================ >> "%REPORT%"
echo   SECTION 16: GPU DRIVER CRASHES (TDR) >> "%REPORT%"
echo ============================================================ >> "%REPORT%"
powershell -NoProfile -Command ^
  "$tdr=Get-WinEvent -LogName System -MaxEvents 500 -ErrorAction SilentlyContinue|Where-Object{$_.Id -eq 4101};" ^
  "if($tdr){Write-Output('Driver crash count (Event 4101): '+$tdr.Count);$tdr|Select -First 10|%{Write-Output('  Time: '+$_.TimeCreated+' - '+$_.Message.Substring(0,[Math]::Min(200,$_.Message.Length)))}}else{Write-Output 'No 4101 events found.'}" >> "%REPORT%" 2>&1
echo. >> "%REPORT%"
powershell -NoProfile -Command ^
  "$x=Get-WinEvent -LogName System -MaxEvents 500 -ErrorAction SilentlyContinue|Where-Object{$_.Id -in @(4109,4110,4114,5010,5011)};" ^
  "if($x){Write-Output('Other GPU events: '+$x.Count);$x|Select -First 10|%{Write-Output('  ID='+$_.Id+' Time='+$_.TimeCreated)}}else{Write-Output 'No other GPU events found.'}" >> "%REPORT%" 2>&1
echo. >> "%REPORT%"

:: ===== 17. DPI SCALING =====
echo ============================================================ >> "%REPORT%"
echo   SECTION 17: DPI SCALING SETTINGS >> "%REPORT%"
echo ============================================================ >> "%REPORT%"
powershell -NoProfile -Command ^
  "$dpi=Get-ItemProperty -Path 'HKCU:\Control Panel\Desktop\WindowMetrics' -Name AppliedDPI -ErrorAction SilentlyContinue;" ^
  "if($dpi){Write-Output('AppliedDPI: '+$dpi.AppliedDPI+' -> '+[math]::Round($dpi.AppliedDPI/96*100)+'%')}else{Write-Output 'AppliedDPI not found.'}" >> "%REPORT%" 2>&1
echo. >> "%REPORT%"
echo --- Per-Monitor DPI --- >> "%REPORT%"
reg query "HKCU\Control Panel\Desktop\PerMonitorSettings" /s >> "%REPORT%" 2>&1
reg query "HKCU\Control Panel\Desktop" /v Win8DpiScaling >> "%REPORT%" 2>&1
echo. >> "%REPORT%"

:: ===== 18. HDR ^& ADVANCED COLOR =====
echo ============================================================ >> "%REPORT%"
echo   SECTION 18: HDR ^& ADVANCED COLOR >> "%REPORT%"
echo ============================================================ >> "%REPORT%"
reg query "HKLM\SOFTWARE\Microsoft\Windows\AdvancedColor" /s >> "%REPORT%" 2>&1
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvancedColor" /s >> "%REPORT%" 2>&1
echo. >> "%REPORT%"

:: ===== 19. VRR / G-SYNC / FREESYNC =====
echo ============================================================ >> "%REPORT%"
echo   SECTION 19: VRR / G-SYNC / FREESYNC >> "%REPORT%"
echo ============================================================ >> "%REPORT%"
powershell -NoProfile -Command "$vrr=Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm' -Name DisableVRROverlay -ErrorAction SilentlyContinue;if($vrr){Write-Output('DisableVRROverlay: '+$vrr.DisableVRROverlay)}else{Write-Output 'VRR registry key not found.'}" >> "%REPORT%" 2>&1
echo. >> "%REPORT%"
reg query "HKLM\SOFTWARE\NVIDIA Corporation\Global\GSync" /s >> "%REPORT%" 2>&1
echo. >> "%REPORT%"

:: ===== 20. GRAPHICS PERFORMANCE =====
echo ============================================================ >> "%REPORT%"
echo   SECTION 20: GRAPHICS PERFORMANCE >> "%REPORT%"
echo ============================================================ >> "%REPORT%"
echo --- HAGS --- >> "%REPORT%"
reg query "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode >> "%REPORT%" 2>&1
echo. >> "%REPORT%"
echo --- Game Mode --- >> "%REPORT%"
reg query "HKCU\Software\Microsoft\GameBar" /v AllowAutoGameMode >> "%REPORT%" 2>&1
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v AppCaptureEnabled >> "%REPORT%" 2>&1
reg query "HKCU\Software\Microsoft\DirectX\UserGpuPreferences" /s >> "%REPORT%" 2>&1
echo. >> "%REPORT%"
:: ===== 21. NVIDIA SETTINGS =====
echo ============================================================ >> "%REPORT%"
echo   SECTION 21: NVIDIA SETTINGS >> "%REPORT%"
echo ============================================================ >> "%REPORT%"
reg query "HKLM\SOFTWARE\NVIDIA Corporation\Global\Display" /s >> "%REPORT%" 2>&1
reg query "HKLM\SOFTWARE\NVIDIA Corporation\Global\NVTweak" /s >> "%REPORT%" 2>&1
sc query "NVDisplay.ContainerLocalSystem" >> "%REPORT%" 2>&1
echo. >> "%REPORT%"

:: ===== 22. AMD SETTINGS =====
echo ============================================================ >> "%REPORT%"
echo   SECTION 22: AMD SETTINGS >> "%REPORT%"
echo ============================================================ >> "%REPORT%"
reg query "HKLM\SOFTWARE\AMD\CN" /s >> "%REPORT%" 2>&1
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v DriverVersion >> "%REPORT%" 2>&1
sc query "AMD External Events Utility" >> "%REPORT%" 2>&1
echo. >> "%REPORT%"

:: ===== 23. DIRECTX DIAG (DXDIAG) =====
echo ============================================================ >> "%REPORT%"
echo   SECTION 23: DIRECTX DIAGNOSTIC >> "%REPORT%"
echo ============================================================ >> "%REPORT%"
dxdiag /t "%TEMP%\dxdiag_output.txt" >nul 2>&1
if exist "%TEMP%\dxdiag_output.txt" (
    findstr /i /c:"System Information" /c:"Operating System" /c:"Processor" /c:"Memory" /c:"DirectX Version" /c:"Display Devices" /c:"Card name" /c:"Manufacturer" /c:"Chip type" /c:"DAC type" /c:"Display Memory" /c:"Dedicated Memory" /c:"Shared Memory" /c:"Current Mode" /c:"Monitor Name" /c:"HDR" /c:"Driver Model" /c:"Feature Levels" "%TEMP%\dxdiag_output.txt" >> "%REPORT%" 2>&1
    del "%TEMP%\dxdiag_output.txt" 2>nul
) else (
    echo dxdiag.exe not available or failed. >> "%REPORT%"
)
echo. >> "%REPORT%"

:: ===== 24. DISPLAY-RELATED SERVICES =====
echo ============================================================ >> "%REPORT%"
echo   SECTION 24: DISPLAY-RELATED SERVICES >> "%REPORT%"
echo ============================================================ >> "%REPORT%"
powershell -NoProfile -Command "@('NVDisplay.ContainerLocalSystem','DisplayEnhancementService','AMD External Events Utility','igfxCUIService2.0.0.0')|ForEach-Object{Write-Output('--- '+$_+' ---');sc.exe query $_>>'%REPORT%' 2>&1;Write-Output ''}" >> "%REPORT%" 2>&1
echo. >> "%REPORT%"

:: ===== 25. DISPLAY SOFTWARE =====
echo ============================================================ >> "%REPORT%"
echo   SECTION 25: DISPLAY-RELATED SOFTWARE >> "%REPORT%"
echo ============================================================ >> "%REPORT%"
echo --- Running processes --- >> "%REPORT%"
tasklist /v /fo csv 2>nul | findstr /i "f.lux flux twinkletray clickmonitorddc dimscreen sunset gamma nightlight displayfusion ultramon actualmultiplemonitors monitorian controlmymonitor" >> "%REPORT%" 2>&1
if !errorlevel! neq 0 echo No known display-altering software found. >> "%REPORT%"
echo. >> "%REPORT%"
echo --- Remote Desktop / Screen Sharing --- >> "%REPORT%"
tasklist /v /fo csv 2>nul | findstr /i "mstsc teamviewer anydesk vnc sunshin gamestream parsec steamlink" >> "%REPORT%" 2>&1
if !errorlevel! neq 0 echo No remote/screen sharing software found. >> "%REPORT%"
echo. >> "%REPORT%"

:: ===== 26. APPLICATION EVENT LOGS =====
echo ============================================================ >> "%REPORT%"
echo   SECTION 26: APPLICATION EVENT LOGS (DISPLAY) >> "%REPORT%"
echo ============================================================ >> "%REPORT%"
powershell -NoProfile -Command ^
  "$evts=Get-WinEvent -LogName Application -MaxEvents 100 -ErrorAction SilentlyContinue|Where-Object{$_.Message -match 'display|nvidia|amd|intel.*graphics|driver.*display|nvlddmkm|amdkmdag|igdkmd|dwm\.exe' -and $_.LevelDisplayName -in @('Error','Warning','Critical')};" ^
  "if($evts){$i=0;foreach($e in $evts){Write-Output('Event['+$i+']:');Write-Output('  Source: '+$e.ProviderName);Write-Output('  Date: '+$e.TimeCreated);Write-Output('  ID: '+$e.Id);Write-Output('  Level: '+$e.LevelDisplayName);$m=$e.Message;if($m){Write-Output('  Desc: '+$m.Substring(0,[Math]::Min(250,$m.Length)))};Write-Output '';$i++}}else{Write-Output 'No display-related Application log errors/warnings found.'}" >> "%REPORT%" 2>&1
echo. >> "%REPORT%"

:: ===== 27. DISPLAY TIMEOUT ^& SCREENSAVER =====
echo ============================================================ >> "%REPORT%"
echo   SECTION 27: DISPLAY TIMEOUT ^& SCREENSAVER >> "%REPORT%"
echo ============================================================ >> "%REPORT%"
echo --- Display Timeout (AC) --- >> "%REPORT%"
powercfg /query SCHEME_CURRENT SUB_VIDEO VIDEOIDLE >> "%REPORT%" 2>&1
echo. >> "%REPORT%"
echo --- Screensaver Settings --- >> "%REPORT%"
reg query "HKCU\Control Panel\Desktop" /v SCRNSAVE.EXE >> "%REPORT%" 2>&1
reg query "HKCU\Control Panel\Desktop" /v ScreenSaveActive >> "%REPORT%" 2>&1
reg query "HKCU\Control Panel\Desktop" /v ScreenSaveTimeOut >> "%REPORT%" 2>&1
echo. >> "%REPORT%"

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