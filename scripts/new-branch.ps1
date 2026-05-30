#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Creates the next DATA-XX branch automatically.
.DESCRIPTION
    Scans all local and remote branches for the highest DATA-XX number,
    increments it, and creates a new branch.
.EXAMPLE
    .\scripts\new-branch.ps1 add-customer-lifetime-value
    # Creates: DATA-43/add-customer-lifetime-value
.EXAMPLE
    .\scripts\new-branch.ps1 fix-order-deduplication
    # Creates: DATA-44/fix-order-deduplication
#>

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Description
)

# Ensure we're on main and up to date
git fetch origin --quiet 2>$null

# Find the highest DATA-XX number across all branches
$branches = git branch -a --list "*DATA-*" 2>$null
$maxNum = 0

foreach ($branch in $branches) {
    if ($branch -match 'DATA-(\d+)') {
        $num = [int]$Matches[1]
        if ($num -gt $maxNum) { $maxNum = $num }
    }
}

$nextNum = $maxNum + 1
$slug = $Description -replace '\s+', '-' -replace '[^a-zA-Z0-9\-]', '' | ForEach-Object { $_.ToLower() }
$branchName = "DATA-$nextNum/$slug"

# Create and switch to the new branch
git checkout main --quiet 2>$null
git pull origin main --quiet 2>$null
git checkout -b $branchName

Write-Host ""
Write-Host "  Created branch: $branchName" -ForegroundColor Green
Write-Host "  When ready, push with: git push -u origin $branchName" -ForegroundColor DarkGray
Write-Host ""
