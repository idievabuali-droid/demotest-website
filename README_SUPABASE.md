Supabase deployment guide

This project is a static site (single `index.html`) and can be hosted on Supabase Sites or Supabase Storage.

Two recommended approaches:

1) Quick: Use Supabase Storage (manual upload)
   - In Supabase dashboard -> Storage -> create a public bucket (e.g. `site`).
   - Upload the contents of this repository (drag & drop `index.html`, `img/`, etc.).
   - Use the public URL: `https://<PROJECT_REF>.supabase.co/storage/v1/object/public/<BUCKET>/index.html`

2) Continuous: GitHub → Supabase Sites (recommended)
   - Create a GitHub repo and push this project.
   - In Supabase dashboard -> Sites (Hosting) -> New site -> Connect GitHub and pick this repo & branch.
   - Publish directory: `.` (root) and leave build command empty (static site).

Automated deploy via GitHub Actions (template included)
--------------------------------------------------
This repo includes `.github/workflows/deploy-to-supabase.yml`. To use it:

1. In your Supabase project, create a Service Key or an access token that can deploy (SUPABASE_ACCESS_TOKEN).
2. In GitHub repo settings -> Secrets -> Actions add two secrets:
   - `SUPABASE_ACCESS_TOKEN` — your Supabase access token
   - `SUPABASE_PROJECT_REF` — your Supabase project ref (found in project settings URL)
3. Push to `main` branch. The workflow will install the Supabase CLI and run the deploy script.

Notes
- The workflow uses the Supabase CLI and assumes the CLI supports non-interactive login via token. If the workflow fails, follow the console errors and consider using the Supabase dashboard's native GitHub integration instead.
- Keep any secrets out of the repository.

Local convenience scripts
------------------------
- `push-to-github.ps1` — helper that will create a GitHub repo with `gh` CLI (if available) and push your current code.
- `deploy-supabase.sh` — script that uses `supabase` CLI to deploy; it expects `SUPABASE_ACCESS_TOKEN` and `SUPABASE_PROJECT_REF` to be set.

If you want, I can try to create the GitHub repo via the GitHub CLI for you (I will provide the exact command to run locally), or walk you through connecting Supabase Sites.
