<#
.SYNOPSIS
Backup and reinstall installed packages on Windows using Winget, Scoop, and Chocolatey.
Exports JSON files to ./exports with timestamps to avoid overwriting.
#>

param(
    [switch]$Export,
    [switch]$Install
)

# -------------------------------
# Setup export folder and timestamp
# -------------------------------
$exportFolder = Join-Path -Path $PSScriptRoot -ChildPath "exports"
if (-Not (Test-Path $exportFolder)) {
    New-Item -ItemType Directory -Path $exportFolder | Out-Null
}

# Default JSON file name with timestamp
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$jsonFileName = "packages_$timestamp.json"
$jsonPath = Join-Path -Path $exportFolder -ChildPath $jsonFileName

# -------------------------------
# Functions
# -------------------------------
function Get-InstalledPackages {
    $packages = @()

    # Winget
    try {
        $wingetPackages = winget list --source winget --accept-source-agreements --accept-package-agreements | ForEach-Object {
            if ($_ -match "^(?<Name>.+?)\s{2,}(?<Id>.+?)\s{2,}(?<Version>.+?)\s{2,}(?<Publisher>.+)$") {
                [PSCustomObject]@{
                    Name      = $matches['Name'].Trim()
                    ID        = $matches['Id'].Trim()
                    Source    = 'winget'
                    Version   = $matches['Version'].Trim()
                    Publisher = $matches['Publisher'].Trim()
                }
            }
        }
        $packages += $wingetPackages
    } catch {
        Write-Warning "Winget not found or failed."
    }

    # Scoop
    try {
        $scoopPackages = scoop list | Select-Object -Skip 1 | ForEach-Object {
            if ($_ -match "^(?<Name>\S+)\s+(?<Version>\S+)") {
                [PSCustomObject]@{
                    Name      = $matches['Name']
                    Source    = 'scoop'
                    Version   = $matches['Version']
                    Publisher = ''
                }
            }
        }
        $packages += $scoopPackages
    } catch {
        Write-Warning "Scoop not found or failed."
    }

    # Chocolatey
    try {
        $chocoPackages = choco list --localonly --exact | Select-Object -Skip 1 | ForEach-Object {
            if ($_ -match "^(?<Name>[^|]+)\|(?<Version>.+)$") {
                [PSCustomObject]@{
                    Name      = $matches['Name']
                    ID        = $matches['Name']   # Chocolatey uses package name as ID
                    Source    = 'chocolatey'
                    Version   = $matches['Version']
                    Publisher = ''
                }
            }
        }
        $packages += $chocoPackages
    } catch {
        Write-Warning "Chocolatey not found or failed."
    }

    return $packages
}

function Export-PackagesToJson {
    $packages = Get-InstalledPackages
    $packages | ConvertTo-Json -Depth 3 | Set-Content -Path $jsonPath
    Write-Host "Exported $($packages.Count) packages to $jsonPath"
}

function Install-PackagesFromJson {
    # If no JSON exists, pick the latest file in exports
    if (-Not $InstallPath) {
        $jsonFiles = Get-ChildItem -Path $exportFolder -Filter "*.json" | Sort-Object LastWriteTime -Descending
        if ($jsonFiles.Count -eq 0) {
            Write-Error "No JSON files found in $exportFolder"
            return
        }
        $jsonPath = $jsonFiles[0].FullName
    }

    $packages = Get-Content $jsonPath | ConvertFrom-Json

    foreach ($pkg in $packages) {
        switch ($pkg.Source) {
            'winget' {
                if ($pkg.ID) {
                    Write-Host "Installing $($pkg.Name) via Winget (ID: $($pkg.ID))..."
                    winget install --id "$($pkg.ID)" --accept-source-agreements --accept-package-agreements --silent
                } else {
                    Write-Warning "No ID found for $($pkg.Name), skipping..."
                }
            }
            'scoop' {
                Write-Host "Installing $($pkg.Name) via Scoop..."
                scoop install "$($pkg.Name)"
            }
            'chocolatey' {
                if ($pkg.ID) {
                    Write-Host "Installing $($pkg.Name) via Chocolatey (ID: $($pkg.ID))..."
                    choco install "$($pkg.ID)" -y
                } else {
                    Write-Warning "No ID found for $($pkg.Name), skipping..."
                }
            }
            default {
                Write-Warning "Unknown source for package $($pkg.Name)"
            }
        }
    }
}

# -------------------------------
# Main
# -------------------------------
if ($Export) {
    Export-PackagesToJson
} elseif ($Install) {
    Install-PackagesFromJson
} else {
    Write-Host "Specify -Export to export packages or -Install to install from JSON."
}
