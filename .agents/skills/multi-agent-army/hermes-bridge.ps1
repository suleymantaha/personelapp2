param(
    [Parameter(Mandatory=$true)]
    [string]$Task,
    [string]$OutputFile = "hermes_output.json",
    [string]$Skills = ""
)

$MODEL    = "nvidia/nemotron-3-ultra-550b-a55b"
$PROVIDER = "nvidia"
$SCRIPT_DIR   = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_ROOT = Split-Path -Parent (Split-Path -Parent $SCRIPT_DIR)

# 1. Context yukle
$contextFile = Join-Path $SCRIPT_DIR "flutter-project-context.md"
$projectContext = ""
if (Test-Path $contextFile) {
    $raw = Get-Content $contextFile -Raw -Encoding UTF8
    $projectContext = $raw.Substring(0, [Math]::Min($raw.Length, 1500))
}

# 2. Gecici prompt dosyasi olustur
$promptFile = Join-Path $env:TEMP "hermes_prompt_$([System.Guid]::NewGuid().ToString('N').Substring(0,8)).txt"

$promptContent = @"
Gorev: $Task

CIKTI KURALI: Sadece asagidaki JSON yapisini dondur. Baska hicbir aciklama, yorum veya metin yazma.

Ornek cikti formati:
{"status":"completed","summary":"kisa ozet","findings":["bulgu1","bulgu2"],"files_to_change":["lib/example.dart"],"recommended_actions":[{"priority":"high","action":"yapilacak is","file":"dosya"}],"quality_gates":{"notes":"ek not"},"estimated_complexity":"simple"}

PROJE BILGISI:
$projectContext
"@

$promptContent | Set-Content -Path $promptFile -Encoding UTF8

# 3. Hermes -z <file> chat ... formatinda calistir
Write-Host "Hermes (nemotron-550b) baslatiliyor..." -ForegroundColor Cyan
Write-Host "Gorev: $($Task.Substring(0, [Math]::Min($Task.Length, 80)))..." -ForegroundColor Gray

$startTime = Get-Date

$hermesArgs = @("-z", $promptFile, "chat", "-m", $MODEL, "--provider", $PROVIDER, "-Q")
if ($Skills -ne "") {
    $hermesArgs += @("--skills", $Skills)
}

$hermesOutput = & hermes @hermesArgs 2>&1

$elapsed = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 2)

# Gecici dosyayi temizle
Remove-Item $promptFile -Force -ErrorAction SilentlyContinue

# 4. JSON ayikla
$rawText = ($hermesOutput | Where-Object { $_ -notmatch "^session_id:" -and $_ -notmatch "^System\.Management" }) -join " "

$jsonPattern = "(?s)\{.+\}"
$jsonMatch = [regex]::Match($rawText, $jsonPattern)
$parsedResult = $null

if ($jsonMatch.Success) {
    try {
        $parsedResult = $jsonMatch.Value | ConvertFrom-Json
        Write-Host "JSON ozet alindi (${elapsed}s)" -ForegroundColor Green
    } catch {
        Write-Host "JSON parse hatasi, ham metin kullaniliyor" -ForegroundColor Yellow
        $parsedResult = [PSCustomObject]@{
            status = "completed"
            summary = $rawText.Trim().Substring(0, [Math]::Min($rawText.Trim().Length, 500))
            findings = @()
            files_to_change = @()
            recommended_actions = @()
            quality_gates = @{ notes = "JSON parse hatasi" }
            estimated_complexity = "unknown"
            raw_output = $rawText
        }
    }
} else {
    Write-Host "JSON bulunamadi, ham metin sariliyor (${elapsed}s)" -ForegroundColor Yellow
    $parsedResult = [PSCustomObject]@{
        status = "completed"
        summary = $rawText.Trim().Substring(0, [Math]::Min($rawText.Trim().Length, 500))
        findings = @()
        files_to_change = @()
        recommended_actions = @()
        quality_gates = @{ notes = "JSON yapisal cikti yok" }
        estimated_complexity = "unknown"
        raw_output = $rawText
    }
}

# 5. Kaydet
$output = [PSCustomObject]@{
    hermes_meta = [PSCustomObject]@{
        model     = $MODEL
        provider  = $PROVIDER
        elapsed_s = $elapsed
        timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        task      = $Task
    }
    result = $parsedResult
}

$outputPath = Join-Path $PROJECT_ROOT $OutputFile
$output | ConvertTo-Json -Depth 10 | Set-Content -Path $outputPath -Encoding UTF8

# 6. Ozet yazdir
Write-Host ""
Write-Host "Ozet: $outputPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "======== HERMES OZETI ========" -ForegroundColor Magenta
Write-Host "Status  : $($parsedResult.status)" -ForegroundColor Green
if ($parsedResult.summary) {
    Write-Host "Ozet    : $($parsedResult.summary.ToString().Substring(0,[Math]::Min($parsedResult.summary.ToString().Length,200)))" -ForegroundColor White
}
if ($parsedResult.recommended_actions -and $parsedResult.recommended_actions.Count -gt 0) {
    Write-Host ""
    Write-Host "Aksiyonlar:" -ForegroundColor Yellow
    foreach ($action in $parsedResult.recommended_actions) {
        $pri = if ($action.priority) { $action.priority.ToUpper() } else { "?" }
        Write-Host "  [$pri] $($action.action)" -ForegroundColor White
        if ($action.file) { Write-Host "        -> $($action.file)" -ForegroundColor Gray }
    }
}
Write-Host "Elapsed : ${elapsed}s" -ForegroundColor Gray
Write-Host "==============================" -ForegroundColor Magenta

return $outputPath
