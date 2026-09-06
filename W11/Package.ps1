#requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('Stage','Pack','Sign','Register','RegisterDevelopment','Remove','Status')]
    [string]$Action,
    [ValidateSet('Release','Debug')][string]$Configuration = 'Release',
    [string]$HelperDirectory,
    [string]$SdkBin = $env:DDS_WINDOWS_SDK_BIN,
    [string]$CertificateThumbprint,
    [string]$TimestampUrl,
    [string]$ExpectedUserSid
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$output = Join-Path $repo "build\modern\$Configuration"
$app = Join-Path $output 'app'
$layout = Join-Path $output 'identity'
$manifestPath = Join-Path $layout 'AppxManifest.xml'
$packagePath = Join-Path $output 'DelphiDevShellTools.Modern.msix'
[xml]$sourceManifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'AppxManifest.xml') -Raw
$packageName = $sourceManifest.Package.Identity.Name
$publisher = $sourceManifest.Package.Identity.Publisher

function Assert-UserContext {
    if ($PSEdition -ne 'Desktop') { throw 'Run registration/removal with 64-bit Windows PowerShell 5.1 (powershell.exe), not PowerShell 7.' }
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    if (!$ExpectedUserSid -or $identity.User.Value -ne $ExpectedUserSid) {
        throw 'Pass -ExpectedUserSid for the intended interactive user; package operations are per-user.'
    }
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'Run package registration/removal as the original, non-elevated interactive user (Inno Setup: runasoriginaluser).'
    }
    if (![Environment]::Is64BitProcess -or [Environment]::OSVersion.Version.Build -lt 22000) {
        throw 'The M1 prototype requires 64-bit Windows PowerShell on Windows 11 x64.'
    }
    if ($env:PROCESSOR_ARCHITECTURE -ne 'AMD64') { throw 'M1 supports x64 Explorer only.' }
}

function Get-OwnedPackage {
    @(Get-AppxPackage -Name $packageName | Where-Object { $_.Publisher -eq $publisher })
}

function Notify-ShellAssociations {
    if (!('DelphiDevShellTools.PackageShell' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
namespace DelphiDevShellTools {
    public static class PackageShell {
        [DllImport("shell32.dll")]
        public static extern void SHChangeNotify(uint eventId, uint flags, IntPtr item1, IntPtr item2);
    }
}
'@
    }
    # SHCNE_ASSOCCHANGED / SHCNF_IDLIST: refresh registrations without killing Explorer.
    [DelphiDevShellTools.PackageShell]::SHChangeNotify(0x08000000, 0, [IntPtr]::Zero, [IntPtr]::Zero)
}

function Find-SdkTool([string]$Name) {
    if ($SdkBin) {
        $tool = Join-Path $SdkBin $Name
        if (Test-Path -LiteralPath $tool) { return $tool }
        throw "SDK tool missing: $tool"
    }
    $sdkRoot = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10\bin'
    if (Test-Path -LiteralPath $sdkRoot) {
        foreach ($version in (Get-ChildItem -LiteralPath $sdkRoot -Directory | Sort-Object Name -Descending)) {
            $tool = Join-Path $version.FullName "x64\$Name"
            if (Test-Path -LiteralPath $tool) { return $tool }
        }
    }
    throw "Set -SdkBin (or DDS_WINDOWS_SDK_BIN) to the Windows SDK x64 bin folder containing $Name."
}

function Assert-AppFiles {
    foreach ($name in @('DelphiDevShellTools.Modern.dll','GUIDelphiDevShell.exe','libeay32.dll','ssleay32.dll')) {
        if (!(Test-Path -LiteralPath (Join-Path $app $name) -PathType Leaf)) { throw "Stage is incomplete: $name" }
    }
    $stream = [IO.File]::OpenRead((Join-Path $app 'DelphiDevShellTools.Modern.dll'))
    $reader = New-Object IO.BinaryReader($stream)
    try {
        if ($reader.ReadUInt16() -ne 0x5A4D) { throw 'Adapter is not a PE image.' }
        $stream.Position = 0x3C
        $peOffset = $reader.ReadInt32()
        $stream.Position = $peOffset
        if ($reader.ReadUInt32() -ne 0x4550 -or $reader.ReadUInt16() -ne 0x8664) { throw 'Adapter must be an AMD64 PE image.' }
    } finally { $reader.Dispose() }
}

switch ($Action) {
    'Stage' {
        if (!$HelperDirectory) { $HelperDirectory = Join-Path $repo "Win64\$Configuration" }
        if (!(Test-Path -LiteralPath (Join-Path $app 'DelphiDevShellTools.Modern.dll'))) { throw 'Run modern\Build.bat first.' }
        foreach ($name in @('GUIDelphiDevShell.exe','libeay32.dll','ssleay32.dll')) {
            $source = Join-Path $HelperDirectory $name
            if (!(Test-Path -LiteralPath $source)) { throw "Build the classic GUI/dependencies first; missing $source" }
        }
        New-Item -ItemType Directory -Path $layout,(Join-Path $layout 'Assets'),(Join-Path $app 'Assets') -Force | Out-Null
        foreach ($name in @('GUIDelphiDevShell.exe','libeay32.dll','ssleay32.dll')) {
            Copy-Item -LiteralPath (Join-Path $HelperDirectory $name) -Destination (Join-Path $app $name)
        }
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'AppxManifest.xml') -Destination $manifestPath
        Add-Type -AssemblyName System.Drawing
        $sourceImage = [Drawing.Image]::FromFile((Join-Path $repo 'Icons\logo.png'))
        try {
            foreach ($asset in @(@('StoreLogo.png',50),@('Square44x44Logo.png',44),@('Square150x150Logo.png',150))) {
                $size = [int]$asset[1]
                $bitmap = New-Object Drawing.Bitmap($size,$size)
                $graphics = [Drawing.Graphics]::FromImage($bitmap)
                try {
                    $graphics.Clear([Drawing.Color]::Transparent)
                    $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                    $scale = [Math]::Min($size / $sourceImage.Width, $size / $sourceImage.Height)
                    $width = [int]($sourceImage.Width * $scale)
                    $height = [int]($sourceImage.Height * $scale)
                    $graphics.DrawImage($sourceImage, [int](($size-$width)/2), [int](($size-$height)/2), $width, $height)
                    $assetPath = Join-Path $layout ('Assets\' + $asset[0])
                    $bitmap.Save($assetPath,[Drawing.Imaging.ImageFormat]::Png)
                    Copy-Item -LiteralPath $assetPath -Destination (Join-Path $app ('Assets\' + $asset[0]))
                } finally { $graphics.Dispose(); $bitmap.Dispose() }
            }
        } finally { $sourceImage.Dispose() }
        Assert-AppFiles
        Write-Output "Staged external app: $app"
    }
    'Pack' {
        Assert-AppFiles
        if (!(Test-Path -LiteralPath $manifestPath)) { throw 'Run Stage first.' }
        $tool = Find-SdkTool 'makeappx.exe'
        # Sparse packages refer to external binaries; /nv skips those path checks.
        & $tool pack /o /d $layout /nv /p $packagePath
        if ($LASTEXITCODE -ne 0) { throw "MakeAppx failed: $LASTEXITCODE" }
        Write-Output "Unsigned identity package: $packagePath"
    }
    'Sign' {
        if (!$CertificateThumbprint) { throw 'Pass a signing certificate thumbprint from CurrentUser\My; no private keys are written to this repository.' }
        $cert = Get-Item -LiteralPath "Cert:\CurrentUser\My\$CertificateThumbprint"
        if (!$cert.HasPrivateKey -or $cert.Subject -ne $publisher) { throw "Signing certificate must have a private key and Subject exactly '$publisher'." }
        $tool = Find-SdkTool 'signtool.exe'
        $signArgs = @('sign','/fd','SHA256','/s','My','/sha1',$CertificateThumbprint)
        if ($TimestampUrl) { $signArgs += @('/tr',$TimestampUrl,'/td','SHA256') }
        & $tool @signArgs $packagePath
        if ($LASTEXITCODE -ne 0) { throw "SignTool failed: $LASTEXITCODE" }
    }
    'Register' {
        Assert-UserContext
        Assert-AppFiles
        # Windows verifies the signature/trust chain. Never import certificates or bypass trust here.
        Add-AppxPackage -Path $packagePath -ExternalLocation $app -ErrorAction Stop
        Notify-ShellAssociations
        Get-OwnedPackage | Select-Object Name,Version,PackageFullName,Status
    }
    'RegisterDevelopment' {
        Assert-UserContext
        Assert-AppFiles
        $mode = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' -ErrorAction SilentlyContinue
        if (!$mode -or $mode.AllowDevelopmentWithoutDevLicense -ne 1) {
            throw 'Unsigned manifest registration requires Developer Mode already enabled. This script never changes system policy; use a trusted signed package instead.'
        }
        Add-AppxPackage -Register -Path $manifestPath -ExternalLocation $app -ErrorAction Stop
        Notify-ShellAssociations
        Get-OwnedPackage | Select-Object Name,Version,PackageFullName,Status
    }
    'Remove' {
        Assert-UserContext
        # Exact identity AND publisher, current user only. No classic CLSID/handler writes.
        foreach ($package in (Get-OwnedPackage)) { Remove-AppxPackage -Package $package.PackageFullName -ErrorAction Stop }
        Notify-ShellAssociations
        Write-Output 'Modern package removed for the current user; classic registration is unchanged.'
    }
    'Status' { Get-OwnedPackage | Select-Object Name,Version,PackageFullName,Status,InstallLocation }
}
