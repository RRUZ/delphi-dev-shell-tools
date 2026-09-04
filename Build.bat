@echo off
setlocal
set "DDS_BUILD_SCRIPT=%~f0"
set "DDS_ARG1=%~1"
set "DDS_ARG2=%~2"
set "DDS_ARG3=%~3"
if not "%~4"=="" (
  echo ERROR: Too many arguments. Run Build.bat help.
  exit /b 2
)
set "DDS_POWERSHELL=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if exist "%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe" set "DDS_POWERSHELL=%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe"
"%DDS_POWERSHELL%" -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "try {$a=@(); foreach($n in 1..3){$v=[Environment]::GetEnvironmentVariable('DDS_ARG'+$n); if($v){$a+=$v}}; $body=([IO.File]::ReadAllText($env:DDS_BUILD_SCRIPT) -split '(?m)^# POWERSHELL\r?$',2)[1]; & ([scriptblock]::Create($body)) @a} catch {[Console]::Error.WriteLine('ERROR: '+$_.Exception.Message); exit 2}"
exit /b %errorlevel%
# POWERSHELL
# One-file batch/PowerShell build tool. The batch header forwards data, not code.
param(
    [ValidateSet('build', 'rebuild', 'clean', 'test', 'test-registration', 'register', 'unregister', 'status', 'help')]
    [string] $Action = 'build',
    [ValidateSet('Win32', 'Win64', 'All')]
    [string] $Platform = 'Win64',
    [ValidateSet('Debug', 'Release', 'All')]
    [string] $Configuration = 'Release'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$scriptFile = $env:DDS_BUILD_SCRIPT
$root = Split-Path -Parent $scriptFile
$classId = '{45DCA61E-3762-45B1-939D-2446C0DCAC25}'
$handlerKey = 'Software\Classes\*\shellex\ContextMenuHandlers\DelphiDevShellToolsContextMenu'

function Show-Help {
    @'
Delphi Dev. Shell Tools (Delphi 13)

  Build.bat [build|rebuild|clean] [Win64|Win32|All] [Release|Debug|All]
  Build.bat test [Win64|Win32|All] [Release|Debug|All]
  Build.bat test-registration [Win64|Win32|All] [Release|Debug|All]
  Build.bat register   [Win64|Win32] [Release|Debug]
  Build.bat unregister [Win64|Win32|All]
  Build.bat status     [Win64|Win32|All]

Defaults: build Win64 Release. Paths are relative to this script, not your cwd.
Build/rebuild compiles the shell DLL and Win32 GUI, then stages GUI + OpenSSL
beside each DLL. The updater and installer are not built or changed.
Set DELPHI_ROOT to override Delphi 13 discovery (the folder containing bin).
Register/unregister request UAC when needed; they never restart Explorer.
Unregister uses the currently registered DLL, regardless of configuration.
Status reports actual registration. Registration never happens during a build.
Build logs: build\logs. Output: Win32|Win64\Debug|Release.
Test builds/runs DUnitX tests without registration changes. Set DUNITX_ROOT
to override C:\dev\DUnitX-0.4.1. Test-registration runs already-built tests
with UAC and restores the previous registration; run test first.
'@ | Write-Host
}

function Get-RegistryValue([Microsoft.Win32.RegistryHive] $Hive,
                           [string] $TargetPlatform, [string] $Key, [string] $Name = '') {
    $view = [Microsoft.Win32.RegistryView]::Registry32
    if ($TargetPlatform -eq 'Win64') { $view = [Microsoft.Win32.RegistryView]::Registry64 }
    $base = [Microsoft.Win32.RegistryKey]::OpenBaseKey($Hive, $view)
    try {
        $entry = $base.OpenSubKey($Key)
        if ($null -eq $entry) { return $null }
        try { return $entry.GetValue($Name) } finally { $entry.Dispose() }
    } finally { $base.Dispose() }
}

function Get-RegisteredDll([string] $TargetPlatform) {
    Get-RegistryValue LocalMachine $TargetPlatform "Software\Classes\CLSID\$classId\InprocServer32"
}

function Get-OutputFolder([string] $TargetPlatform, [string] $Config) {
    Join-Path $root "$TargetPlatform\$Config"
}

function Assert-DllArchitecture([string] $Path, [string] $TargetPlatform) {
    $stream = [IO.File]::OpenRead($Path)
    $reader = New-Object IO.BinaryReader($stream)
    try {
        if ($reader.ReadUInt16() -ne 0x5A4D) { throw "Not a Windows executable: $Path" }
        $stream.Position = 0x3C
        $offset = $reader.ReadInt32()
        $stream.Position = $offset
        if ($reader.ReadUInt32() -ne 0x4550) { throw "Invalid PE header: $Path" }
        $machine = $reader.ReadUInt16()
        $expected = 0x14C
        if ($TargetPlatform -eq 'Win64') { $expected = 0x8664 }
        if ($machine -ne $expected) { throw "DLL architecture does not match $TargetPlatform`: $Path" }
    } finally { $reader.Dispose() }
}

function Find-DelphiRoot {
    if ($env:DELPHI_ROOT) { return $env:DELPHI_ROOT }
    foreach ($hive in @('CurrentUser', 'LocalMachine')) {
        foreach ($arch in @('Win32', 'Win64')) {
            $candidate = Get-RegistryValue $hive $arch 'Software\Embarcadero\BDS\37.0' 'RootDir'
            if ($candidate -and (Test-Path -LiteralPath (Join-Path $candidate 'bin\rsvars.bat'))) {
                return $candidate
            }
        }
    }
    return Join-Path ${env:ProgramFiles(x86)} 'Embarcadero\Studio\37.0'
}

function Initialize-Compiler {
    $delphi = Find-DelphiRoot
    $vars = Join-Path $delphi 'bin\rsvars.bat'
    if (-not (Test-Path -LiteralPath $vars)) {
        throw "Delphi 13 was not found. Set DELPHI_ROOT to its installation folder. Missing: $vars"
    }
    $environmentLines = & $env:ComSpec /d /c ('call "{0}" >nul && set' -f $vars)
    if ($LASTEXITCODE -ne 0) { throw "rsvars.bat failed (exit $LASTEXITCODE)." }
    foreach ($line in $environmentLines) {
        if ($line -match '^([^=]+)=(.*)$') {
            [Environment]::SetEnvironmentVariable($matches[1], $matches[2], 'Process')
        }
    }
    $script:msbuild = Join-Path $env:FrameworkDir 'MSBuild.exe'
    $script:resourceCompiler = Join-Path $env:BDS 'bin\brcc32.exe'
    foreach ($tool in @($script:msbuild, $script:resourceCompiler)) {
        if (-not (Test-Path -LiteralPath $tool)) { throw "Missing build tool: $tool" }
    }
    Write-Host "Compiler: $env:BDS"
}

function Invoke-ProjectBuild([string] $Project, [string] $TargetPlatform,
                             [string] $Config, [string] $Target, [string] $Output = '') {
    $name = [IO.Path]::GetFileNameWithoutExtension($Project)
    $log = Join-Path $root "build\logs\$name-$TargetPlatform-$Config.log"
    $arguments = @((Join-Path $root $Project), '/nologo', '/v:minimal', "/t:$Target",
        "/p:Platform=$TargetPlatform", "/p:Config=$Config", '/p:VerInfo_AutoIncVersion=false', "/flp:LogFile=$log;Verbosity=normal")
    if ($Output) {
        $arguments += "/p:DCC_ExeOutput=$Output"
        $arguments += "/p:DCC_DcuOutput=$Output"
    }
    if ($Project -eq 'tests\ShellTools.Tests.dproj' -and $env:DUNITX_ROOT) {
        $arguments += "/p:DUnitXRoot=$env:DUNITX_ROOT"
    }
    Write-Host "`n$Target $name / $TargetPlatform / $Config"
    & $script:msbuild @arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Build failed (exit $LASTEXITCODE). Log: $log. If the DLL is locked, unregister it and close the shell host holding it before rebuilding."
    }
}

function Invoke-Build {
    Initialize-Compiler
    $null = New-Item -ItemType Directory -Force -Path (Join-Path $root 'build\logs')
    $target = 'Build'
    if ($Action -eq 'rebuild') { $target = 'Clean;Build' }
    if ($Action -eq 'clean') { $target = 'Clean' }
    $openssl = Join-Path $root 'OpenSSL\openssl-1.0.1g-i386-win32'
    if ($Action -ne 'clean') {
        foreach ($name in @('libeay32.dll', 'ssleay32.dll')) {
            if (-not (Test-Path -LiteralPath (Join-Path $openssl $name))) {
                throw "Missing GUI checksum dependency: $openssl\$name. Restore the GUI checksum libraries in the OpenSSL folder."
            }
        }
        & $script:resourceCompiler (Join-Path $root 'VersionInfo.rc')
        if ($LASTEXITCODE -ne 0) { throw "VersionInfo resource compilation failed (exit $LASTEXITCODE)." }
    }
    foreach ($config in $configs) {
        $guiOutput = Join-Path $root "GUI\Win32\$config"
        Invoke-ProjectBuild 'GUI\GUIDelphiDevShell.dproj' 'Win32' $config $target $guiOutput
        foreach ($arch in $platforms) {
            Invoke-ProjectBuild 'DelphiDevShellTools.dproj' $arch $config $target
            $output = Get-OutputFolder $arch $config
            if ($Action -eq 'clean') {
                # Remove only the three files staged by this script; never delete a tree.
                foreach ($name in @('GUIDelphiDevShell.exe', 'libeay32.dll', 'ssleay32.dll')) {
                    $file = Join-Path $output $name
                    if (Test-Path -LiteralPath $file) { Remove-Item -LiteralPath $file }
                }
            } else {
                $dll = Join-Path $output 'DelphiDevShellTools.dll'
                Assert-DllArchitecture $dll $arch
                Copy-Item -LiteralPath (Join-Path $guiOutput 'GUIDelphiDevShell.exe') -Destination $output -Force
                foreach ($name in @('libeay32.dll', 'ssleay32.dll')) {
                    Copy-Item -LiteralPath (Join-Path $openssl $name) -Destination $output -Force
                }
                Write-Host "Ready: $dll"
            }
        }
    }
}

function Initialize-Defaults {
    $data = Join-Path ([Environment]::GetFolderPath('CommonApplicationData')) 'DelphiDevShellTools'
    $isNew = -not (Test-Path -LiteralPath $data)
    $null = New-Item -ItemType Directory -Force -Path $data
    if ($isNew) {
        # The legacy app writes here. Grant Modify only to the requesting user,
        # retaining inherited SYSTEM/Administrators permissions, not Everyone Full.
        $sid = $env:DDS_REQUESTING_SID
        if (-not $sid) { $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value }
        $acl = Get-Acl -LiteralPath $data
        $identity = New-Object Security.Principal.SecurityIdentifier($sid)
        $rule = New-Object Security.AccessControl.FileSystemAccessRule($identity, 'Modify', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
        $acl.AddAccessRule($rule)
        Set-Acl -LiteralPath $data -AclObject $acl
    }
    foreach ($name in @('Settings.ini', 'Tools.db', 'DelphiVersions.db', 'macros.xml')) {
        $destination = Join-Path $data $name
        if (-not (Test-Path -LiteralPath $destination)) {
            if ($name -eq 'Settings.ini') {
                # The updater is intentionally excluded from this development build.
                $settings = [IO.File]::ReadAllText((Join-Path $root $name))
                $settings = $settings -replace '(?m)^CheckForUpdates=1\r?$', 'CheckForUpdates=0'
                [IO.File]::WriteAllText($destination, $settings, [Text.Encoding]::ASCII)
            } else { Copy-Item -LiteralPath (Join-Path $root $name) -Destination $destination }
        }
    }
    $icons = Join-Path $data 'ico'
    $null = New-Item -ItemType Directory -Force -Path $icons
    foreach ($icon in Get-ChildItem -LiteralPath (Join-Path $root 'ico') -Filter '*.ico' -File) {
        $destination = Join-Path $icons $icon.Name
        if (-not (Test-Path -LiteralPath $destination)) { Copy-Item -LiteralPath $icon.FullName -Destination $destination }
    }
    Write-Host "Runtime data ready: $data (existing files preserved)."
}

function Invoke-Tests {
    foreach ($config in $configs) {
        foreach ($arch in $platforms) {
            $exe = Join-Path $root "tests\$arch\$config\ShellTools.Tests.exe"
            $dll = Join-Path (Get-OutputFolder $arch $config) 'DelphiDevShellTools.dll'
            if (-not (Test-Path -LiteralPath $exe) -or -not (Test-Path -LiteralPath $dll)) {
                throw "Tests or DLL are missing. Run Build.bat test $arch $config first."
            }
            $env:DDS_TEST_DLL = $dll
            $env:DDS_TEST_REGISTRATION = '0'
            if ($Action -eq 'test-registration') { $env:DDS_TEST_REGISTRATION = '1' }
            $report = Join-Path $root "build\logs\$Action-$arch-$config.xml"
            Write-Host "`nRunning $Action / $arch / $config"
            & $exe "--xml:$report"
            if ($LASTEXITCODE -ne 0) { throw "DUnitX failed (exit $LASTEXITCODE). Report: $report" }
            Write-Host "Passed. Report: $report"
        }
    }
}

function Invoke-Registration([string] $TargetPlatform) {
    $dll = Get-RegisteredDll $TargetPlatform
    if ($Action -eq 'register') {
        $dll = Join-Path (Get-OutputFolder $TargetPlatform $Configuration) 'DelphiDevShellTools.dll'
        foreach ($name in @('DelphiDevShellTools.dll', 'GUIDelphiDevShell.exe', 'libeay32.dll', 'ssleay32.dll')) {
            if (-not (Test-Path -LiteralPath (Join-Path (Split-Path $dll) $name))) {
                throw "Missing $name. Run Build.bat build $TargetPlatform $Configuration first."
            }
        }
        $userOverride = Get-RegistryValue CurrentUser $TargetPlatform "Software\Classes\CLSID\$classId\InprocServer32"
        if ($userOverride) { throw "A per-user COM registration overrides this class: $userOverride. Remove that override before machine registration." }
    } elseif (-not $dll) {
        Write-Host "$TargetPlatform is already unregistered."
        return
    }
    if (-not (Test-Path -LiteralPath $dll)) {
        throw "Registered DLL is missing: $dll. Rebuild that configuration before unregistering."
    }
    Assert-DllArchitecture $dll $TargetPlatform
    if ($Action -eq 'register') { Initialize-Defaults }
    $systemFolder = 'System32'
    if ($TargetPlatform -eq 'Win32' -and [Environment]::Is64BitOperatingSystem) { $systemFolder = 'SysWOW64' }
    $regsvr = Join-Path $env:SystemRoot "$systemFolder\regsvr32.exe"
    $arguments = '/s "{0}"' -f $dll
    if ($Action -eq 'unregister') { $arguments = '/s /u "{0}"' -f $dll }
    $process = Start-Process -FilePath $regsvr -ArgumentList $arguments -WindowStyle Hidden -Wait -PassThru
    if ($process.ExitCode -ne 0) { throw "regsvr32 failed (exit $($process.ExitCode)): $dll" }
    $registered = Get-RegisteredDll $TargetPlatform
    $handler = Get-RegistryValue LocalMachine $TargetPlatform $handlerKey
    if ($Action -eq 'register') {
        if ($registered -ne $dll -or $handler -ne $classId) { throw 'Registration verification failed: COM server or context-menu handler is missing.' }
        Write-Host "Registered $TargetPlatform`: $registered"
    } else {
        if ($registered -or $handler) { throw 'Unregistration verification failed: COM server or context-menu handler remains.' }
        Write-Host "Unregistered $TargetPlatform. Runtime data was preserved."
    }
    if (-not ('DevShellBuild.ShellNotify' -as [type])) {
        Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; namespace DevShellBuild { public static class ShellNotify { [DllImport("shell32.dll")] public static extern void SHChangeNotify(uint eventId, uint flags, IntPtr item1, IntPtr item2); } }'
    }
    [DevShellBuild.ShellNotify]::SHChangeNotify(0x08000000, 0, [IntPtr]::Zero, [IntPtr]::Zero)
}

function Invoke-Elevated {
    $null = New-Item -ItemType Directory -Force -Path (Join-Path $root 'build\logs')
    $log = Join-Path $root ('build\logs\{0}-{1}.log' -f $Action, [guid]::NewGuid().ToString('N'))
    $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    # Values embedded below are single-quoted PowerShell literals, escaped explicitly.
    $fileLiteral = $scriptFile.Replace("'", "''")
    $logLiteral = $log.Replace("'", "''")
    $command = "`$env:DDS_BUILD_SCRIPT='$fileLiteral'; `$env:DDS_REQUESTING_SID='$sid'; `$body=([IO.File]::ReadAllText(`$env:DDS_BUILD_SCRIPT) -split '(?m)^# POWERSHELL\r?$',2)[1]; & ([scriptblock]::Create(`$body)) '$Action' '$Platform' '$Configuration' *> '$logLiteral'"
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($command))
    Write-Host "Requesting administrator permission for $Action $Platform..."
    $powershell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $process = Start-Process -FilePath $powershell -ArgumentList "-NoLogo -NoProfile -ExecutionPolicy Bypass -EncodedCommand $encoded" -Verb RunAs -WindowStyle Hidden -Wait -PassThru
    if (Test-Path -LiteralPath $log) { Get-Content -LiteralPath $log | Write-Host }
    if ($process.ExitCode -ne 0) { throw "Elevated $Action failed (exit $($process.ExitCode)). Log: $log" }
}

try {
    if ($Action -eq 'help') { Show-Help; exit 0 }
    if ($Action -eq 'register' -and ($Platform -eq 'All' -or $Configuration -eq 'All')) {
        throw 'Register exactly one architecture/configuration at a time.'
    }
    $platforms = @($Platform)
    if ($Platform -eq 'All') { $platforms = @('Win32', 'Win64') }
    if (-not [Environment]::Is64BitOperatingSystem -and $platforms -contains 'Win64') {
        throw 'Win64 requires a 64-bit Windows host. Use Win32.'
    }
    $configs = @($Configuration)
    if ($Configuration -eq 'All') { $configs = @('Debug', 'Release') }
    Push-Location -LiteralPath $root
    try {
        if ($Action -eq 'status') {
            foreach ($arch in $platforms) {
                $registered = Get-RegisteredDll $arch
                if ($registered) { Write-Host "$arch registered: $registered" }
                else { Write-Host "$arch not registered." }
            }
        } elseif ($Action -in @('register', 'unregister', 'test-registration')) {
            $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
            $principal = New-Object Security.Principal.WindowsPrincipal($identity)
            if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
                Invoke-Elevated
            } elseif ($Action -eq 'test-registration') {
                Invoke-Tests
            } else {
                foreach ($arch in $platforms) { Invoke-Registration $arch }
            }
        } else {
            if ($Action -eq 'test') {
                $dunit = $env:DUNITX_ROOT
                if (-not $dunit) { $dunit = 'C:\dev\DUnitX-0.4.1' }
                if (-not (Test-Path -LiteralPath (Join-Path $dunit 'Source\DUnitX.TestFramework.pas'))) {
                    throw "DUnitX source not found: $dunit. Set DUNITX_ROOT."
                }
            }
            Invoke-Build
            if ($Action -eq 'test') {
                foreach ($config in $configs) {
                    foreach ($arch in $platforms) {
                        Invoke-ProjectBuild 'tests\ShellTools.Tests.dproj' $arch $config 'Build'
                    }
                }
                Invoke-Tests
            }
        }
    } finally { Pop-Location }
    exit 0
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
