#!/usr/bin/env bash
# Usage: SUPABASE_ACCESS_TOKEN=xxx SUPABASE_PROJECT_REF=yyy ./deploy-supabase.sh
set -euo pipefail
if [ -z "${SUPABASE_ACCESS_TOKEN:-}" ] || [ -z "${SUPABASE_PROJECT_REF:-}" ]; then
  echo "Please set SUPABASE_ACCESS_TOKEN and SUPABASE_PROJECT_REF environment variables."
  exit 1
fi
echo "Logging into Supabase CLI..."
supabase login --service-role "$SUPABASE_ACCESS_TOKEN"
echo "Deploying project ref $SUPABASE_PROJECT_REF from current directory..."
# Try preferred deploy command; different versions of the CLI may have different commands
if supabase projects deploy --project-ref "$SUPABASE_PROJECT_REF" --directory .; then
  echo "Deployed via projects deploy"
elif supabase deploy --project "$SUPABASE_PROJECT_REF" --site .; then
  echo "Deployed via deploy"
else
  echo "Deployment attempted; if this fails check supabase CLI version and consult README_SUPABASE.md"
fi
