# === CONFIG ===
$HistoryFile = "$env:USERPROFILE\clipboard_history.txt"
$HtmlFile    = "$env:USERPROFILE\clipboard_history.html"
$PollIntervalMs = 500

# Ensure history file exists
if (!(Test-Path $HistoryFile)) {
    New-Item -Path $HistoryFile -ItemType File | Out-Null
}

function Convert-ToHtmlSafe {
    param([string]$Text)
    if ($null -eq $Text) { return "" }
    $t = $Text -replace '&', '&amp;'
    $t = $t -replace '<', '&lt;'
    $t = $t -replace '>', '&gt;'
    return $t
}

function Update-Html {
    param($HistoryFilePath, $HtmlFilePath)

    $lines = @()
    if (Test-Path $HistoryFilePath) {
        $lines = Get-Content $HistoryFilePath
    }

    $items = $lines | ForEach-Object {
        "<div class='item'>" + (Convert-ToHtmlSafe $_) + "</div>"
    }

    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <meta http-equiv="refresh" content="2" />
    <title>Craft-Matic's Fantastic Clipboard Tool</title>
    <style>
        body {
            font-family: Segoe UI, Arial, sans-serif;
            background-color: #111;
            color: #eee;
            padding: 10px 16px;
        }
        .title {
            font-size: 32px;
            font-weight: 700;
            text-align: center;
            margin: 10px 0 20px 0;
            letter-spacing: 1px;
            color: #ffcc33;
            text-shadow: 0 0 8px rgba(255, 204, 51, 0.6);
        }
        .subtitle {
            text-align: center;
            margin-bottom: 20px;
            color: #aaa;
            font-size: 13px;
        }
        .item {
            margin-bottom: 6px;
            padding-bottom: 4px;
            border-bottom: 1px solid #333;
            white-space: pre-wrap;
        }
    </style>
</head>
<body>
    <div class="title">Craft-Matic's Fantastic Clipboard Tool</div>
    <div class="subtitle">Live clipboard history &mdash; leave this page open while you work - The answer is 42</div>
    $($items -join "`n")
</body>
</html>
"@

    Set-Content -Path $HtmlFilePath -Value $html -Encoding UTF8
}

Write-Host "Clipboard HTML logger running. Close PowerShell to stop."
Write-Host "History file: $HistoryFile"
Write-Host "HTML file:    $HtmlFile"
Write-Host ""

# Initial HTML block
Update-Html -HistoryFilePath $HistoryFile -HtmlFilePath $HtmlFile

# Open in default browser
Start-Process $HtmlFile

$last = ""

try {
    while ($true) {
        try {
            $current = Get-Clipboard -Raw
        } catch {
            $current = ""
        }

        if ($current -and $current -ne $last) {
            $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            $entry = "[$timestamp] $current"

            Add-Content -Path $HistoryFile -Value $entry
            Write-Host $entry

            Update-Html -HistoryFilePath $HistoryFile -HtmlFilePath $HtmlFile

            $last = $current
        }

        Start-Sleep -Milliseconds $PollIntervalMs
    }
}
finally {
    Write-Host "`nStopping… cleaning up history file."

    if (Test-Path $HistoryFile) {
        Remove-Item $HistoryFile -Force
        Write-Host "Deleted: $HistoryFile"
    }

    if (Test-Path $HtmlFile) {
        Remove-Item $HtmlFile -Force
        Write-Host "Deleted: $HtmlFile"
    }
}
