﻿$ErrorActionPreference = 'Stop'; # stop on all errors

$packageName = 'DraftSight'
$url         = 'http://dl-ak.solidworks.com/nonsecure/draftsight/2017SP03/DraftSight32.exe'
$url64       = 'http://dl-ak.solidworks.com/nonsecure/draftsight/2017SP03/DraftSight64.exe'
$checkSum    = '4874a8527df1a8c46aab2eb7f63805481afcc9f87a1d49e95a930cfc6d645c29'
$checkSum64  = 'ac968ebadc2827ff8aa479f0a8aaafdb24c3fb7c404fcddc6972bd8a7125107c'

$WorkSpace = Join-Path $env:TEMP "$packageName.$env:chocolateyPackageVersion"

$WebFileArgs = @{
   packageName  = $packageName
   FileFullPath = Join-Path $WorkSpace "$packageName.exe"
   Url          = $url
   Url64bit     = $url64
   Checksum     = $checkSum
   Checksum64   = $checkSum64
   ChecksumType = 'sha256'
   GetOriginalFileName = $true
}

$PackedInstaller = Get-ChocolateyWebFile @WebFileArgs

$UnzipArgs = @{
   PackageName  = $packageName
   FileFullPath = $PackedInstaller
   Destination  = $WorkSpace
}

Get-ChocolateyUnzip @UnzipArgs

$InstallArgs = @{
   PackageName    = $packageName
   File           = Join-Path $WorkSpace "$packageName.msi"
   fileType       = 'msi'
   silentArgs     = "/qn /norestart /l*v `"$($env:TEMP)\$($packageName).$($env:chocolateyPackageVersion).MsiInstall.log`" ALLUSERS=1"
   validExitCodes = @(0, 3010, 1641)
}

Install-ChocolateyInstallPackage @InstallArgs
