param(
  [string]$StoriesPath = "workflow/stories.json",
  [string]$WorkflowScript = "scripts/workflow-loop.ps1",
  [switch]$StartNext
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Read-JsonFile {
  param([string]$Path)
  if (-not (Test-Path -LiteralPath $Path)) {
    throw "File not found: $Path"
  }
  return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

Write-Host "== Story Autopilot =="
Write-Host "Checking workflow status..."
powershell -ExecutionPolicy Bypass -File $WorkflowScript -Action status -Role orchestrator | Out-Host

$state = Read-JsonFile -Path $StoriesPath
if ($state.status -eq "complete") {
  Write-Host ""
  Write-Host "Workflow is COMPLETE."
  exit 0
}
if ($state.status -eq "blocked") {
  Write-Host ""
  Write-Host "Workflow is BLOCKED. Resolve blockers before continuing."
  exit 1
}

$nextStory = $state.stories |
  Where-Object { ($_.status -eq "todo" -or $_.status -eq "in_progress") } |
  Sort-Object priority, id |
  Select-Object -First 1

if ($null -eq $nextStory) {
  Write-Host "No ready story found."
  exit 0
}

Write-Host ""
Write-Host "Next story candidate: $($nextStory.id) - $($nextStory.title)"
Write-Host "Owner role: $($nextStory.ownerRole)"
Write-Host "Gate: $($nextStory.gateStatus)"

if ($StartNext.IsPresent) {
  Write-Host ""
  Write-Host "Starting story..."
  powershell -ExecutionPolicy Bypass -File $WorkflowScript -Action start -StoryId $nextStory.id -Role generator | Out-Host
}

Write-Host ""
Write-Host "Recommended session checklist:"
Write-Host "1) /generator"
Write-Host "2) run-quality for story"
Write-Host "3) /evaluator"
Write-Host "4) record-audit + record-evidence"
Write-Host "5) approve-gate or reject-gate"
Write-Host "6) pass or nogo"
