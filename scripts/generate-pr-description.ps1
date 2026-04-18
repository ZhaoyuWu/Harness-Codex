param(
  [string]$StoriesPath = "workflow/stories.json",
  [string]$PolicyPath = "workflow/policy.json",
  [string]$QualityPath = "workflow/quality.json",
  [string]$GeneratorHandover = "handover/local/generator.md",
  [string]$EvaluatorHandover = "handover/local/evaluator.md",
  [string]$PublicHandover = "handover/public.md",
  [string]$OutputPath = "docs/pr/PR_DESCRIPTION.md",
  [switch]$PrintOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Read-JsonIfExists {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) { return $null }
  return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Read-TextIfExists {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) { return "" }
  return Get-Content -LiteralPath $Path -Raw
}

function First-NonEmptyLine {
  param([string]$Text)
  foreach ($line in ($Text -split "`r?`n")) {
    $trim = $line.Trim()
    if ($trim.Length -gt 0 -and -not $trim.StartsWith("#")) {
      return $trim
    }
  }
  return ""
}

$stories = Read-JsonIfExists -Path $StoriesPath
$policy = Read-JsonIfExists -Path $PolicyPath
$quality = Read-JsonIfExists -Path $QualityPath
$generatorText = Read-TextIfExists -Path $GeneratorHandover
$evaluatorText = Read-TextIfExists -Path $EvaluatorHandover
$publicText = Read-TextIfExists -Path $PublicHandover

$taskId = if ($null -ne $stories -and $stories.taskId) { "$($stories.taskId)" } else { "TASK-UNKNOWN" }
$globalStatus = if ($null -ne $stories -and $stories.status) { "$($stories.status)" } else { "unknown" }

$storyLines = @()
$requiredFixLines = @()
$riskLines = @()
$evidenceLines = @()

if ($null -ne $stories -and $null -ne $stories.stories) {
  foreach ($story in ($stories.stories | Sort-Object priority, id)) {
    $storyLines += "- [$($story.status)] $($story.id): $($story.title)"
    $p0 = [int]$story.findings.P0
    $p1 = [int]$story.findings.P1
    $p2 = [int]$story.findings.P2

    if ($p0 -gt 0 -or $p1 -gt 0) {
      $requiredFixLines += "- $($story.id): Open findings P0=$p0, P1=$p1 (must fix before merge)."
    }
    if ($p2 -gt 0) {
      $riskLines += "- $($story.id): P2 findings=$p2 (tracked follow-up needed)."
    }

    if ($null -ne $story.requiredEvidence) {
      foreach ($key in $story.requiredEvidence) {
        $entry = $story.evidence.PSObject.Properties[$key]
        if ($null -ne $entry -and $entry.Value.status -eq "provided") {
          $val = "$($entry.Value.value)".Trim()
          if ($val.Length -gt 0) {
            $evidenceLines += "- $($story.id) / ${key}: $val"
          } else {
            $evidenceLines += "- $($story.id) / ${key}: provided"
          }
        }
      }
    }
  }
}

if ($storyLines.Count -eq 0) { $storyLines = @("- No story entries found.") }
if ($requiredFixLines.Count -eq 0) { $requiredFixLines = @("- No blocking P0/P1 findings recorded.") }
if ($riskLines.Count -eq 0) { $riskLines = @("- No additional tracked risks recorded.") }
if ($evidenceLines.Count -eq 0) { $evidenceLines = @("- No evidence entries found in stories.json.") }

$generatorSummary = First-NonEmptyLine -Text $generatorText
$evaluatorSummary = First-NonEmptyLine -Text $evaluatorText
$publicSummary = First-NonEmptyLine -Text $publicText

if ([string]::IsNullOrWhiteSpace($generatorSummary)) { $generatorSummary = "No generator local handover summary found." }
if ([string]::IsNullOrWhiteSpace($evaluatorSummary)) { $evaluatorSummary = "No evaluator local handover summary found." }
if ([string]::IsNullOrWhiteSpace($publicSummary)) { $publicSummary = "No public handover summary found." }

$qualityChecks = @()
if ($null -ne $quality -and $null -ne $quality.requiredChecks) {
  foreach ($c in $quality.requiredChecks) {
    $qualityChecks += "- Required: $c"
  }
}
if ($qualityChecks.Count -eq 0) { $qualityChecks = @("- Required checks are not configured.") }

$policyLines = @()
if ($null -ne $policy -and $null -ne $policy.gates) {
  $policyLines += "- requirePrinciplesCheck: $($policy.gates.requirePrinciplesCheck)"
  $policyLines += "- requireQualityPassed: $($policy.gates.requireQualityPassed)"
  $policyLines += "- requireNoOpenP0P1: $($policy.gates.requireNoOpenP0P1)"
}
if ($policyLines.Count -eq 0) { $policyLines = @("- Governance gates not configured.") }

$markdown = @"
## Summary
This PR updates task **$taskId** with current workflow status **$globalStatus**.

## What Changed
### Story Progress
$($storyLines -join "`n")

### Generator Branch Summary
$generatorSummary

### Evaluator Branch Summary
$evaluatorSummary

## Why
$publicSummary

## Validation
### Evidence
$($evidenceLines -join "`n")

### Quality Gates
$($qualityChecks -join "`n")

### Governance Policy Checks
$($policyLines -join "`n")

## Risks
$($riskLines -join "`n")

## Required Fixes Before Merge
$($requiredFixLines -join "`n")

## Rollback
- Revert this PR commit set.
- Restore last known good state from git history.

"@

if ($PrintOnly.IsPresent) {
  Write-Output $markdown
  exit 0
}

$outDir = Split-Path -Parent $OutputPath
if (-not (Test-Path -LiteralPath $outDir)) {
  New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

Set-Content -LiteralPath $OutputPath -Value $markdown -Encoding UTF8
Write-Host "PR description generated:"
Write-Host $OutputPath
