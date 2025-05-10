# Run as administrator (required for winget installs)
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process pwsh.exe "-NoProfile -File `"$($MyInvocation.MyCommand.Path)`"" -Verb RunAs
    exit
}

# ===== Apps to install via WINGET (most reliable) =====
$wingetApps = @(
    "Discord.Discord",          # Official Discord
    "OBSProject.OBSStudio",     # Official OBS Studio
    "RiotGames.RiotClient"      # Riot Client (includes League of Legends)
)

# ===== Apps to install via direct download (for game clients not in winget) =====
$directDownloadApps = @(
    @{
        Name = "Steam"
        URL = "https://cdn.akamai.steamstatic.com/client/installer/SteamSetup.exe"
        Installer = "SteamSetup.exe"
        Args = "/S"
    },
    @{
        Name = "Battle.Net"
        URL = "https://www.battle.net/download/getInstaller?os=win&installer=Battle.net-Setup.exe"
        Installer = "BattleNetSetup.exe"
        Args = "/S"
    },
    @{
        Name = "Epic Games Launcher"
        URL = "https://launcher-public-service-prod06.ol.epicgames.com/launcher/api/installer/download/EpicGamesLauncherInstaller.msi"
        Installer = "EpicInstaller.msi"
        Args = "/qn /norestart"
    },
    @{
        Name = "Ubisoft Connect"
        URL = "https://ubi.li/4vxt9"
        Installer = "UbisoftConnect.exe"
        Args = "/S"
    }
)

# ===== 1. INSTALL VIA WINGET =====
Write-Host "=== Installing apps via winget ===" -ForegroundColor Cyan
foreach ($app in $wingetApps) {
    try {
        Write-Host "Installing $app..."
        winget install --id $app --accept-package-agreements --accept-source-agreements --silent
        Write-Host "[SUCCESS] $app installed." -ForegroundColor Green
    }
    catch {
        Write-Host "[ERROR] Failed to install $app : $_" -ForegroundColor Red
    }
}

# ===== 2. INSTALL VIA DIRECT DOWNLOAD (fallback for non-winget apps) =====
$tempDir = "$env:TEMP\GameClients"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

Write-Host "`n=== Installing game clients via direct download ===" -ForegroundColor Cyan
foreach ($app in $directDownloadApps) {
    $installerPath = Join-Path -Path $tempDir -ChildPath $app.Installer
    
    try {
        # Download
        Write-Host "Downloading $($app.Name)..."
        Invoke-WebRequest -Uri $app.URL -OutFile $installerPath -UseBasicParsing -ErrorAction Stop

        # Install
        Write-Host "Installing $($app.Name)..."
        if ($app.Installer.EndsWith('.msi')) {
            Start-Process "msiexec.exe" -ArgumentList "/i `"$installerPath`" $($app.Args)" -Wait -NoNewWindow
        } else {
            Start-Process -FilePath $installerPath -ArgumentList $app.Args -Wait -NoNewWindow
        }
        
        Write-Host "[SUCCESS] $($app.Name) installed." -ForegroundColor Green
    }
    catch {
        Write-Host "[ERROR] Failed to install $($app.Name): $_" -ForegroundColor Red
    }
    finally {
        if (Test-Path $installerPath) { Remove-Item $installerPath -Force }
    }
}

# Cleanup
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "`n=== All installations completed! ===" -ForegroundColor Green
