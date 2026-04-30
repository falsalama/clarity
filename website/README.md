# Clarity Website

Static public site for App Store support, privacy, and terms URLs.

The site is plain HTML/CSS with no analytics, no external fonts, no build step, and Cloudflare Pages security headers.

## Recommended Hosting

Use Cloudflare Pages because the domain is already managed in Cloudflare.

Suggested Cloudflare Pages settings:

- Framework preset: `None`
- Build command: leave blank
- Build output directory: `website`
- Root directory: repository root
- Production branch: `main`

After the first deploy, add the custom domain:

- `clarityapp.uk`
- `www.clarityapp.uk`

Then set Cloudflare Email Routing:

- `support@clarityapp.uk` -> your real support inbox

## App Store URLs

- Privacy Policy URL: `https://clarityapp.uk/privacy`
- Support URL: `https://clarityapp.uk/support`
- Terms URL: `https://clarityapp.uk/terms`
