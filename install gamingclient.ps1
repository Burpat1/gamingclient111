# Save as `install_gaming_clients.ps1`
# Right-click → "Run with PowerShell" (or deploy via NTLite Post-Setup).

# Self-elevate to Admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process pwsh.exe "-NoProfile -File `"$($MyInvocation.MyCommand.Path)`"" -Verb RunAs
    exit
}

$tempDir = "$env:TEMP\GameClients"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

$apps = @(
    @{ 
        Name = "Discord"
        URL = "https://discord.com/api/downloads/distributions/app/installers/latest?platform=win&arch=x86"
        Installer = "DiscordSetup.exe"
        Args = "/S"
    },
    @{ 
        Name = "OBS Studio"
        URL = "https://cdn-fastly.obsproject.com/downloads/OBS-Studio-30.0.2-Full-x64.exe"
        Installer = "OBS-Studio.exe"
        Args = "/S"
    },
    @{ 
        Name = "Steam"
        URL = "https://cdn.akamai.steamstatic.com/client/installer/SteamSetup.exe"
        Installer = "SteamSetup.exe"
        Args = "/S"
    },
    @{ 
        Name = "Battle.Net"
        URL = "https://www.battle.net/download/getInstallerForGame?os=win&installer=Battle.net-Setup.exe"
        Installer = "BattleNetSetup.exe"
        Args = "/S"
    },
    @{ 
        Name = "Epic Games Launcher"
        URL = "https://launcher-public-service-prod06.ol.epicgames.com/launcher/api/installer/download/EpicGamesLauncherInstaller.msi"
        Installer = "EpicInstaller.msi"
        Args = "/qn"
    },
    @{ 
        Name = "Ubisoft Connect"
        URL = "https://ubi.li/4vxt9"
        Installer = "UbisoftConnect.exe"
        Args = "/S"
    },
    @{ 
        Name = "Riot Client"
        URL = "https://riotgamespatcher-a.akamaihd.net/releases/live/installer/deploy/Riot%20Client%20Installer.exe"
        Installer = "RiotClientInstaller.exe"
        Args = "--launch-product=league_of_legends --launch-patchline=live"
    }
)

foreach ($app in $apps) {
    Write-Host "=== Installing $($app.Name) ==="
    $installerPath = Join-Path -Path $tempDir -ChildPath $app.Installer
    
    try {
        # Download
        Invoke-WebRequest -Uri $app.URL -OutFile $installerPath -UserAgent "Wget" -ErrorAction Stop
        
        # Install
        Start-Process -FilePath $installerPath -ArgumentList $app.Args -Wait -NoNewWindow
        
        Write-Host "[SUCCESS] $($app.Name) installed." -ForegroundColor Green
    }
    catch {
        Write-Host "[ERROR] Failed to install $($app.Name): $_" -ForegroundColor Red
    }
}

# Cleanup
Remove-Item -Path $tempDir -Recurse -Force
Write-Host "=== All installations completed. ==="
Read-Host "Press Enter to exit..."