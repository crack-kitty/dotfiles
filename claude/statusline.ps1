$inputJson = [Console]::In.ReadToEnd()

try {
    $data = $inputJson | ConvertFrom-Json
    $model = "Claude"
    if ($data.model) {
        if ($data.model.PSObject.Properties["display_name"]) {
            $model = $data.model.display_name
        } else {
            $model = [string]$data.model
        }
    }

    $used = $null
    $remaining = $null
    if ($data.context_window) {
        $used = $data.context_window.used_percentage
        $remaining = $data.context_window.remaining_percentage
    }

    if ($null -eq $used -or $null -eq $remaining) {
        Write-Host -NoNewline $model
        exit 0
    }

    $usedInt = [int][Math]::Round([double]$used)
    $remainingInt = [int][Math]::Round([double]$remaining)
    $status = "$model | Context: $usedInt%"

    if ($remainingInt -le 5) {
        $status += " [CRITICAL: $remainingInt% remaining]"
    } elseif ($remainingInt -le 10) {
        $status += " [WARNING: $remainingInt% remaining]"
    }

    Write-Host -NoNewline $status
} catch {
    Write-Host -NoNewline "Claude"
}
