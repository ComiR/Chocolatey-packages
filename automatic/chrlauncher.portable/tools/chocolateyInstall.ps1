﻿$ErrorActionPreference = 'Stop'  # stop on all errors

$ToolsDir   = Join-Path $env:ChocolateyPackageFolder 'tools'

# Remove previous versions
$Previous = Get-ChildItem $env:ChocolateyPackageFolder -filter 'chrlauncher*' | ?{ $_.PSIsContainer }
if ($Previous) {
   $Previous | % { Remove-Item $_.FullName -Recurse -Force }
}

$InstallArgs = @{
   packageName  = $env:ChocolateyPackageName
   FileFullPath = (Get-ChildItem $ToolsDir -Filter "*.zip").FullName
   Destination  = (Join-path $env:ChocolateyPackageFolder ($env:ChocolateyPackageName.split('.')[0] + $env:ChocolateyPackageVersion))
}

Get-ChocolateyUnzip @InstallArgs

$BitLevel = Get-ProcessorBits
$target   = Join-Path $InstallArgs.Destination "$BitLevel\chrlauncher.exe"
$shortcut = Join-Path ([System.Environment]::GetFolderPath('Desktop')) 'Chromium Launcher.lnk'

Install-ChocolateyShortcut -ShortcutFilePath $shortcut -TargetPath $target


# Capturing Package Parameters.
$UserArguments = @{}
if ($env:chocolateyPackageParameters) {
   $match_pattern = "\/(?<option>([a-zA-Z]+)):(?<value>([`"'])?([a-zA-Z0-9- _\\:\.]+)([`"'])?)|\/(?<option>([a-zA-Z]+))"
   $option_name = 'option'
   $value_name = 'value'

   if ($env:chocolateyPackageParameters -match $match_pattern ){
      $results = $env:chocolateyPackageParameters | Select-String $match_pattern -AllMatches
      $results.matches | ForEach-Object {$UserArguments.Add(
                           $_.Groups[$option_name].Value.Trim(),
                           $_.Groups[$value_name].Value.Trim())
                        }
   } else { Throw 'Package Parameters were found but were invalid (REGEX Failure)' }
} else { Write-Debug 'No Package Parameters Passed in' }

if ($UserArguments.ContainsKey('Default')) {
   $msgtext = 'You want chrlauncher as the system default browser.'
   Write-Host $msgtext -ForegroundColor Cyan
   $Bat = Join-Path $InstallArgs.unzipLocation "$BitLevel\SetDefaultBrowser.bat"
   $NoPauseBat = Join-Path (Split-Path $Bat) 'NoPauseSetDefaultBrowser.bat'
   (Get-Content $Bat) -ne 'pause' | Out-File $NoPauseBat -Encoding ascii -Force
   & $NoPauseBat
}

if ($UserArguments.ContainsKey('Shared')) {
   $msgtext = 'You want chrlauncher to install/update/launch a single instance of Chromium to be shared (including settings, bookmarks, etc.) among all users.'
   Write-Host $msgtext -ForegroundColor Cyan
   $Acl = get-acl $InstallArgs.UnzipLocation
   $InheritanceFlag = [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit
   $PropagationFlag = [System.Security.AccessControl.PropagationFlags]::InheritOnly
   $rule = New-Object  system.security.accesscontrol.filesystemaccessrule('BUILTIN\Users','Modify',$InheritanceFlag,$PropagationFlag,'Allow')
   $Acl.setaccessrule($rule)
   set-acl $InstallArgs.UnzipLocation $Acl
} else {
   $msgtext = 'chrlauncher will install/update/launch Chromium independently for each user.'
   Write-Host $msgtext -ForegroundColor Cyan
   $INIfile = Join-Path (Split-Path $target) 'chrlauncher.ini'
   (gc $INIfile) -replace "^(ChromiumDirectory=).*$",'$1%LOCALAPPDATA%\Chromium\bin' | Set-Content $INIfile
}

if ($UserArguments.ContainsKey('Type')) {
   $msgtext = 'You want to use a Chromium build other than the unofficial development builds with codecs.'
   Write-Host $msgtext -ForegroundColor Cyan
   $NotValid = $false
   switch ($UserArguments['Type']) {
      'dev-official'         { $ValidType = 'dev-official'; break }
      'stable-codecs-sync'   { $ValidType = 'stable-codecs-sync'; break }
      'dev-codecs-nosync'    { $ValidType = 'dev-codecs-nosync'; break }
      'stable-codecs-nosync' { $ValidType = 'stable-codecs-nosync'; break }
      'ungoogled-chromium'   { $ValidType = 'ungoogled-chromium'; break }
      default                { $NotValid = $true; $ValidType = 'dev-codecs-sync' }
   }
   if ($NotValid) {
      $msgtext = "The value '" + $UserArguments['Type'] + "' is not a Chromium build that chrlauncher recognizes." +
                  "`nFalling back to use the default, unofficial development builds with codecs."
      Write-Warning $msgtext
   } else {
      $INIfile = Join-Path (Split-Path $target) 'chrlauncher.ini'
      (Get-Content $INIfile) -replace "^(ChromiumType=).*$","`$1$ValidType" | Set-Content $INIfile
      $msgtext = "chrlauncher will install/update/launch the '$ValidType' Chromium build."
      Write-Host $msgtext -ForegroundColor Cyan
   }
}

