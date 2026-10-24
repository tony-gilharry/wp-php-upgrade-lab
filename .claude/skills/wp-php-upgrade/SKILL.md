---
name: wp-php-upgrade
description: Safely upgrade a WordPress site to a newer PHP version (7.4 → 8.x, 8.2 → 8.4, or an emergency move after a PHP CVE such as PHP2Shell) on a managed host such as WP Engine, Pressable, GoDaddy, Kinsta, Flywheel, SiteGround, WordPress.com, Pantheon or Cloudways. Covers auditing plugins and themes for PHP compatibility, reproducing the site in a local Docker sandbox on the old and new PHP side by side, deciding which updates ship before and after the PHP switch, and rolling out through dev, staging and production with the checks a human must do in the host's portal. Use this whenever someone asks about upgrading or switching PHP on WordPress, whether plugins are "ready for PHP 8", what will break on a new PHP version, testing a WordPress site on a different PHP version, a host warning about end-of-life PHP, WP-CLI or a site failing after a PHP change, or deploying plugin updates to WP Engine around a PHP change, even if they never say "upgrade".
---

# WordPress PHP upgrade

Move a WordPress site to a new PHP version without discovering in production
what breaks. The method: reproduce the site locally on the old and the new
PHP, fix until both are clean, then roll out in an order where **every
intermediate state works**.

This skill drives the tooling in the `wp-php-upgrade-lab` repository
(`bin/` scripts, `docker-compose.yml`, `docs/`). Paths below are relative to
that repo. If you are not inside it, find it locally or clone
`https://github.com/tony-gilharry/wp-php-upgrade-lab`, and keep the user's
site code out of it (it goes in the gitignored `site/` folder).

## Ground rules, and why

- **The user owns anything outward-facing.** Changing PHP in a host portal,
  making backups, copying environments, and every write to production need
  the user's explicit go-ahead in this conversation. Production is a live
  business; a mistake there is not undoable the way a local one is. Prepare
  everything, then ask.
- **Both-versions rule.** Production keeps running the old PHP while new code
  arrives, and runs the new PHP before the last updates arrive. So every
  change must be tested on both PHP versions, or explicitly deferred until
  after the switch. This single rule prevents most upgrade outages.
- **Evidence over assumptions.** A static scan finds suspects; a crawl of the
  running site convicts them. Compare against production before calling
  anything a regression: things are often already broken.
- **Nothing private leaks.** Production database copies stay in `.local/`,
  site code in `site/`, real environment names in `.env`. Debug logs on a
  server go outside the web root. Never push a repo that contains tooling to
  a host that serves the repo root (WP Engine does).

## Workflow

### 1. Inventory

Find out: host, environments (WP Engine offers Development, Staging and
Production), current PHP, WordPress version, active theme, plugins with
versions and available updates, and what the site is for (brochure site,
store, headless API for a front end).

Read the host guide in `docs/hosts/<host>.md` now. It says how that host
changes PHP, copies environments, exposes SSH and WP-CLI, deploys code and
shows logs, and which PHP versions it offers. The target version must be one
the host actually offers (WP Engine: 7.4, 8.2, 8.4, no 8.3).

### 2. Audit and scan

```bash
CURRENT_PHP=7.4 bin/plugin-audit.sh   # needs SITE_DIR with the site's wp-content
bin/compat-scan.sh 8.4                # exactly one target version
```

Classify every plugin and the theme:

| Finding | Meaning | Action |
|---|---|---|
| Update supports both PHP versions | Safe to ship before the switch | Update in the sandbox, test on both |
| Update requires the new PHP (`NEEDS-PHP`, or "update unavailable" in wp-admin) | Breaks the site if it ships early | Ship after the switch |
| `CLOSED` on WordPress.org | No more fixes; may already be broken | Replace; check the pages that use it |
| `STALE` (no release in 2+ years) | Unmaintained | Test hard; plan a replacement |
| `NOT-ON-ORG` | Premium, custom, or a dev build (`*-develop`) | Premium: license may have lapsed. Dev build: swap for the released plugin |
| Theme | Edited in place? | Diff against the pristine release before updating |

### 3. Sandbox

```bash
bin/pull-site.sh                       # code -> site/, database -> .local/ (WP Engine)
PHP_VERSION=<current> docker compose up -d
bin/import-db.sh                       # also installs the server's WordPress core version
PHP_VERSION=<current> bin/crawl-local.sh
PHP_VERSION=<target> docker compose up -d --force-recreate wordpress
PHP_VERSION=<target> bin/crawl-local.sh
```

The crawl fetches every published URL plus the main admin screens as an
administrator and sends a GraphQL query if `/graphql` exists (headless sites
depend on it more than on pages). It exits non-zero on a fatal error or a
non-200 response, and groups PHP errors by plugin or theme.

Reading the results:
- **Fatal errors and 500s** block the upgrade.
- **Warnings** usually point at real bugs (often a theme indexing arrays that
  no longer have the expected keys).
- **Deprecations** do not break anything yet. Note them; fix what is yours.
  Deprecations inside a maintained plugin's latest release are upstream's.
- **Static-scan errors that never show up in the crawl** are usually dead
  code paths. Say so instead of treating them as blockers.
- **Deprecations from `wp-includes/`** mean the sandbox runs an old
  WordPress core; re-run `bin/import-db.sh` so core matches the server.

### 4. Fix in the sandbox

Update plugins with WP-CLI inside the sandbox
(`docker compose run --rm cli wp plugin update <slug>`), swap dev builds for
released plugins, fix theme code, and crawl on **both** PHP versions after
every change. After replacing files, restart the web container: OPcache keeps
serving old code for a while.

Commit in the site's own repository, split by when each change can deploy:

1. Changes that run on both PHP versions (deploy before the switch).
2. Removals of dead or replaced plugins (after they are deactivated on the
   server).
3. Changes that require the new PHP (deploy after the switch).

Database-side changes (activating or deactivating plugins, converting page
content away from a closed block plugin) do not travel with Git. Script them
with WP-CLI, rehearse them on staging, and take before-and-after screenshots.

### 5. Rollout: dev → staging → production

For each environment, in this order:

1. **[User]** Back up (production always), and refresh the environment from
   production with the host's copy feature.
2. Deploy the both-versions commits (`bin/deploy-wpengine.sh <remote> <commit>`
   on WP Engine; see the host guide elsewhere). Do the WP-CLI swaps.
3. Turn on a debug log outside the web root, crawl
   (`LOG=_wpeprivate/debug-lab.log bin/crawl-remote.sh <env>` on WP Engine).
4. **[User]** Switch PHP in the portal. On WP Engine, try **Preview PHP**
   on production first: a cookie lets only the user's browser see the new
   version.
5. Crawl again. Confirm the **web** PHP version (Site Health), not the
   shell's: they can differ for hours.
6. Deploy the new-PHP-only commits. Crawl.
7. **[User]** Check key pages by eye, including on a phone-sized screen,
   and submit real forms. A 200 does not mean the page looks right.

Afterwards: remove debug settings, delete logs, delete leftover plugin and
theme folders (deploys may not), and check the host's error log the next
day.

How environments copy PHP differs by host, and it changes the plan: WP
Engine and WordPress.com do not carry the PHP version with a copy, a Kinsta
push always overwrites the destination's PHP, Pantheon sets PHP in
`pantheon.yml` so it deploys with code. Read the host guide before step 1.

## Gotchas worth knowing

Read `docs/gotchas.md` for the full list. The costliest:

- **WP-CLI fails but the site is fine.** The shell's PHP lags the website's
  after a switch (WP Engine), or follows the server default (Cloudways). A
  plugin that requires the new PHP then breaks every WP-CLI call. Diagnose
  with `php -v` versus Site Health; work around with
  `wp --skip-plugins=<slug>`.
- **WP Engine's SSH Gateway loses quotes in remote commands.** Send anything
  with quotes, parentheses or `$` as a script: `ssh env@env.ssh.wpengine.net
  'bash -s' <<'EOF' ... EOF`.
- **WP Engine serves the repo root.** A pushed `docker-compose.yml` was
  downloadable from a live site. Deploy `wp-content` only.
- **The first push to an empty WP Engine repo only adds files.** Deletions
  apply from the second deploy on, and empty directories stay behind.
- **`wp-content/debug.log` is public.** On WP Engine use `_wpeprivate/`.
- **A Composer platform check takes the whole site down** if a plugin that
  requires the new PHP is deployed before the switch.
- **Gateway SSH keys belong to a portal user** and reach every install that
  user can access. Use a separate user and key for labs and CI.

## Report

When asked for a plan or a readiness assessment, use this structure:

```markdown
# PHP <current> → <target> readiness: <site or environment>

## Verdict
One paragraph: can it go, what blocks it, and the order.

## Findings
| Component | Version now → target | PHP <current> | PHP <target> | Action | Ships |
(Ships = before the switch / after the switch / remove / replace)

## Rollout
Numbered steps per environment, each marked [User] or [Claude], ending with
the checks a person must do in the host's portal.

## Risks and unknowns
What was not tested (forms, payments, cron, front ends) and how to check it.
```
