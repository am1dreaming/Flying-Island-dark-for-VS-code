# Installs Flying Island into VS Code on Windows. macOS: install.sh
#
#   powershell -ExecutionPolicy Bypass -File .\install.ps1
#
# Needs nothing but Windows PowerShell 5.1+ (no Python, no Node).
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem

$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$Utf8 = New-Object System.Text.UTF8Encoding $false

# ------------------------------------------------------------- VS Code CLI
$Code = (Get-Command code.cmd -ErrorAction SilentlyContinue).Source
foreach ($c in @("$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd",
                 "$env:ProgramFiles\Microsoft VS Code\bin\code.cmd")) {
    if (-not $Code -and (Test-Path $c)) { $Code = $c }
}
if (-not $Code) { throw "VS Code CLI (code.cmd) not found. Install VS Code (User Installer) first." }
$UserDir = Join-Path $env:APPDATA "Code\User"
$Pkg = Get-Content (Join-Path $Here "package.json") -Raw | ConvertFrom-Json
$ExtId = "$($Pkg.publisher).$($Pkg.name)"
$ExtDir = Join-Path $env:USERPROFILE ".vscode\extensions\$ExtId-$($Pkg.version)"
# The extension used to be published as "Islands Dark (CLion)".
$LegacyExtId = "yaroslav.islands-dark-clion"

# ------------------------------------------------------------------ fonts
Write-Host "==> Fonts (JetBrains Mono, Inter - SIL OFL) for the current user"
$FontDir = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
$FontReg = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
New-Item -ItemType Directory -Force -Path $FontDir | Out-Null
if (-not (Test-Path $FontReg)) { New-Item -Path $FontReg -Force | Out-Null }
foreach ($f in Get-ChildItem (Join-Path $Here "fonts") -File | Where-Object { $_.Extension -in ".ttf", ".otf" }) {
    $dst = Join-Path $FontDir $f.Name
    if (-not (Test-Path $dst)) { Copy-Item $f.FullName $dst }
    $kind = if ($f.Extension -eq ".otf") { "OpenType" } else { "TrueType" }
    Set-ItemProperty -Path $FontReg -Name "$($f.BaseName) ($kind)" -Value $dst
}

# ------------------------------------------------------------- pack .vsix
Write-Host "==> Flying Island extension"
$Dist = Join-Path $Here "dist"
New-Item -ItemType Directory -Force -Path $Dist | Out-Null
$Vsix = Join-Path $Dist "$($Pkg.name)-$($Pkg.version).vsix"
if (Test-Path $Vsix) { Remove-Item $Vsix }
$manifest = @"
<?xml version="1.0" encoding="utf-8"?>
<PackageManifest Version="2.0.0" xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011">
  <Metadata>
    <Identity Language="en-US" Id="$($Pkg.name)" Version="$($Pkg.version)" Publisher="$($Pkg.publisher)"/>
    <DisplayName>$($Pkg.displayName)</DisplayName>
    <Description xml:space="preserve">$($Pkg.description)</Description>
    <Categories>Themes</Categories>
    <Properties><Property Id="Microsoft.VisualStudio.Code.Engine" Value="$($Pkg.engines.vscode)"/></Properties>
  </Metadata>
  <Installation><InstallationTarget Id="Microsoft.VisualStudio.Code"/></Installation>
  <Dependencies/>
  <Assets><Asset Type="Microsoft.VisualStudio.Code.Manifest" Path="extension/package.json" Addressable="true"/></Assets>
</PackageManifest>
"@
$types = @"
<?xml version="1.0" encoding="utf-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension=".json" ContentType="application/json"/>
  <Default Extension=".js" ContentType="application/javascript"/>
  <Default Extension=".css" ContentType="text/css"/>
  <Default Extension=".vsixmanifest" ContentType="text/xml"/>
  <Default Extension=".txt" ContentType="text/plain"/>
</Types>
"@
$Payload = @{
    "extension/package.json"      = "package.json"
    "extension/extension.js"      = "extension.js"
    "extension/css/islands.css"   = "css\islands.css"
    "extension/css/vibrancy.css"  = "css\vibrancy.css"
    "extension/LICENSE.txt"       = "LICENSE"
    "extension/NOTICE.txt"        = "NOTICE"
    "extension/licenses/Apache-2.0.txt" = "licenses\Apache-2.0.txt"
}
foreach ($t in Get-ChildItem (Join-Path $Here "themes") -Filter *.json) {
    $Payload["extension/themes/$($t.Name)"] = "themes\$($t.Name)"
}
$zip = [System.IO.Compression.ZipFile]::Open($Vsix, "Create")
try {
    foreach ($pair in @(@("extension.vsixmanifest", $manifest), @("[Content_Types].xml", $types))) {
        $w = New-Object System.IO.StreamWriter($zip.CreateEntry($pair[0]).Open(), $Utf8)
        $w.Write($pair[1]); $w.Dispose()
    }
    foreach ($entry in $Payload.Keys) {
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, (Join-Path $Here $Payload[$entry]), $entry) | Out-Null
    }
} finally { $zip.Dispose() }

# Every VS Code profile has its own extensions + settings: install into all.
$Profiles = @("")
$storage = Join-Path $UserDir "globalStorage\storage.json"
if (Test-Path $storage) {
    $s = Get-Content $storage -Raw | ConvertFrom-Json
    foreach ($p in @($s.userDataProfiles)) { if ($p.name) { $Profiles += $p.name } }
}
foreach ($prof in $Profiles) {
    Write-Host "   profile: $(if ($prof) { $prof } else { 'Default' })"
    $profArgs = if ($prof) { @("--profile", $prof) } else { @() }
    # PS 5.1 + "Stop" turns any native stderr (e.g. Node deprecation warnings) into a fatal error.
    $ErrorActionPreference = "Continue"
    & $Code @profArgs --uninstall-extension $LegacyExtId *> $null   # fine if it was never installed
    $ErrorActionPreference = "Stop"
    foreach ($ext in @($Vsix, "llvm-vs-code-extensions.vscode-clangd", "chadalen.vscode-jetbrains-icon-theme")) {
        # PS 5.1 + "Stop" turns any native stderr (e.g. Node deprecation warnings) into a fatal error.
        $ErrorActionPreference = "Continue"
        & $Code @profArgs --install-extension $ext --force *> $null
        $ErrorActionPreference = "Stop"
        if ($LASTEXITCODE -ne 0) { Write-Host "     ! $ext (close VS Code and re-run)" }
    }
}
# Sync files in place too (CLI refuses to reinstall while VS Code is running).
New-Item -ItemType Directory -Force -Path (Join-Path $ExtDir "css"), (Join-Path $ExtDir "themes"), (Join-Path $ExtDir "licenses") | Out-Null
foreach ($entry in $Payload.Keys) {
    Copy-Item (Join-Path $Here $Payload[$entry]) (Join-Path $ExtDir ($entry -replace '^extension/', '' -replace '/', '\')) -Force
}

# ---------------------------------------------------------------- settings
function Remove-JsonComments([string]$t) {
    $sb = New-Object System.Text.StringBuilder
    $i = 0; $n = $t.Length; $inStr = $false
    while ($i -lt $n) {
        $c = $t[$i]
        if ($inStr) {
            [void]$sb.Append($c)
            if ($c -eq '\') { [void]$sb.Append($t[$i + 1]); $i++ }
            elseif ($c -eq '"') { $inStr = $false }
        } elseif ($c -eq '"') { $inStr = $true; [void]$sb.Append($c) }
        elseif ($c -eq '/' -and $i + 1 -lt $n -and $t[$i + 1] -eq '/') {
            while ($i -lt $n -and $t[$i] -ne "`n") { $i++ }; continue
        } elseif ($c -eq '/' -and $i + 1 -lt $n -and $t[$i + 1] -eq '*') {
            $i = $t.IndexOf("*/", $i) + 2; continue
        } else { [void]$sb.Append($c) }
        $i++
    }
    return [regex]::Replace($sb.ToString(), ',(\s*[}\]])', '$1')
}

Write-Host "==> Merging settings into every profile (backup: settings.json.bak-islands)"
$new = Remove-JsonComments (Get-Content (Join-Path $Here "settings\settings.jsonc") -Raw) | ConvertFrom-Json
$files = @(Join-Path $UserDir "settings.json")
if (Test-Path (Join-Path $UserDir "profiles")) {
    $files += Get-ChildItem (Join-Path $UserDir "profiles") -Directory |
        ForEach-Object { Join-Path $_.FullName "settings.json" } | Where-Object { Test-Path $_ }
}
foreach ($f in $files) {
    $cur = New-Object PSObject
    if (Test-Path $f) {
        if (-not (Test-Path "$f.bak-islands")) { Copy-Item $f "$f.bak-islands" }
        $raw = Get-Content $f -Raw
        if ($raw -and $raw.Trim()) { $cur = Remove-JsonComments $raw | ConvertFrom-Json }
    } else {
        New-Item -ItemType Directory -Force -Path (Split-Path $f) | Out-Null
    }
    # drop keys of the pre-rename extension ("islandsDark.*")
    foreach ($old in @($cur.PSObject.Properties | Where-Object { $_.Name -like "islandsDark.*" })) {
        $cur.PSObject.Properties.Remove($old.Name)
    }
    foreach ($p in $new.PSObject.Properties) {
        $cur | Add-Member -NotePropertyName $p.Name -NotePropertyValue $p.Value -Force
    }
    [System.IO.File]::WriteAllText($f, ($cur | ConvertTo-Json -Depth 32), $Utf8)
    Write-Host "   merged $(@($new.PSObject.Properties).Count) keys -> $($f.Substring($UserDir.Length + 1))"
}

Write-Host ""
Write-Host "Done. Close VS Code completely, reopen it, click 'Reload Window' in the Flying Island popup."
Write-Host "If Windows 11: the next popup asks to quit once more to turn on the acrylic glass."
Write-Host "Undo: run 'Flying Island: Remove All Patches' in VS Code, restore settings.json.bak-islands, then"
Write-Host "      code --uninstall-extension $ExtId"
