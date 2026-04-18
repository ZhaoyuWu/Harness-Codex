param(
  [string]$StoriesPath = "workflow/stories.json",
  [string]$ArchiveRoot = "archive"
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

function Copy-IfExists {
  param(
    [string]$Source,
    [string]$Destination
  )
  if (Test-Path -LiteralPath $Source) {
    Copy-Item -LiteralPath $Source -Destination $Destination -Force
  }
}

$state = Read-JsonFile -Path $StoriesPath
$taskId = if ([string]::IsNullOrWhiteSpace($state.taskId)) { "TASK-UNKNOWN" } else { $state.taskId }
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$targetDir = Join-Path $ArchiveRoot "$taskId-$stamp"

New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $targetDir "handover") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $targetDir "workflow") -Force | Out-Null

Copy-IfExists -Source "handover/public.md" -Destination (Join-Path $targetDir "handover/public.md")
Copy-IfExists -Source "handover/local/generator.md" -Destination (Join-Path $targetDir "handover/generator.local.md")
Copy-IfExists -Source "handover/local/evaluator.md" -Destination (Join-Path $targetDir "handover/evaluator.local.md")
Copy-IfExists -Source "handover/tasks/task.md" -Destination (Join-Path $targetDir "handover/task.md")
Copy-IfExists -Source "handover/tasks/generator.md" -Destination (Join-Path $targetDir "handover/generator.task.md")
Copy-IfExists -Source "handover/tasks/evaluator.md" -Destination (Join-Path $targetDir "handover/evaluator.task.md")

Copy-IfExists -Source "workflow/stories.json" -Destination (Join-Path $targetDir "workflow/stories.json")
Copy-IfExists -Source "workflow/quality.json" -Destination (Join-Path $targetDir "workflow/quality.json")
Copy-IfExists -Source "workflow/policy.json" -Destination (Join-Path $targetDir "workflow/policy.json")

Write-Host "Task archive created:"
Write-Host $targetDir
