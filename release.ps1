param (
    [Parameter(Mandatory = $false)]
    [string]$Version,
    
    [Parameter(Mandatory = $false)]
    [string]$ReleaseNotes
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Write-Step { param([string]$Message) Write-Host "`n--- $Message ---" -ForegroundColor Cyan }
function Write-Success { param([string]$Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-ErrorMsg { param([string]$Message) Write-Host "❌ Error: $Message" -ForegroundColor Red }

try {
    # --- Step 0: Check Version Argument ---
    if (-not $Version) {
        Write-ErrorMsg "Version number is required. Usage: .\release.ps1 -Version '1.1.0'"
        exit 1
    }

    Write-Host "🚀 Preparing Release v$Version..." -ForegroundColor Magenta

    # --- Step 1: Update pubspec.yaml ---
    Write-Step "Step 1: Updating pubspec.yaml"
    $pubspecPath = "pubspec.yaml"
    if (-not (Test-Path $pubspecPath)) { throw "pubspec.yaml not found!" }
    
    $content = Get-Content $pubspecPath -Raw
    if ($content -match "(?m)^version: .*") {
        $newContent = $content -replace "(?m)^version: .*", "version: $Version"
        Set-Content -Path $pubspecPath -Value $newContent -Encoding UTF8
        Write-Success "Updated version to $Version"
    } else {
        Write-ErrorMsg "Could not find 'version:' in pubspec.yaml"
    }

    # --- Step 2: Update Release Notes ---
    if ($ReleaseNotes) {
        Write-Step "Step 2: Updating Release Notes"
        $notesPath = "assets/release_notes.md"
        if (-not (Test-Path "assets")) { New-Item -ItemType Directory -Force -Path "assets" | Out-Null }
        
        $currentNotes = ""
        if (Test-Path $notesPath) { $currentNotes = Get-Content $notesPath -Raw }
        
        $formattedNotes = $ReleaseNotes -replace "\. ", ".`n"
        $header = "# Release Notes`n`n## v$Version`n$formattedNotes`n"
        $newNotes = $header + ($currentNotes -replace "# Release Notes\s+", "")
        Set-Content -Path $notesPath -Value $newNotes -Encoding UTF8
        Write-Success "Updated $notesPath"
    }

    # --- Step 3: Git Operations ---
    Write-Step "Step 3: Git Commit, Tag & Push"
    $tagName = "v$Version"
    
    # Add changes (pubspec, release_notes)
    git add .
    
    # Commit
    $commitMsg = "Bump version to $Version"
    if ($ReleaseNotes) { $commitMsg = "Release v$Version`n`n$ReleaseNotes" }
    
    # Check if there are changes to commit
    $gitStatus = git status --porcelain
    if ($gitStatus) {
        git commit -m $commitMsg
        Write-Success "Committed changes."
    } else {
        Write-Host "No changes to commit (version might be same)." -ForegroundColor Yellow
    }

    # Tag
    $tagExists = git tag -l $tagName
    if (-not $tagExists) {
        git tag -a $tagName -m "Release $Version"
        Write-Success "Created Git Tag: $tagName"
    } else {
        Write-Host "Tag $tagName already exists." -ForegroundColor Yellow
    }

    # Push triggers the GitHub Action
    Write-Step "Step 4: Triggering GitHub Action (Push)"
    
    git push origin HEAD
    git push origin $tagName
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Pushed to GitHub successfully!"
        Write-Host "`n🚀 GitHub Action should now be building and deploying v$Version." -ForegroundColor Magenta
        Write-Host "Monitor progress at: https://github.com/erueloi/centim/actions" -ForegroundColor Cyan
    } else {
        Write-ErrorMsg "Git push failed."
    }
}
catch {
    Write-ErrorMsg $_.Exception.Message
    exit 1
}
