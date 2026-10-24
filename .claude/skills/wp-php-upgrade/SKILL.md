---
name: wp-php-upgrade
description: Plan, test and roll out a PHP version upgrade for a WordPress site (7.4 → 8.x, 8.2 → 8.4, or an emergency move after a PHP security advisory such as PHP2Shell) with the wp-php-upgrade-lab repo. Audits plugins and themes, runs the site in Docker on the old and new PHP side by side, decides which updates ship before or after the switch, and rolls out dev → staging → production. In depth for WP Engine, with guides for Kinsta, Pressable, GoDaddy, Flywheel, SiteGround, WordPress.com, Pantheon and Cloudways. Use whenever someone asks about upgrading or switching a WordPress site's PHP, whether plugins or a theme are "ready for PHP 8", a host or Site Health warning about outdated or end-of-life PHP, testing WordPress on another PHP version, or WP-CLI, a critical error or a Composer platform check failing after a PHP change, even if they never say "upgrade". Not for PHP apps outside WordPress or plugin updates with no PHP change.
---

# WordPress PHP upgrade

Move a WordPress site to a new PHP version without discovering in production
what breaks. The method: reproduce the site locally on the old and the new
PHP, fix until both are clean, then roll out in an order where **every
intermediate state works**.

**Not every request needs the whole workflow.** For a single question (a
WP-CLI error after a switch, how a host copies PHP between environments,
whether a deploy order is safe), answer from the ground rules below,
`docs/gotchas.md` and the host's guide in `docs/hosts/`, and cite the host's
own documentation linked there.

## Where the tooling lives

This skill drives the `wp-php-upgrade-lab` repository (`bin/` scripts,
`docker-compose.yml`, `docs/`). Run commands from its root; paths below are
relative to it. To find it: use the current directory if it has
`bin/crawl-local.sh`; otherwise resolve this skill's base directory
(`readlink -f` if it is a symlink) and go two levels up from `.claude/skills/`;
otherwise ask the user. If there is no copy, ask before cloning
`https://github.com/tony-gilharry/wp-php-upgrade-lab`, then
`cp .env.example .env`.

The lab repo is **public**. The user's site never enters its Git history: the
site's code goes in the gitignored `site/` folder (or `SITE_DIR` points at the
site's own checkout), and it is committed and deployed from **the site's own
private repository**. Never add a host remote to the lab repo or force-add
`site/`.

Prerequisites: Docker; local `php` and `composer` for the scan; `jq`.

## Ground rules, and why

- **The user owns anything outward-facing.** Changing PHP in a host portal,
  backups and environment copies are the user's to do. Any command that
  changes a remote environment (a deploy, a `wp-config.php` edit, a WP-CLI
  write, a `bin/wpe-api.sh` backup or copy) needs a go-ahead in this
  conversation; on production, ask before each one and show the exact
  command. Production is a live business; a mistake there is not undoable the
  way a local one is. Prepare everything, then ask.
- **Both-versions rule.** Production keeps running the old PHP while new code
  arrives, and runs the new PHP before the last updates arrive. So every
  change must be tested on both PHP versions, or explicitly deferred until
  after the switch. This single rule prevents most upgrade outages.
- **Evidence over assumptions.** A static scan finds suspects; a crawl of the
  running site convicts them. Compare against production before calling
  anything a regression: things are often already broken.
- **Nothing private leaks.** Production database copies stay in `.local/`,
  site code in `site/`, real environment names in `.env`. Debug logs on a
  server go outside the web root. Before publishing anything derived from
  this work, follow `docs/opsec/process.md`.

## Workflow

### 1. Inventory

Find out: host, environments (WP Engine offers Development, Staging and
Production), current PHP, WordPress version, active theme, plugins with
versions and available updates, and what the site is for (brochure site,
store, headless API for a front end). On WP Engine with API credentials,
`bin/wpe-api.sh installs` lists every environment and its portal PHP setting
(read-only).

Read the host guide in `docs/hosts/<host>.md` now. It says how that host
changes PHP, copies environments, exposes SSH and WP-CLI, deploys code and
shows logs, and which PHP versions it offers. The target version must be one
the host actually offers (WP Engine: 7.4, 8.2, 8.4, no 8.3). For a host
without a guide, or a self-managed server, work through "What to check on any
host" in `docs/hosts/README.md`.

### 2. Get the site, audit and scan

```bash
cp .env.example .env          # SITE_DIR=./site, WPE_PROD_ENV, PROD_DOMAIN, TABLE_PREFIX
bin/pull-site.sh              # WP Engine: code -> site/, database -> .local/
CURRENT_PHP=<current> bin/plugin-audit.sh
bin/compat-scan.sh <target>   # exactly one target version
```

Check `SITE_DIR` first: it defaults to `./demo`, so if it is missing the audit
and scan run on the bundled demo site without any error.

Other hosts: copy themes, plugins and must-use plugins into
`site/wp-content` and a database export into `.local/` as the host guide
describes, write the server's `wp core version` to `.local/<name>.wp-version`,
and pass the dump path to `bin/import-db.sh` in step 3.

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
PHP_VERSION=<current> docker compose up -d
PHP_VERSION=<current> bin/import-db.sh          # matches core to the server's version
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
- **"WP-CLI cannot load this site"** means a plugin refuses to load on that
  PHP: it is a ship-after-the-switch change.

For a realistic end-to-end run, see `docs/worked-example.md`.

### 4. Fix in the sandbox

Update plugins with WP-CLI on the **current** PHP, so WP-CLI does not install
a release the current PHP cannot run:
`PHP_VERSION=<current> docker compose run --rm cli wp plugin update <slug>`
(pin `--version=<x>` when the latest release needs the new PHP). Swap dev
builds for released plugins, fix theme code, and crawl on **both** PHP
versions after every change. After replacing files,
`docker compose restart wordpress`: OPcache keeps serving old code for a
while.

Commit in the site's own repository (the checkout `SITE_DIR` points at; if
the site has none, `git init` inside `site/`, which the lab ignores), split
by when each change can deploy:

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
   production with the host's copy feature. Check its PHP version afterwards.
2. **[User approves on production]** From the site's repository, deploy group
   1 (`<lab>/bin/deploy-wpengine.sh <remote> <commit>` on WP Engine; other
   hosts: see the guide). Do the WP-CLI plugin swaps, then deploy group 2.
3. **[User approves on production]** Turn on a debug log outside the web
   root. On WP Engine use the `bash -s` snippet in `docs/hosts/wp-engine.md`:
   `wp config set` needs `--anchor` there, and the gateway drops quotes from
   inline commands. Crawl:
   `LOG=_wpeprivate/debug-lab.log bin/crawl-remote.sh <env>`.
4. On production, preview the new PHP before switching if the host can. On
   WP Engine: `PREVIEW_PHP=<target> LOG=_wpeprivate/debug-lab.log
   bin/crawl-remote.sh <prod-env>`; the web-PHP line in its report confirms
   the preview took effect.
5. **[User]** Switch PHP in the portal.
6. Crawl again. Confirm the **web** PHP version (Site Health), not the
   shell's: they can differ for hours. If `crawl-remote.sh` says WP-CLI
   returned nothing, the gateway is lagging; check the site in a browser
   before treating it as an outage.
7. **[User approves on production]** Deploy group 3. Crawl.
8. **[User]** Check key pages by eye, including on a phone-sized screen,
   and submit real forms. A 200 does not mean the page looks right.

Afterwards: remove debug settings, delete logs, delete leftover plugin and
theme folders and empty directories (deploys may not), and check the host's
error log the next day.

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
Numbered steps per environment, each marked [User], [User approves] or
[Claude], ending with the checks a person must do in the host's portal.

## Risks and unknowns
What was not tested (forms, payments, cron, front ends) and how to check it.
```
