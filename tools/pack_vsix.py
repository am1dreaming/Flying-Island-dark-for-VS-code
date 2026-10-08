#!/usr/bin/env python3
"""Packs the extension into dist/<name>-<version>.vsix without node/vsce."""
import json, zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
pkg = json.loads((ROOT / "package.json").read_text())
ident = f'{pkg["publisher"]}.{pkg["name"]}'
out = ROOT / "dist" / f'{pkg["name"]}-{pkg["version"]}.vsix'
out.parent.mkdir(exist_ok=True)

manifest = f"""<?xml version="1.0" encoding="utf-8"?>
<PackageManifest Version="2.0.0" xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011">
  <Metadata>
    <Identity Language="en-US" Id="{pkg["name"]}" Version="{pkg["version"]}" Publisher="{pkg["publisher"]}"/>
    <DisplayName>{pkg["displayName"]}</DisplayName>
    <Description xml:space="preserve">{pkg["description"]}</Description>
    <Categories>Themes</Categories>
    <Properties>
      <Property Id="Microsoft.VisualStudio.Code.Engine" Value="{pkg["engines"]["vscode"]}"/>
    </Properties>
  </Metadata>
  <Installation><InstallationTarget Id="Microsoft.VisualStudio.Code"/></Installation>
  <Dependencies/>
  <Assets>
    <Asset Type="Microsoft.VisualStudio.Code.Manifest" Path="extension/package.json" Addressable="true"/>
  </Assets>
</PackageManifest>
"""
types = """<?xml version="1.0" encoding="utf-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension=".json" ContentType="application/json"/>
  <Default Extension=".js" ContentType="application/javascript"/>
  <Default Extension=".css" ContentType="text/css"/>
  <Default Extension=".vsixmanifest" ContentType="text/xml"/>
  <Default Extension=".txt" ContentType="text/plain"/>
</Types>
"""
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    z.writestr("extension.vsixmanifest", manifest)
    z.writestr("[Content_Types].xml", types)
    z.write(ROOT / "package.json", "extension/package.json")
    z.write(ROOT / "extension.js", "extension/extension.js")
    z.write(ROOT / "css" / "islands.css", "extension/css/islands.css")
    z.write(ROOT / "css" / "vibrancy.css", "extension/css/vibrancy.css")
    z.write(ROOT / "LICENSE", "extension/LICENSE.txt")
    z.write(ROOT / "NOTICE", "extension/NOTICE.txt")
    z.write(ROOT / "licenses" / "Apache-2.0.txt", "extension/licenses/Apache-2.0.txt")
    for f in sorted((ROOT / "themes").glob("*.json")):
        z.write(f, f"extension/themes/{f.name}")
print(out.relative_to(ROOT), "->", ident)
