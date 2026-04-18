param(
  [ValidateSet("status", "next", "start", "pass", "nogo", "block", "run-quality", "init", "record-evidence", "record-audit", "approve-gate", "reject-gate", "governance-check")]
  [string]$Action = "status",
  [string]$StoryId = "",
  [string]$Reason = "",
  [string]$Role = "orchestrator",
  [string]$EvidenceKey = "",
  [string]$EvidenceValue = "",
  [ValidateSet("P0", "P1", "P2")]
  [string]$Severity = "P2",
  [int]$Count = 1,
  [string]$StoriesPath = "workflow/stories.json",
  [string]$QualityPath = "workflow/quality.json",
  [string]$PolicyPath = "workflow/policy.json",
  [int]$MaxIterations = 10,
  [int]$ConsecutiveNoGoLimit = 3
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

function Write-JsonFile {
  param(
    [string]$Path,
    [Parameter(Mandatory = $true)]$Object
  )
  $json = $Object | ConvertTo-Json -Depth 30
  Set-Content -LiteralPath $Path -Value $json -Encoding UTF8
}

function Ensure-StoryDefaults {
  param($Story)
  if ($null -eq $Story.ownerRole) { $Story | Add-Member -NotePropertyName ownerRole -NotePropertyValue "generator" }
  if ($null -eq $Story.acceptance) { $Story | Add-Member -NotePropertyName acceptance -NotePropertyValue @() }
  if ($null -eq $Story.requiredEvidence) { $Story | Add-Member -NotePropertyName requiredEvidence -NotePropertyValue @() }
  if ($null -eq $Story.evidence) { $Story | Add-Member -NotePropertyName evidence -NotePropertyValue ([PSCustomObject]@{}) }
  if ($null -eq $Story.gateStatus) { $Story | Add-Member -NotePropertyName gateStatus -NotePropertyValue "pending" }
  if ($null -eq $Story.blockedReason) { $Story | Add-Member -NotePropertyName blockedReason -NotePropertyValue "" }
  if ($null -eq $Story.findings) {
    $Story | Add-Member -NotePropertyName findings -NotePropertyValue ([PSCustomObject]@{ P0 = 0; P1 = 0; P2 = 0 })
  }
  if ($null -eq $Story.quality) {
    $Story | Add-Member -NotePropertyName quality -NotePropertyValue ([PSCustomObject]@{ passedRequired = $false; results = @(); lastRunAt = $null })
  }
}

function Ensure-StateDefaults {
  param($State)
  if ($null -eq $State.maxIterations) {
    $State | Add-Member -NotePropertyName maxIterations -NotePropertyValue $MaxIterations
  }
  if ($null -eq $State.consecutiveNoGoLimit) {
    $State | Add-Member -NotePropertyName consecutiveNoGoLimit -NotePropertyValue $ConsecutiveNoGoLimit
  }
  if ($null -eq $State.governance) {
    $State | Add-Member -NotePropertyName governance -NotePropertyValue ([PSCustomObject]@{
        policyFile    = $PolicyPath
        qualityFile   = $QualityPath
        lastQualityRun = $null
      })
  }
  if ($null -eq $State.stories) {
    $State | Add-Member -NotePropertyName stories -NotePropertyValue @()
  }
  foreach ($story in $State.stories) {
    Ensure-StoryDefaults -Story $story
  }
}

function Ensure-EvidenceEntry {
  param(
    $Story,
    [string]$Key
  )
  $entry = $Story.evidence.PSObject.Properties[$Key]
  if ($null -eq $entry) {
    $Story.evidence | Add-Member -NotePropertyName $Key -NotePropertyValue ([PSCustomObject]@{
        status    = "missing"
        value     = ""
        updatedAt = $null
      })
  }
}

function Assert-RolePermission {
  param(
    $Policy,
    [string]$RoleName,
    [string]$ActionName
  )
  $rolePolicy = $Policy.roles.PSObject.Properties[$RoleName]
  if ($null -eq $rolePolicy) {
    throw "Unknown role '$RoleName'."
  }
  $allowed = $rolePolicy.Value.allowedActions
  if ($allowed -notcontains $ActionName) {
    throw "Role '$RoleName' is not allowed to run action '$ActionName'."
  }
}

function Get-StoryIndex {
  param(
    $State,
    [string]$Id
  )
  for ($i = 0; $i -lt $State.stories.Count; $i++) {
    if ($State.stories[$i].id -eq $Id) {
      return $i
    }
  }
  return -1
}

function Test-DependenciesMet {
  param(
    $State,
    $Story
  )
  foreach ($dep in $Story.dependsOn) {
    $depStory = $State.stories | Where-Object { $_.id -eq $dep } | Select-Object -First 1
    if ($null -eq $depStory -or $depStory.passes -ne $true) {
      return $false
    }
  }
  return $true
}

function Get-NextStory {
  param($State)
  $eligible = @()
  foreach ($story in $State.stories) {
    if (($story.status -eq "todo" -or $story.status -eq "in_progress") -and (Test-DependenciesMet -State $State -Story $story)) {
      $eligible += $story
    }
  }
  return $eligible | Sort-Object priority, id | Select-Object -First 1
}

function Update-GlobalState {
  param($State)

  $allPassed = $true
  foreach ($story in $State.stories) {
    if ($story.passes -ne $true) {
      $allPassed = $false
      break
    }
  }

  if ($allPassed) {
    $State.status = "complete"
    return
  }

  if ($State.iteration -ge $State.maxIterations) {
    $State.status = "blocked"
    return
  }

  if ($State.consecutiveNoGo -ge $State.consecutiveNoGoLimit) {
    $State.status = "blocked"
    return
  }

  if ($State.status -ne "blocked") {
    $State.status = "in_progress"
  }
}

function Run-QualityChecks {
  param([string]$ConfigPath)
  $config = Read-JsonFile -Path $ConfigPath
  if ($null -eq $config.commands -or $config.commands.Count -eq 0) {
    throw "No quality commands found in $ConfigPath"
  }

  $results = @()
  $failedRequired = $false
  foreach ($entry in $config.commands) {
    $passed = $true
    $errorText = ""
    Write-Host ""
    Write-Host "Running quality check: $($entry.name)"
    Write-Host "Command: $($entry.command)"
    try {
      $null = Invoke-Expression $entry.command
      if ($LASTEXITCODE -ne 0) {
        throw "Command exited with code $LASTEXITCODE"
      }
      Write-Host "Result: PASS"
    } catch {
      $passed = $false
      $errorText = "$($_.Exception.Message)"
      Write-Host "Result: FAIL"
      if ($entry.required -eq $true) {
        $failedRequired = $true
      }
    }
    $results += [PSCustomObject]@{
      name     = $entry.name
      required = [bool]$entry.required
      passed   = $passed
      error    = $errorText
    }
  }

  return [PSCustomObject]@{
    passedRequired = [bool](-not $failedRequired)
    results        = $results
  }
}

function Test-StoryPassEligibility {
  param(
    $Story,
    $Policy,
    $Quality
  )
  if ($Story.gateStatus -ne "approved") {
    throw "Story gateStatus must be 'approved' before pass."
  }

  foreach ($key in $Story.requiredEvidence) {
    Ensure-EvidenceEntry -Story $Story -Key $key
    $entry = $Story.evidence.PSObject.Properties[$key].Value
    if ($entry.status -ne "provided") {
      throw "Missing required evidence '$key'."
    }
  }

  if ($Policy.gates.requirePrinciplesCheck -eq $true) {
    Ensure-EvidenceEntry -Story $Story -Key "principles-check"
    $principles = $Story.evidence.PSObject.Properties["principles-check"].Value
    if ($principles.status -ne "provided") {
      throw "Missing required evidence 'principles-check'."
    }
  }

  if ($Policy.gates.requireNoOpenP0P1 -eq $true -or $Quality.forbidP0P1 -eq $true) {
    if ($Story.findings.P0 -gt 0 -or $Story.findings.P1 -gt 0) {
      throw "Open P0/P1 findings block pass."
    }
  }

  if ($Policy.gates.requireQualityPassed -eq $true) {
    if ($Story.quality.passedRequired -ne $true) {
      throw "Required quality checks have not passed for this story."
    }
  }
}

function Print-Summary {
  param($State)
  Write-Host "Task: $($State.taskId)"
  Write-Host "Global status: $($State.status)"
  Write-Host "Iteration: $($State.iteration)/$($State.maxIterations)"
  Write-Host "Consecutive No-Go: $($State.consecutiveNoGo)/$($State.consecutiveNoGoLimit)"
  Write-Host ""
  Write-Host "Stories:"
  foreach ($story in ($State.stories | Sort-Object priority, id)) {
    Write-Host "- [$($story.status)] $($story.id) owner=$($story.ownerRole) gate=$($story.gateStatus) p$($story.priority) passes=$($story.passes) P0=$($story.findings.P0) P1=$($story.findings.P1)"
  }
}

if ($Action -eq "init") {
  if (Test-Path -LiteralPath $StoriesPath) {
    throw "Refusing to overwrite existing $StoriesPath"
  }
  $initial = [PSCustomObject]@{
    taskId               = "TASK-001"
    status               = "in_progress"
    iteration            = 0
    maxIterations        = $MaxIterations
    consecutiveNoGo      = 0
    consecutiveNoGoLimit = $ConsecutiveNoGoLimit
    governance           = [PSCustomObject]@{
      policyFile    = $PolicyPath
      qualityFile   = $QualityPath
      lastQualityRun = $null
    }
    stories              = @(
      [PSCustomObject]@{
        id               = "US-001"
        title            = "Fill this story"
        priority         = 1
        dependsOn        = @()
        ownerRole        = "generator"
        status           = "todo"
        passes           = $false
        notes            = ""
        acceptance       = @("Define acceptance criteria")
        requiredEvidence = @("implementation-summary", "test-results", "principles-check")
        evidence         = [PSCustomObject]@{}
        gateStatus       = "pending"
        blockedReason    = ""
        findings         = [PSCustomObject]@{ P0 = 0; P1 = 0; P2 = 0 }
        quality          = [PSCustomObject]@{ passedRequired = $false; results = @(); lastRunAt = $null }
      }
    )
  }
  Write-JsonFile -Path $StoriesPath -Object $initial
  Write-Host "Initialized $StoriesPath"
  exit 0
}

$state = Read-JsonFile -Path $StoriesPath
$quality = Read-JsonFile -Path $QualityPath
$policy = Read-JsonFile -Path $PolicyPath
Ensure-StateDefaults -State $state
Assert-RolePermission -Policy $policy -RoleName $Role -ActionName $Action

switch ($Action) {
  "status" {
    Update-GlobalState -State $state
    Write-JsonFile -Path $StoriesPath -Object $state
    Print-Summary -State $state
  }
  "next" {
    Update-GlobalState -State $state
    Write-JsonFile -Path $StoriesPath -Object $state
    if ($state.status -eq "complete") {
      Write-Host "COMPLETE"
      break
    }
    if ($state.status -eq "blocked") {
      Write-Host "BLOCKED"
      break
    }
    $next = Get-NextStory -State $state
    if ($null -eq $next) {
      Write-Host "No ready story. Check dependencies and blocked states."
    } else {
      Write-Host "Next story: $($next.id) [$($next.status)] p$($next.priority) - $($next.title)"
    }
  }
  "start" {
    if ([string]::IsNullOrWhiteSpace($StoryId)) { throw "start requires -StoryId" }
    $idx = Get-StoryIndex -State $state -Id $StoryId
    if ($idx -lt 0) { throw "Story not found: $StoryId" }
    if (-not (Test-DependenciesMet -State $state -Story $state.stories[$idx])) {
      throw "Dependencies are not satisfied for story $StoryId"
    }
    $state.stories[$idx].status = "in_progress"
    $state.stories[$idx].blockedReason = ""
    Update-GlobalState -State $state
    Write-JsonFile -Path $StoriesPath -Object $state
    Write-Host "Story started: $StoryId"
  }
  "record-evidence" {
    if ([string]::IsNullOrWhiteSpace($StoryId)) { throw "record-evidence requires -StoryId" }
    if ([string]::IsNullOrWhiteSpace($EvidenceKey)) { throw "record-evidence requires -EvidenceKey" }
    $idx = Get-StoryIndex -State $state -Id $StoryId
    if ($idx -lt 0) { throw "Story not found: $StoryId" }
    Ensure-EvidenceEntry -Story $state.stories[$idx] -Key $EvidenceKey
    $state.stories[$idx].evidence.PSObject.Properties[$EvidenceKey].Value.status = "provided"
    $state.stories[$idx].evidence.PSObject.Properties[$EvidenceKey].Value.value = $EvidenceValue
    $state.stories[$idx].evidence.PSObject.Properties[$EvidenceKey].Value.updatedAt = [DateTime]::UtcNow.ToString("o")
    Write-JsonFile -Path $StoriesPath -Object $state
    Write-Host "Evidence recorded: $StoryId / $EvidenceKey"
  }
  "record-audit" {
    if ([string]::IsNullOrWhiteSpace($StoryId)) { throw "record-audit requires -StoryId" }
    if ($Count -lt 1) { throw "record-audit requires -Count >= 1" }
    $idx = Get-StoryIndex -State $state -Id $StoryId
    if ($idx -lt 0) { throw "Story not found: $StoryId" }
    $state.stories[$idx].findings.$Severity += $Count
    $state.stories[$idx].gateStatus = "pending"
    Write-JsonFile -Path $StoriesPath -Object $state
    Write-Host "Audit recorded: $StoryId / $Severity +$Count"
  }
  "approve-gate" {
    if ([string]::IsNullOrWhiteSpace($StoryId)) { throw "approve-gate requires -StoryId" }
    $idx = Get-StoryIndex -State $state -Id $StoryId
    if ($idx -lt 0) { throw "Story not found: $StoryId" }
    $state.stories[$idx].gateStatus = "approved"
    $state.stories[$idx].blockedReason = ""
    if (-not [string]::IsNullOrWhiteSpace($Reason)) {
      $state.stories[$idx].notes = $Reason
    }
    Write-JsonFile -Path $StoriesPath -Object $state
    Write-Host "Gate approved: $StoryId"
  }
  "reject-gate" {
    if ([string]::IsNullOrWhiteSpace($StoryId)) { throw "reject-gate requires -StoryId" }
    $idx = Get-StoryIndex -State $state -Id $StoryId
    if ($idx -lt 0) { throw "Story not found: $StoryId" }
    $state.stories[$idx].gateStatus = "rejected"
    $state.stories[$idx].blockedReason = $Reason
    Write-JsonFile -Path $StoriesPath -Object $state
    Write-Host "Gate rejected: $StoryId"
  }
  "run-quality" {
    $qualityResult = Run-QualityChecks -ConfigPath $QualityPath
    $qualityPassed = [bool](-not ($qualityResult.results | Where-Object { $_.required -eq $true -and $_.passed -ne $true }))
    $timestamp = [DateTime]::UtcNow.ToString("o")
    $state.governance.lastQualityRun = [PSCustomObject]@{
      at             = $timestamp
      passedRequired = $qualityPassed
      storyId        = $StoryId
      results        = $qualityResult.results
    }
    if (-not [string]::IsNullOrWhiteSpace($StoryId)) {
      $idx = Get-StoryIndex -State $state -Id $StoryId
      if ($idx -lt 0) { throw "Story not found: $StoryId" }
      $state.stories[$idx].quality.passedRequired = $qualityPassed
      $state.stories[$idx].quality.results = $qualityResult.results
      $state.stories[$idx].quality.lastRunAt = $timestamp
      if ($policy.gates.failStoryOnRequiredQualityFail -eq $true -and $qualityPassed -ne $true) {
        $state.stories[$idx].gateStatus = "rejected"
        $state.stories[$idx].blockedReason = "required_quality_checks_failed"
      }
    }
    Write-JsonFile -Path $StoriesPath -Object $state
    if ($qualityPassed -eq $true) {
      Write-Host ""
      Write-Host "All required quality checks passed."
    } else {
      throw "Required quality checks failed."
    }
  }
  "pass" {
    if ([string]::IsNullOrWhiteSpace($StoryId)) { throw "pass requires -StoryId" }
    $idx = Get-StoryIndex -State $state -Id $StoryId
    if ($idx -lt 0) { throw "Story not found: $StoryId" }
    Test-StoryPassEligibility -Story $state.stories[$idx] -Policy $policy -Quality $quality
    $state.stories[$idx].status = "done"
    $state.stories[$idx].passes = $true
    if (-not [string]::IsNullOrWhiteSpace($Reason)) {
      $state.stories[$idx].notes = $Reason
    }
    $state.iteration += 1
    $state.consecutiveNoGo = 0
    Update-GlobalState -State $state
    Write-JsonFile -Path $StoriesPath -Object $state
    if ($state.status -eq "complete") {
      Write-Host "COMPLETE"
    } else {
      Write-Host "Story passed: $StoryId"
    }
  }
  "nogo" {
    if ([string]::IsNullOrWhiteSpace($StoryId)) { throw "nogo requires -StoryId" }
    $idx = Get-StoryIndex -State $state -Id $StoryId
    if ($idx -lt 0) { throw "Story not found: $StoryId" }
    $state.stories[$idx].status = "todo"
    $state.stories[$idx].passes = $false
    $state.stories[$idx].gateStatus = "rejected"
    $state.stories[$idx].blockedReason = $Reason
    if (-not [string]::IsNullOrWhiteSpace($Reason)) {
      $state.stories[$idx].notes = $Reason
    }
    $state.iteration += 1
    $state.consecutiveNoGo += 1
    Update-GlobalState -State $state
    Write-JsonFile -Path $StoriesPath -Object $state
    if ($state.status -eq "blocked") {
      Write-Host "BLOCKED: consecutive No-Go or iteration limit reached."
    } else {
      Write-Host "No-Go recorded for story: $StoryId"
    }
  }
  "block" {
    $state.status = "blocked"
    if (-not [string]::IsNullOrWhiteSpace($Reason)) {
      $state.blockedReason = $Reason
    } elseif ($null -eq $state.blockedReason) {
      $state | Add-Member -NotePropertyName blockedReason -NotePropertyValue "manual_block"
    }
    Write-JsonFile -Path $StoriesPath -Object $state
    Write-Host "Workflow blocked."
  }
  "governance-check" {
    $errors = @()
    foreach ($story in $state.stories) {
      foreach ($need in $story.requiredEvidence) {
        Ensure-EvidenceEntry -Story $story -Key $need
      }
      if ($quality.forbidP0P1 -eq $true -and ($story.findings.P0 -gt 0 -or $story.findings.P1 -gt 0) -and $story.passes -eq $true) {
        $errors += "Story $($story.id) is marked pass with open P0/P1 findings."
      }
      if ($story.gateStatus -eq "approved") {
        foreach ($need in $story.requiredEvidence) {
          $entry = $story.evidence.PSObject.Properties[$need].Value
          if ($entry.status -ne "provided") {
            $errors += "Story $($story.id) approved without required evidence '$need'."
          }
        }
      }
      if ($policy.gates.requirePrinciplesCheck -eq $true) {
        Ensure-EvidenceEntry -Story $story -Key "principles-check"
      }
    }
    Write-JsonFile -Path $StoriesPath -Object $state
    if ($errors.Count -gt 0) {
      foreach ($err in $errors) { Write-Host "ERROR: $err" }
      throw "Governance check failed."
    }
    Write-Host "Governance check passed."
  }
  default {
    throw "Unsupported action: $Action"
  }
}
