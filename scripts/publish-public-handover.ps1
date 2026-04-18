param(
  [string]$GeneratorPath = "handover/local/generator.md",
  [string]$EvaluatorPath = "handover/local/evaluator.md",
  [string]$PublicIndexPath = "handover/public.md",
  [string]$SessionPrefixPath = "handover/session-",
  [string]$HistoryDir = "handover/history",
  [string]$NextOwner = "",
  [string]$WorkflowScript = "scripts/workflow-loop.ps1",
  [switch]$SkipGateCheck
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Read-TextIfExists {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) { return "" }
  return Get-Content -LiteralPath $Path -Raw
}

function Extract-MaxSessionNumber {
  param(
    [string]$PatternPath
  )
  $max = 0
  $files = Get-ChildItem -Path $PatternPath -File -ErrorAction SilentlyContinue
  foreach ($f in $files) {
    if ($f.Name -match "session-(\d{4,})\.md$") {
      $num = [int]$Matches[1]
      if ($num -gt $max) { $max = $num }
    }
  }
  return $max
}

if (-not $SkipGateCheck.IsPresent) {
  powershell -ExecutionPolicy Bypass -File $WorkflowScript -Action governance-check -Role orchestrator | Out-Host
}

$sessionDir = Split-Path -Parent $SessionPrefixPath
if ([string]::IsNullOrWhiteSpace($sessionDir)) { $sessionDir = "handover" }

if (-not (Test-Path -LiteralPath $sessionDir)) {
  New-Item -ItemType Directory -Path $sessionDir -Force | Out-Null
}
if (-not (Test-Path -LiteralPath $HistoryDir)) {
  New-Item -ItemType Directory -Path $HistoryDir -Force | Out-Null
}

$maxSession = 0
$maxSession = [Math]::Max($maxSession, (Extract-MaxSessionNumber -PatternPath $sessionDir))
$maxSession = [Math]::Max($maxSession, (Extract-MaxSessionNumber -PatternPath $HistoryDir))
$nextSession = $maxSession + 1
$sessionId = ("session-{0:D4}" -f $nextSession)

$sessionFile = Join-Path $sessionDir "$sessionId.md"
$historyFile = Join-Path $HistoryDir "$sessionId.md"
$createdAt = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")

$generatorText = Read-TextIfExists -Path $GeneratorPath
$evaluatorText = Read-TextIfExists -Path $EvaluatorPath
if ([string]::IsNullOrWhiteSpace($generatorText)) { $generatorText = "Not available." }
if ([string]::IsNullOrWhiteSpace($evaluatorText)) { $evaluatorText = "Not available." }
if ([string]::IsNullOrWhiteSpace($NextOwner)) { $NextOwner = "unassigned" }

$content = @"
# Public Handover - $sessionId

## Metadata
- Session ID: $sessionId
- Created At (UTC): $createdAt
- Next Owner: $NextOwner

## Source Files
- $GeneratorPath
- $EvaluatorPath

## Generator Summary
$generatorText

## Evaluator Summary
$evaluatorText

## Final Status
published
"@

Set-Content -LiteralPath $sessionFile -Value $content -Encoding UTF8
Set-Content -LiteralPath $historyFile -Value $content -Encoding UTF8

$indexContent = @"
# Public Handover

Latest session: **$sessionId**

- Current handover file: $sessionFile
- Historical handover file: $historyFile
- Created At (UTC): $createdAt
- Next Owner: $NextOwner
"@
Set-Content -LiteralPath $PublicIndexPath -Value $indexContent -Encoding UTF8

Write-Host "Public handover published:"
Write-Host "- Session file: $sessionFile"
Write-Host "- History file: $historyFile"
Write-Host "- Index updated: $PublicIndexPath"
