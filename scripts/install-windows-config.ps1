param(
    [Parameter(Mandatory = $true)]
    [string]$RepoRoot
)

$ErrorActionPreference = "Stop"

function Copy-RepoFile {
    param(
        [string]$Source,
        [string]$Destination
    )

    $parent = Split-Path -Parent $Destination
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    Copy-Item -LiteralPath $Source -Destination $Destination -Force
}

function Set-RepoJunction {
    param(
        [string]$Source,
        [string]$Destination
    )

    if (Test-Path $Destination) {
        $item = Get-Item -LiteralPath $Destination -Force
        if ($item.LinkType -eq "Junction" -or $item.LinkType -eq "SymbolicLink") {
            [System.IO.Directory]::Delete($Destination)
        } elseif ($item.PSIsContainer) {
            $backupRoot = Join-Path ([Environment]::GetFolderPath("UserProfile")) ".dotfiles-windows-backup"
            $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
            $backupDir = Join-Path $backupRoot $stamp
            New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
            Move-Item -LiteralPath $Destination -Destination (Join-Path $backupDir (Split-Path -Leaf $Destination))
        } else {
            Remove-Item -LiteralPath $Destination -Force
        }
    }

    New-Item -ItemType Junction -Path $Destination -Target $Source | Out-Null
}

function Merge-JsonObject {
    param($Target, $Source)

    foreach ($property in $Source.PSObject.Properties) {
        $name = $property.Name
        $value = $property.Value
        $existing = $Target.PSObject.Properties[$name]

        if ($existing -and $existing.Value -is [pscustomobject] -and $value -is [pscustomobject]) {
            Merge-JsonObject -Target $existing.Value -Source $value
        } elseif ($existing) {
            $existing.Value = $value
        } else {
            $Target | Add-Member -NotePropertyName $name -NotePropertyValue $value
        }
    }
}

function Set-TopLevelTomlValue {
    param(
        [string[]]$Lines,
        [string]$Key,
        [string]$Value
    )

    $pattern = "^\s*$([regex]::Escape($Key))\s*="
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^\s*\[') {
            break
        }
        if ($Lines[$i] -match $pattern) {
            $Lines[$i] = "$Key = $Value"
            return $Lines
        }
    }

    return @("$Key = $Value") + $Lines
}

function Set-TomlTableValue {
    param(
        [string[]]$Lines,
        [string]$Table,
        [string]$Key,
        [string]$Value
    )

    $header = "[$Table]"
    $headerPattern = "^\s*\[$([regex]::Escape($Table))\]\s*$"
    $keyPattern = "^\s*$([regex]::Escape($Key))\s*="

    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -notmatch $headerPattern) {
            continue
        }

        $insertAt = $i + 1
        for ($j = $i + 1; $j -lt $Lines.Count; $j++) {
            if ($Lines[$j] -match '^\s*\[') {
                break
            }
            if ($Lines[$j] -match $keyPattern) {
                $Lines[$j] = "$Key = $Value"
                return $Lines
            }
            $insertAt = $j + 1
        }

        $before = if ($insertAt -gt 0) { $Lines[0..($insertAt - 1)] } else { @() }
        $after = if ($insertAt -lt $Lines.Count) { $Lines[$insertAt..($Lines.Count - 1)] } else { @() }
        return @($before) + @("$Key = $Value") + @($after)
    }

    return @($Lines) + @("", $header, "$Key = $Value")
}

function Set-TomlTableMultilineValue {
    param(
        [string[]]$Lines,
        [string]$Table,
        [string]$Key,
        [string[]]$ValueLines
    )

    $header = "[$Table]"
    $headerPattern = "^\s*\[$([regex]::Escape($Table))\]\s*$"
    $keyPattern = "^\s*$([regex]::Escape($Key))\s*="
    if ($ValueLines.Count -eq 0) {
        throw "ValueLines must contain at least one line."
    }

    $replacement = @("$Key = $($ValueLines[0])")
    if ($ValueLines.Count -gt 1) {
        $replacement += $ValueLines[1..($ValueLines.Count - 1)]
    }

    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -notmatch $headerPattern) {
            continue
        }

        $insertAt = $i + 1
        for ($j = $i + 1; $j -lt $Lines.Count; $j++) {
            if ($Lines[$j] -match '^\s*\[') {
                break
            }

            if ($Lines[$j] -match $keyPattern) {
                $end = $j
                if ($Lines[$j] -match '=\s*\[' -and $Lines[$j] -notmatch '\]\s*(#.*)?$') {
                    for ($k = $j + 1; $k -lt $Lines.Count; $k++) {
                        $end = $k
                        if ($Lines[$k] -match '^\s*\]' -or $Lines[$k] -match '\]\s*(#.*)?$') {
                            break
                        }
                    }
                }

                $before = if ($j -gt 0) { $Lines[0..($j - 1)] } else { @() }
                $after = if ($end + 1 -lt $Lines.Count) { $Lines[($end + 1)..($Lines.Count - 1)] } else { @() }
                return @($before) + $replacement + @($after)
            }

            $insertAt = $j + 1
        }

        $before = if ($insertAt -gt 0) { $Lines[0..($insertAt - 1)] } else { @() }
        $after = if ($insertAt -lt $Lines.Count) { $Lines[$insertAt..($Lines.Count - 1)] } else { @() }
        return @($before) + $replacement + @($after)
    }

    return @($Lines) + @("", $header) + $replacement
}

$homeDir = [Environment]::GetFolderPath("UserProfile")

$codexDir = Join-Path $homeDir ".codex"
$claudeDir = Join-Path $homeDir ".claude"
New-Item -ItemType Directory -Force -Path $claudeDir | Out-Null
New-Item -ItemType Directory -Force -Path $codexDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $codexDir "agents") | Out-Null

Copy-RepoFile -Source (Join-Path $RepoRoot ".gitconfig") -Destination (Join-Path $homeDir ".gitconfig")
Copy-RepoFile -Source (Join-Path $RepoRoot ".gitignore") -Destination (Join-Path $homeDir ".gitignore")

Copy-RepoFile -Source (Join-Path $RepoRoot "claude\CLAUDE.md") -Destination (Join-Path $claudeDir "CLAUDE.md")
Copy-RepoFile -Source (Join-Path $RepoRoot "claude\CHANGELOG.md") -Destination (Join-Path $claudeDir "CHANGELOG.md")
Copy-RepoFile -Source (Join-Path $RepoRoot "claude\statusline.sh") -Destination (Join-Path $claudeDir "statusline.sh")
Copy-RepoFile -Source (Join-Path $RepoRoot "claude\statusline-command.sh") -Destination (Join-Path $claudeDir "statusline-command.sh")
Copy-RepoFile -Source (Join-Path $RepoRoot "claude\statusline.ps1") -Destination (Join-Path $claudeDir "statusline.ps1")
Set-RepoJunction -Source (Join-Path $RepoRoot "claude\agents") -Destination (Join-Path $claudeDir "agents")
Set-RepoJunction -Source (Join-Path $RepoRoot "claude\hooks") -Destination (Join-Path $claudeDir "hooks")
Set-RepoJunction -Source (Join-Path $RepoRoot "claude\skills") -Destination (Join-Path $claudeDir "skills")

Copy-RepoFile -Source (Join-Path $RepoRoot "codex\AGENTS.md") -Destination (Join-Path $codexDir "AGENTS.md")
Copy-RepoFile -Source (Join-Path $RepoRoot "codex\triage.config.toml") -Destination (Join-Path $codexDir "triage.config.toml")
Copy-RepoFile -Source (Join-Path $RepoRoot "codex\deep-work.config.toml") -Destination (Join-Path $codexDir "deep-work.config.toml")
Copy-RepoFile -Source (Join-Path $RepoRoot "codex\codex-auto") -Destination (Join-Path $codexDir "codex-auto")
Copy-RepoFile -Source (Join-Path $RepoRoot "codex\agents\cheap-worker.toml") -Destination (Join-Path $codexDir "agents\cheap-worker.toml")

$claudeSettingsPath = Join-Path $claudeDir "settings.json"
$windowsSettingsPath = Join-Path $RepoRoot "claude\settings.windows.json"

if (Test-Path $claudeSettingsPath) {
    $claudeSettings = Get-Content -Raw $claudeSettingsPath | ConvertFrom-Json
} else {
    $claudeSettings = [pscustomobject]@{}
}
$windowsSettings = Get-Content -Raw $windowsSettingsPath | ConvertFrom-Json
Merge-JsonObject -Target $claudeSettings -Source $windowsSettings
$claudeSettings | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $claudeSettingsPath -Encoding utf8

$codexConfigPath = Join-Path $codexDir "config.toml"

if (Test-Path $codexConfigPath) {
    $lines = [string[]](Get-Content -LiteralPath $codexConfigPath)
} else {
    $lines = [string[]]@()
}

$lines = Set-TopLevelTomlValue -Lines $lines -Key "model" -Value '"gpt-5.5"'
$lines = Set-TopLevelTomlValue -Lines $lines -Key "model_reasoning_effort" -Value '"high"'
$lines = Set-TopLevelTomlValue -Lines $lines -Key "plan_mode_reasoning_effort" -Value '"high"'
$lines = Set-TomlTableValue -Lines $lines -Table "features" -Key "multi_agent" -Value "true"
$lines = Set-TomlTableValue -Lines $lines -Table 'plugins."google-drive@openai-curated"' -Key "enabled" -Value "true"
$lines = Set-TomlTableValue -Lines $lines -Table 'plugins."github@openai-curated"' -Key "enabled" -Value "true"
$lines = Set-TomlTableValue -Lines $lines -Table 'plugins."superpowers@openai-curated"' -Key "enabled" -Value "true"
$lines = Set-TomlTableValue -Lines $lines -Table "mcp_servers.n8n" -Key "url" -Value '"https://n8n-mcp.ckcompute.xyz/mcp"'
$lines = Set-TomlTableValue -Lines $lines -Table "mcp_servers.n8n" -Key "bearer_token_env_var" -Value '"N8N_MCP_TOKEN"'
$lines = Set-TomlTableValue -Lines $lines -Table "mcp_servers.homeassistant" -Key "url" -Value '"http://192.168.22.50:8123/api/mcp"'
$lines = Set-TomlTableValue -Lines $lines -Table "mcp_servers.homeassistant" -Key "bearer_token_env_var" -Value '"HOMEASSISTANT_TOKEN"'
$lines = Set-TomlTableMultilineValue -Lines $lines -Table "tui" -Key "status_line" -ValueLines @(
    "[",
    '  "model-with-reasoning",',
    '  "current-dir",',
    '  "git-branch",',
    '  "context-used",',
    "]"
)

$lines | Set-Content -LiteralPath $codexConfigPath -Encoding utf8

if (Get-Command claude -ErrorAction SilentlyContinue) {
    $marketplaces = claude plugin marketplace list 2>$null
    if ($marketplaces -notmatch "openai-codex") {
        claude plugin marketplace add openai/codex-plugin-cc
    }

    $plugins = claude plugin list 2>$null
    foreach ($plugin in @(
        "frontend-design@claude-plugins-official",
        "codex@openai-codex",
        "code-review@claude-plugins-official",
        "superpowers@claude-plugins-official"
    )) {
        if ($plugins -notmatch [regex]::Escape($plugin)) {
            claude plugin install $plugin
        }
    }
}
