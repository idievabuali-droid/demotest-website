param(
  [string]$repoName = $(Split-Path -Leaf (Get-Location)),
  [string]$visibility = 'public'
)

if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Write-Error "git is not installed or not in PATH"; exit 1 }
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { Write-Error "gh (GitHub CLI) not found. Install or push manually."; exit 1 }

git init
git add .
git commit -m "Initial commit"

Write-Host "Creating remote repo $repoName via gh..."
gh repo create $repoName --$visibility --confirm
git branch -M main
git remote add origin "https://github.com/$(gh api user --jq .login)/$repoName.git" 2>$null
git push -u origin main

Write-Host "Pushed. Now connect Supabase Sites to this repo or add workflow secrets as instructed in README_SUPABASE.md"
