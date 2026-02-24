# VUI.ps1
# Windows標準の音声認識を使った音声コマンドランチャー
# 使い方: powershell -ExecutionPolicy Bypass -File VCL.ps1
param(
    [double]$Confidence = 0.5,  # 信頼度の閾値 (0.0-1.0)
    [string]$JsonPath = ".vcl.json"  # カスタムコマンド定義
)
Add-Type -AssemblyName System.Speech

# ============================================================
# コマンド定義 ("起動フレーズ" = "実行コマンド")
# ============================================================
$commands = [ordered]@{
    "こんにちは" = "echo 'こんにちは'"
    "依頼を書く" = "[EXE]C:\Program Files (x86)\sakura\sakura.exe[ARG]ask.md"
    "参考文献" = "bash -c 'source ~/.local/bin/obsi.sh'"
}
if ($JsonPath -and (Test-Path $JsonPath)) {
    try {
        $json = Get-Content $JsonPath -Raw | ConvertFrom-Json
        foreach ($p in $json.PSObject.Properties) {
            $commands[$p.Name] = $p.Value
        }
    }
    catch {
        # JSON を読み込めない場合は無視
    }
}
$exitPhrase = "終わり"
$commands[$exitPhrase] = "__EXIT__"

# ============================================================
# 認識エンジン初期化
# ============================================================
$recognizer = New-Object System.Speech.Recognition.SpeechRecognitionEngine
try {
    $recognizer.SetInputToDefaultAudioDevice()
} catch {
    Write-Host "[エラー] マイクが見つかりません。" -ForegroundColor Red
    exit 1
}

# 認識対象フレーズを登録
$choices = New-Object System.Speech.Recognition.Choices
$commands.Keys | ForEach-Object { $choices.Add($_) }
$builder = New-Object System.Speech.Recognition.GrammarBuilder
$builder.Culture = [System.Globalization.CultureInfo]::new("ja-JP")
$builder.Append($choices)
$grammar = New-Object System.Speech.Recognition.Grammar($builder)
$recognizer.LoadGrammar($grammar)

# ============================================================
# メインループ
# ============================================================
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Voice Command Launcher" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "設定:" -ForegroundColor Yellow
Write-Host "  信頼度閾値: $Confidence"
Write-Host ""
Write-Host "登録コマンド:" -ForegroundColor Yellow
foreach ($key in $commands.Keys) {
    $val = $commands[$key]
    if ($val -ne "__EXIT__") {
        Write-Host "  '$key' -> $val"
    }
}
Write-Host ""
$waitMsg = "音声を待機中... (Ctrl+C または '$exitPhrase' で音声認識終了)"
Write-Host $waitMsg -ForegroundColor Green
Write-Host ""
try {
    while ($true) {
        # 音声を待機 (3 秒ごとタイムアウトは Ctrl+C で終了できるようにするため)
        $result = $recognizer.Recognize([System.TimeSpan]::FromSeconds(3))
        if (-not $result) {
            continue
        }

        $text = $result.Text
        $conf = $result.Confidence
        $confR = [math]::Round($conf, 2)
        $timestamp = Get-Date -Format "HH:mm:ss"
        if ($conf -lt $Confidence) {
            Write-Host ("[$timestamp] 却下: '$text' (信頼度:$confR < 閾値:$Confidence)") `
                -ForegroundColor DarkMagenta
            continue
        }

        Write-Host ("[$timestamp] 認識: '$text' (信頼度:$confR)") -ForegroundColor White
        $cmd = $commands[$text]
        if ($cmd -eq "__EXIT__") {
            Write-Host "音声認識を終了します。" -ForegroundColor Green
            break
        }
        Write-Host "[$timestamp] 実行: $cmd" -ForegroundColor Cyan
        try {
            if ($cmd.StartsWith('[EXE]')) {
                $body = $cmd.Substring(5)
                $parts = $body -split '\[ARG\]', 2
                $exe = $parts[0]
                $arg = if ($parts.Count -gt 1) { $parts[1] } else { $null }
                if ($arg) { & $exe $arg } else { & $exe }
            } else {
                Invoke-Expression $cmd
            }
        } catch {
            Write-Host "[$timestamp] コマンドエラー: $_" -ForegroundColor Red
        }
        $timestampEnd = Get-Date -Format "HH:mm:ss"
        Write-Host "[$timestampEnd] 実行が終わりました。" -ForegroundColor Cyan
        Write-Host $waitMsg -ForegroundColor Green
        Write-Host ""
    }
} finally {
    $recognizer.Dispose()
    Write-Host "音声認識エンジンを解放しました。" -ForegroundColor DarkGray
}
