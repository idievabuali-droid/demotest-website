#!/bin/bash
# Deploy script for Netlify

echo "🚀 Deploying to Netlify..."

# Add all changes
git add .

# Get commit message from user or use default
if [ "$1" ]; then
    COMMIT_MSG="$1"
else
    COMMIT_MSG="Update website content"
fi

# Commit changes
git commit -m "$COMMIT_MSG"

# Push to GitHub (this will trigger automatic deployment)
git push

echo "✅ Changes pushed to GitHub!"
echo "🌐 Automatic deployment will start shortly at: https://demotest-website.netlify.app"
echo "📊 Monitor deployment: https://app.netlify.com/projects/demotest-website"
