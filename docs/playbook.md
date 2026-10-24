# Playbook: upgrade a WordPress site's PHP version

The process behind the lab, for any host. Your host's guide in
[hosts/](hosts/README.md) maps each step to that platform and links to its
documentation. [gotchas.md](gotchas.md) lists what went wrong on real
upgrades. The [worked example](worked-example.md) shows every step on a real
site.

Steps marked **[Human]** are actions a person takes or approves, usually in
the host's dashboard. Everything else runs from a terminal in this repo.

## The rule that prevents outages

Production keeps running the **old** PHP while new code arrives, and runs
the **new** PHP before the last updates arrive. So every change is either:

- **tested on both PHP versions** and shipped before the switch, or
- **deferred until after the switch**, because it requires the new PHP.

Nothing else is safe to deploy.

## 0. Prepare

- Docker, PHP and Composer locally (`brew install php composer` on macOS),
  `jq`, and a Git host for the site's code.
- SSH access to the host. Use a dedicated key per purpose (personal, lab,
  CI), never a personal key in automation.
- The site's code in its **own private repository**. Track `wp-content`
  themes, plugins and your own must-use plugins; ignore core, uploads,
  caches, `wp-config.php` and the host's platform plugins.
- `cp .env.example .env` and fill in the environment names. `.env` is
  gitignored.

## 1. Inventory

Record PHP version, WordPress version, active theme, every plugin with its
version and available update, and what the site does (brochure site, store,
API for a separate front end). Check which PHP versions **your host offers**:
not every host offers every version.

```bash
bin/pull-site.sh                 # WP Engine: code -> site/, database -> .local/
CURRENT_PHP=7.4 bin/plugin-audit.sh
```

| Flag | Meaning | Usually |
|---|---|---|
| `NEEDS-PHP` | Latest release needs a newer PHP than you run | Ship after the switch |
| `CLOSED` | Removed from WordPress.org: no more fixes | Replace |
| `STALE` | No release in two years | Test hard, plan a replacement |
| `NOT-ON-ORG` | Premium, custom or a development build | Check license; swap dev builds for releases |

Diff the theme against its pristine release if it came from a theme vendor,
so an update does not wipe local edits.

## 2. Static scan

```bash
bin/compat-scan.sh 8.4
```

Finds removed functions, syntax and extensions. It reports code paths that
never run (treat errors as suspects, not verdicts) and misses runtime
problems such as `null` passed to string functions. Step 3 settles both.

## 3. Sandbox on both PHP versions

```bash
PHP_VERSION=7.4 docker compose up -d
bin/import-db.sh                       # also installs the server's WordPress core
PHP_VERSION=7.4 bin/crawl-local.sh     # baseline
PHP_VERSION=8.4 docker compose up -d --force-recreate wordpress
PHP_VERSION=8.4 bin/crawl-local.sh     # what breaks
```

The crawl requests every published page, the main admin screens as an
administrator, and the GraphQL endpoint if there is one. It fails on any
fatal error or non-200 response and groups PHP errors by plugin and theme.

## 4. Fix until both are clean

Update plugins with WP-CLI inside the sandbox, replace closed or abandoned
ones, fix theme code, and crawl on **both** versions after each change.
Restart the web container after swapping files (OPcache).

Commit in three groups:

1. Changes that run on both versions (deploy before the switch).
2. Removals of replaced plugins (after they are deactivated on the server).
3. Changes that require the new PHP (deploy after the switch).

Plugin activation and page content live in the database, not in Git. Script
those changes with WP-CLI and rehearse them on staging.

## 5. Each environment: development, staging, production

1. **[Human]** Back up. Refresh the environment from production with the
   host's copy feature, then check its PHP version: many hosts do not copy
   it, and some (Kinsta) always push it.
2. Deploy group 1. Do the WP-CLI plugin swaps. Deploy group 2.
3. Turn on a debug log outside the web root and crawl.
4. On production, preview the new PHP first if your host can (WP Engine's
   Preview PHP: `PREVIEW_PHP=8.4 bin/crawl-remote.sh <env>`).
5. **[Human]** Switch PHP.
6. Crawl. Confirm the **web** PHP version in Site Health; the shell's PHP can
   lag for minutes to hours.
7. Deploy group 3. Crawl.
8. **[Human]** Look at key pages, on a phone-sized screen too, and submit
   real forms. A 200 is not proof a page looks right.

## 6. Clean up

- Remove the debug settings and delete the log.
- Delete plugin and theme folders the deploys left behind.
- **[Human]** Check the host's PHP error log the next day.
- Write down what you found for the next upgrade.
