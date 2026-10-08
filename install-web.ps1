# One-line installer for Windows:
#
#   iwr -useb https://raw.githubusercontent.com/am1dreaming/Flying-Island-dark-for-VS-code/main/install-web.ps1 | iex
#
# Downloads the repository (main branch) into a temp folder and runs install.ps1 from it.
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$Repo = "am1dreaming/Flying-Island-dark-for-VS-code"
$Zip = "https://github.com/$Repo/archive/refs/heads/main.zip"
$Tmp = Join-Path $env:TEMP ("flying-island-" + [guid]::NewGuid().ToString("N").Substring(0, 8))
New-Item -ItemType Directory -Force -Path $Tmp | Out-Null

try {
    Write-Host "==> Downloading Flying Island from github.com/$Repo"
    $ProgressPreference = "SilentlyContinue"   # Invoke-WebRequest is very slow with the progress bar
    Invoke-WebRequest -UseBasicParsing -Uri $Zip -OutFile (Join-Path $Tmp "src.zip")
    Expand-Archive -Path (Join-Path $Tmp "src.zip") -DestinationPath $Tmp -Force
    $Src = Get-ChildItem $Tmp -Directory | Where-Object { Test-Path (Join-Path $_.FullName "install.ps1") } | Select-Object -First 1
    if (-not $Src) { throw "install.ps1 not found in the downloaded archive" }

    # A child process: install.ps1 changes $ErrorActionPreference and may exit.
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Src.FullName "install.ps1")
    if ($LASTEXITCODE -ne 0) { throw "install.ps1 failed (exit code $LASTEXITCODE)" }
} finally {
    Remove-Item -Recurse -Force $Tmp -ErrorAction SilentlyContinue
}
