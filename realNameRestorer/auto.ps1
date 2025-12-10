$ErrorActionPreference = "SilentlyContinue"
$scriptPath = $PSScriptRoot
$sourceFile = Join-Path $scriptPath "characters.json"
$cacheFile = Join-Path $scriptPath ".gameLoc"
$remoteFile = "https://raw.githubusercontent.com/renshengongji/PureBadminton_Mods/refs/heads/main/realNameRestorer/characters.json"

if (-not (Test-Path $sourceFile)) {
    Write-Host "Attempting to download 'characters.json' from GitHub" -ForegroundColor Cyan

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $remoteFile -OutFile $sourceFile -UseBasicParsing
        
        if (Test-Path $sourceFile) {
            Write-Host "Download successful" -ForegroundColor Green
        } else {
            throw "Download failed silently"
        }
    } catch {
        Write-Host "Error: Failed to download 'characters.json'." -ForegroundColor Red
        Write-Host "$($_.Exception.Message)" -ForegroundColor Red
        Read-Host "Press Enter to exit..."
        exit
    }
}

$selectedGame = $null
if (Test-Path $cacheFile) {
    $cachedPath = Get-Content $cacheFile -ErrorAction SilentlyContinue
    if (-not [string]::IsNullOrWhiteSpace($cachedPath) -and (Test-Path $cachedPath)) {
        if (Test-Path (Join-Path $cachedPath "Pure Badminton_Data")) {
            Write-Host "Found cached game path: $cachedPath" -ForegroundColor Cyan
            $response = Read-Host "Do you want to install to this location? (Y/n)"
            if ($response -eq "" -or $response -match "^[Yy]") {
                $selectedGame = Get-Item $cachedPath
            }
        }
    }
} 
if (-not $selectedGame) {
    Write-Host "Enter a start path (e.g., D:\Games) to search game" -ForegroundColor Yellow
    Write-Host "or empty to global serach (slow)"
    $userPath = Read-Host "Start Path"
    $roots = @()
    if ([string]::IsNullOrWhiteSpace($userPath)) {
        $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -gt 0 }
        $roots = $drives.Root
        Write-Host "Starting Global Search" -ForegroundColor Cyan
    } else {
        if (Test-Path $userPath) {
            $roots = @($userPath)
            Write-Host "Searching: $userPath" -ForegroundColor Cyan
        } else {
            Write-Host "Error: The path not exist." -ForegroundColor Red
            Read-Host "Press Enter to exit..."
            exit
        }
    }

    $games = @()
    foreach ($root in $roots) {
        $itemsToScan = Get-ChildItem -Path $root -Directory -ErrorAction SilentlyContinue
        
        $total = $itemsToScan.Count
        $current = 0
        foreach ($dir in $itemsToScan) {
            $current++
            Write-Progress -Activity "Searching..." -Status "Scanning: $($dir.FullName)" -PercentComplete (($current / $total) * 100)

            if ($dir.Name -match "^(Windows|ProgramData|\`$Recycle\.Bin|System Volume Information)$") {
                continue
            }

            $candidates = Get-ChildItem -Path $dir.FullName -Recurse -Directory -Filter "Pure Badminton*" -ErrorAction SilentlyContinue
            foreach ($candidate in $candidates) {
                if ($candidate.Name -match "^Pure Badminton.*") {
                    $checkPath = Join-Path $candidate.FullName "Pure Badminton_Data"
                    if (Test-Path $checkPath) {
                        $games += $candidate
                    }
                }
            }
        }
    }
    Write-Progress -Activity "Searching..." -Completed

    if ($games.Count -eq 0) {
        Write-Host "Error: No valid game folder found" -ForegroundColor Red
        Read-Host "Press Enter to exit..."
        exit
    }
    elseif ($games.Count -eq 1) {
        $selectedGame = $games[0]
        Write-Host "Found game: $($selectedGame.FullName)" -ForegroundColor Green
    }
    else {
        Write-Host "Found games:" -ForegroundColor Yellow
        for ($i = 0; $i -lt $games.Count; $i++) {
            Write-Host "[$($i+1)] $($games[$i].FullName)"
        }
        
        while ($true) {
            $selection = Read-Host "Enter index (1-$($games.Count))"
            if ($selection -match "^\d+$" -and [int]$selection -ge 1 -and [int]$selection -le $games.Count) {
                $selectedGame = $games[[int]$selection - 1]
                break
            }
            Write-Host "Invalid input" -ForegroundColor Red
        }
    }

    try {
        $selectedGame.FullName | Out-File $cacheFile -Encoding utf8 -Force
    } catch {
        Write-Host "Warning: Could not save cache file." -ForegroundColor DarkGray
    }
}

$gameDir = Join-Path $selectedGame.FullName "Pure Badminton_Data"
$modsDir = Join-Path $gameDir "mods"

if (-not (Test-Path $modsDir)) {
    New-Item -ItemType Directory -Path $modsDir -Force | Out-Null
    Write-Host "Created 'mods' directory." -ForegroundColor Gray
}

Copy-Item -Path $sourceFile -Destination $modsDir -Force

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Installation Successful!" -ForegroundColor Green
Write-Host "File copied to: $modsDir" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Green

Read-Host "Press Enter to exit..."