[CmdletBinding()]
param(
  [string]$CodexHome = (Join-Path $env:USERPROFILE '.codex'),
  [switch]$RepairChromeCache,
  [switch]$VerifyOnly
)

$ErrorActionPreference = 'Stop'
$LogPrefix = '[codex-api-access-repair-plugin:persist]'

function Write-Log {
  param([string]$Message)
  Write-Host "$LogPrefix $Message"
}

function Write-Utf8NoBom {
  param(
    [string]$Path,
    [string]$Content
  )
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Path) | Out-Null
  [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
}

function Set-TomlTable {
  param(
    [string]$ConfigPath,
    [string]$Header,
    [hashtable]$Values
  )

  $content = ''
  if (Test-Path -LiteralPath $ConfigPath) {
    $content = [System.IO.File]::ReadAllText($ConfigPath, [System.Text.UTF8Encoding]::new($false))
  }

  $lines = foreach ($key in ($Values.Keys | Sort-Object)) {
    $value = $Values[$key]
    if ($value -is [bool]) {
      "$key = $($value.ToString().ToLowerInvariant())"
    } else {
      $escaped = [string]$value -replace "'", "''"
      "$key = '$escaped'"
    }
  }

  $body = ($lines -join "`r`n") + "`r`n"
  $pattern = "(?ms)^$([regex]::Escape($Header))\s*\r?\n(?:(?!^\[).)*"
  $replacement = "$Header`r`n$body"

  if ([regex]::IsMatch($content, $pattern)) {
    $content = [regex]::Replace($content, $pattern, $replacement, 1)
  } else {
    if ($content.Length -gt 0 -and -not $content.EndsWith("`n")) {
      $content += "`r`n"
    }
    if ($content.Length -gt 0 -and -not $content.EndsWith("`r`n`r`n")) {
      $content += "`r`n"
    }
    $content += $replacement
  }

  Write-Utf8NoBom $ConfigPath $content
}

function Copy-Tree {
  param(
    [string]$Source,
    [string]$Destination
  )
  if (-not (Test-Path -LiteralPath $Source -PathType Container)) {
    throw "missing source directory: $Source"
  }
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Destination) | Out-Null
  & robocopy.exe $Source $Destination /MIR /NFL /NDL /NJH /NJS /NP | Out-Null
  if ($LASTEXITCODE -gt 7) {
    throw "robocopy failed from $Source to $Destination with exit code $LASTEXITCODE"
  }
}

function Remove-ReparsePointOrDirectory {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    return
  }
  $item = Get-Item -LiteralPath $Path -Force
  if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
    [System.IO.Directory]::Delete($item.FullName)
  } else {
    Remove-Item -LiteralPath $item.FullName -Recurse -Force
  }
}

function Get-CodexCli {
  $candidates = @()
  $binRoot = Join-Path $env:LOCALAPPDATA 'OpenAI\Codex\bin'
  if (Test-Path -LiteralPath $binRoot) {
    $candidates += Get-ChildItem -LiteralPath $binRoot -Recurse -Filter 'codex.exe' -ErrorAction SilentlyContinue |
      Sort-Object LastWriteTime -Descending |
      Select-Object -ExpandProperty FullName
  }
  $repackRoot = Join-Path $env:USERPROFILE 'Downloads\codex-msix-repack'
  if (Test-Path -LiteralPath $repackRoot) {
    $candidates += Get-ChildItem -LiteralPath $repackRoot -Recurse -Filter 'codex.exe' -ErrorAction SilentlyContinue |
      Where-Object { $_.FullName -like '*\package\app\resources\codex.exe' } |
      Sort-Object LastWriteTime -Descending |
      Select-Object -ExpandProperty FullName
  }
  return $candidates | Select-Object -First 1
}

function Get-InstalledBundledMarketplaceRoot {
  $pkg = Get-AppxPackage -Name OpenAI.Codex -ErrorAction SilentlyContinue |
    Sort-Object Version -Descending |
    Select-Object -First 1
  if (-not $pkg) {
    return $null
  }

  $root = Join-Path $pkg.InstallLocation 'app\resources\plugins\openai-bundled'
  if (Test-Path -LiteralPath (Join-Path $root '.agents\plugins\marketplace.json') -PathType Leaf) {
    return $root
  }
  return $null
}

function Ensure-ComputerUseSource {
  param([string]$CodexHomeResolved)

  $candidateRoots = @(
    (Join-Path $CodexHomeResolved 'plugins\cache\openai-bundled-local\computer-use\latest'),
    (Join-Path $CodexHomeResolved 'plugins\cache\openai-bundled-local\computer-use\0.1.0-local'),
    (Join-Path $CodexHomeResolved 'plugins\cache\openai-bundled\computer-use\latest'),
    (Join-Path $CodexHomeResolved 'plugins\cache\openai-bundled\computer-use\0.1.0-local')
  )

  $source = $candidateRoots |
    Where-Object { Test-Path -LiteralPath (Join-Path $_ '.codex-plugin\plugin.json') -PathType Leaf } |
    Select-Object -First 1

  if ($source) {
    return $source
  }

  $installer = Join-Path $CodexHomeResolved 'skills\codex-api-access-repair-plugin\scripts\install-computer-use-local.ps1'
  if (Test-Path -LiteralPath $installer -PathType Leaf) {
    Write-Log 'running Computer Use local installer'
    powershell -NoProfile -ExecutionPolicy Bypass -File $installer | Out-Host
  }

  $source = $candidateRoots |
    Where-Object { Test-Path -LiteralPath (Join-Path $_ '.codex-plugin\plugin.json') -PathType Leaf } |
    Select-Object -First 1

  if (-not $source) {
    throw 'could not find or create a local computer-use plugin source'
  }
  return $source
}

function Ensure-PersistentMarketplace {
  $codexHomeResolved = (Resolve-Path -LiteralPath $CodexHome).Path
  $configPath = Join-Path $codexHomeResolved 'config.toml'
  $stableRoot = Join-Path $codexHomeResolved 'marketplaces\openai-bundled-local'
  $stableManifest = Join-Path $stableRoot '.agents\plugins\marketplace.json'
  $stableComputerUse = Join-Path $stableRoot 'plugins\computer-use'
  $cacheRoot = Join-Path $codexHomeResolved 'plugins\cache\openai-bundled-local\computer-use\0.1.0-local'
  $cacheLatest = Join-Path $codexHomeResolved 'plugins\cache\openai-bundled-local\computer-use\latest'

  New-Item -ItemType Directory -Force -Path $stableRoot | Out-Null

  $installedBundled = Get-InstalledBundledMarketplaceRoot
  if ($installedBundled) {
    Write-Log "syncing bundled marketplace source: $installedBundled"
    Copy-Tree $installedBundled $stableRoot
  }

  $computerUseSource = Ensure-ComputerUseSource $codexHomeResolved
  Copy-Tree $computerUseSource $stableComputerUse
  Copy-Tree $stableComputerUse $cacheRoot

  Remove-ReparsePointOrDirectory $cacheLatest
  New-Item -ItemType Junction -Path $cacheLatest -Target $cacheRoot | Out-Null

  if (Test-Path -LiteralPath $stableManifest -PathType Leaf) {
    $manifest = Get-Content -Raw -LiteralPath $stableManifest | ConvertFrom-Json
  } else {
    $manifest = [pscustomobject]@{
      name = 'openai-bundled-local'
      interface = [pscustomobject]@{ displayName = 'OpenAI Bundled Local' }
      plugins = @()
    }
  }

  $manifest.name = 'openai-bundled-local'
  if (-not $manifest.interface) {
    $manifest | Add-Member -NotePropertyName interface -NotePropertyValue ([pscustomobject]@{})
  }
  $manifest.interface.displayName = 'OpenAI Bundled Local'

  $entry = [pscustomobject]@{
    name = 'computer-use'
    source = [pscustomobject]@{
      source = 'local'
      path = './plugins/computer-use'
    }
    policy = [pscustomobject]@{
      installation = 'INSTALLED_BY_DEFAULT'
      authentication = 'ON_INSTALL'
    }
    category = 'Productivity'
  }

  $plugins = @($manifest.plugins | Where-Object { $_.name -ne 'computer-use' })
  $manifest.plugins = @($entry) + $plugins
  Write-Utf8NoBom $stableManifest (($manifest | ConvertTo-Json -Depth 30) + "`n")

  Set-TomlTable $configPath '[marketplaces.openai-bundled-local]' @{
    last_updated = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
    source = '\\?\' + $stableRoot
    source_type = 'local'
  }
  Set-TomlTable $configPath '[plugins."computer-use@openai-bundled-local"]' @{
    enabled = $true
  }
  Set-TomlTable $configPath '[features]' @{
    computer_use = $true
    goals = $true
    js_repl = $false
  }

  [Environment]::SetEnvironmentVariable('CODEX_ELECTRON_ENABLE_WINDOWS_COMPUTER_USE', '1', 'User')
  $env:CODEX_ELECTRON_ENABLE_WINDOWS_COMPUTER_USE = '1'

  $cli = Get-CodexCli
  if ($cli) {
    Write-Log "using CLI: $cli"
    $listing = & $cli plugin list 2>&1 | Out-String
    $listing | Select-String 'computer-use@openai-bundled-local' | Out-Host
    if ($LASTEXITCODE -eq 0 -and $listing -match 'computer-use@openai-bundled-local \(not installed\)') {
      & $cli plugin add computer-use@openai-bundled-local | Out-Host
    }
  } else {
    Write-Log 'warning: no usable Codex CLI found for plugin verification'
  }

  Write-Log "persisted marketplace: $stableManifest"
}

function Repair-ChromeCache {
  $chromeRoot = Join-Path $CodexHome 'plugins\cache\openai-bundled\chrome'
  $cacheRoot = Join-Path $CodexHome 'plugins\cache'
  $resolvedChrome = [System.IO.Path]::GetFullPath($chromeRoot)
  $resolvedCache = [System.IO.Path]::GetFullPath($cacheRoot).TrimEnd('\') + '\'
  if (-not $resolvedChrome.StartsWith($resolvedCache, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "refusing to modify path outside plugin cache: $resolvedChrome"
  }

  Get-Process -Name 'extension-host' -ErrorAction SilentlyContinue |
    Where-Object { $_.Path -and $_.Path.StartsWith($resolvedChrome, [System.StringComparison]::OrdinalIgnoreCase) } |
    ForEach-Object {
      Write-Log "stopping stale Chrome extension host pid=$($_.Id)"
      Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
    }

  Start-Sleep -Milliseconds 500
  Remove-ReparsePointOrDirectory $chromeRoot
  Write-Log "removed stale Chrome plugin cache: $chromeRoot"
}

function Verify-State {
  $cli = Get-CodexCli
  if (-not $cli) {
    Write-Log 'no usable Codex CLI found for verification'
    return
  }

  Write-Log 'feature flags:'
  & $cli features list | Select-String 'goals|computer_use|fast_mode|plugins' | Out-Host
  Write-Log 'plugins:'
  & $cli plugin list | Select-String 'openai-bundled-local|computer-use|chrome@openai-bundled|github@openai-curated|hugging-face@openai-curated' | Out-Host
}

New-Item -ItemType Directory -Force -Path $CodexHome | Out-Null

if ($RepairChromeCache) {
  Repair-ChromeCache
}

if (-not $VerifyOnly) {
  Ensure-PersistentMarketplace
}

Verify-State
