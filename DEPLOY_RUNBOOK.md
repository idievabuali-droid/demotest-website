# Netlify Production Deploy Runbook

This repo deploys a static site (`index.html`, `owner.html`, `customer.js`, `owner.js`, `styles.css`) plus a Netlify Function (`netlify/functions/catalogue.js`).

## Recommended (GitHub → Netlify)

1) Commit and push to `master`.
2) Watch the Netlify deploy finish.
3) Verify:
   - Site: `https://demotest-website.netlify.app/`
   - Owner: `https://demotest-website.netlify.app/owner`

## Manual deploy (Netlify CLI)

If you changed `src/*.jsx` or `tailwind.input.css`, rebuild assets first:

```bash
npm ci
npm run build
```

Deploy (includes the function):

```bash
netlify deploy --prod --dir="." --functions="netlify/functions" --message "Describe the change"
```

## Required Netlify env vars (for the function)

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`

