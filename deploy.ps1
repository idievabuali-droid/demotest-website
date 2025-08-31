# Deploy script for Netlify (PowerShell version)

param(
    [string]$CommitMessage = "Update website content"
)

Write-Host "🚀 Deploying to Netlify..." -ForegroundColor Green

# Add all changes
git add .

# Commit changes
git commit -m $CommitMessage

# Push to GitHub (this will trigger automatic deployment)
git push

Write-Host "✅ Changes pushed to GitHub!" -ForegroundColor Green
Write-Host "🌐 Automatic deployment will start shortly at: https://demotest-website.netlify.app" -ForegroundColor Cyan
Write-Host "📊 Monitor deployment: https://app.netlify.com/projects/demotest-website" -ForegroundColor Cyan
