# Windows Package Backup

A PowerShell utility to **backup and restore installed packages** on Windows from multiple package managers: **Winget**, **Scoop**, and **Chocolatey**.  

This tool exports all installed packages to a JSON file and can later reinstall them automatically.  

---

## Features

- Export all installed packages to a JSON file (`./exports/packages.json`)  
- Works with **Winget**, **Scoop**, and **Chocolatey**  
- Reinstall all packages from the JSON file  
- Uses **package IDs** for reliable reinstallation  
- Organized export folder for easy backups  

---

## Requirements

- Windows 10 or 11  
- PowerShell 7+ recommended  
- At least one of the package managers installed:
  - [Winget](https://learn.microsoft.com/en-us/windows/package-manager/winget/)
  - [Scoop](https://scoop.sh/)
  - [Chocolatey](https://chocolatey.org/)  

---

## Usage

### Export installed packages

```powershell
.\package-backup.ps1 -Export
```
This will create a JSON file with all installed packages in ./exports/packages.json.

Install packages from JSON

```powershell
.\package-backup.ps1 -Install
```
This will read the JSON file and reinstall all packages using the appropriate package manager.


### Folder Structure
```
windows-package-backup/
├─ exports/
├─ package-backup.ps1
├─ README.md
└─ LICENSE
```

## Notes

  -  Scoop uses package names instead of IDs, so ensure the names are correct.
  -  Winget and Chocolatey use package IDs to avoid mismatches during reinstall.
  -  The script will skip any package if its ID is missing.