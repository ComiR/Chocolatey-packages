import-module au

$Release = 'https://www.ccdc.cam.ac.uk/support-and-resources/Downloads/'

function global:au_GetLatest {
   $download_page = Invoke-WebRequest -Uri $Release

   $regex = '^.*?/(.*?\.exe).*'
   $Name = $download_page.allelements | Where-Object {
                                             ($_.tagname -match 'h4') -and 
                                             ($_.innertext -match "mercury.*windows")
                                          } |
                Select-Object -ExpandProperty innertext -First 1
                
   $version = ($Name -split ' ')[1]
   $url = "https://downloads.ccdc.cam.ac.uk/Mercury/$version/mercurystandalone-$version-windows-installer.exe"

   return @{ Version = $version; URL = $url }
}


function global:au_SearchReplace {
    @{
        "tools\chocolateyInstall.ps1" = @{
            "(^[$]url\s*=\s*)('.*')"      = "`$1'$($Latest.URL)'"
            "(^[$]Checksum\s*=\s*)('.*')" = "`$1'$($Latest.Checksum32)'"
            "(^[$]version\s*=\s*)('.*')"  = "`$1'$($Latest.version)'"
        }
    }
}

update -ChecksumFor 32