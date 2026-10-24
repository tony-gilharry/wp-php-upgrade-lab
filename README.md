# wp-php-upgrade-lab

Move a WordPress site to a new PHP version without finding out in
production what breaks. Reproduce the site in Docker on the old and the new
PHP side by side, fix what fails, then roll out to WP Engine staging and
production in an order where every step in between still works.

Prompted by **PHP2Shell** (CVE-2026-109618 and CVE-2026-109619,
unauthenticated remote code execution in PHP 5.4 through 8.5, patched on
2026-10-21 in 8.2.35, 8.3.36, 8.4.27 and 8.5.12), but the process applies
to any PHP upgrade. It was run end to end on my own demo site on WP Engine,
from PHP 7.4 to 8.4 through development, staging and production: see the
[worked example](docs/worked-example.md).

> Not affiliated with or endorsed by WP Engine or the WordPress Foundation.
> WP Engine is the host the deployment scripts target; the sandbox and the
> checks work for any WordPress site.

## What's in the box

| | |
|---|---|
| `docker-compose.yml` | WordPress on any PHP version that has an official `wordpress:php<version>-apache` image, with debug logging on and the port bound to localhost |
| `bin/crawl-local.sh` | Fetches every published page plus the main admin screens as an administrator, then groups PHP errors by plugin. Exits non-zero on a fatal error or a non-200 page |
| `bin/compat-scan.sh` | Static scan with [PHPCompatibility](https://github.com/PHPCompatibility/PHPCompatibility) for exactly one target PHP version |
| `bin/plugin-audit.sh` | Compares every plugin with WordPress.org: closed, stale, or needs a newer PHP than you run today |
| `bin/demo-scenario.sh` | The whole upgrade story on a bundled demo site, with every step checked |
| `bin/pull-site.sh`, `bin/import-db.sh` | Bring a WP Engine site's code and database into the sandbox (both stay out of Git) |
| `bin/crawl-remote.sh` | The crawl, against a WP Engine environment over HTTPS |
| `bin/deploy-wpengine.sh` | Git push deploy that ships only `wp-content`, so repo tooling is never served from the live site |
| `bin/opsec-check.sh` | Pre-publish check: gitleaks, a private denylist, and commit identities |
| [`docs/playbook.md`](docs/playbook.md) | The process, step by step |
| [`docs/gotchas.md`](docs/gotchas.md) | What to watch for: PHP, plugins, WP Engine, process |
| [`docs/wp-engine-checklist.md`](docs/wp-engine-checklist.md) | What a person has to do or check in the WP Engine portal |

## Try it on the demo site (5 minutes)

Needs Docker, and PHP plus Composer for the static scan
(`brew install php composer` on macOS).

```bash
git clone https://github.com/tony-gilharry/wp-php-upgrade-lab.git
cd wp-php-upgrade-lab
cp .env.example .env
bin/demo-scenario.sh --fresh
```

The demo site has two plugins written to fail the way real ones do:

- **Legacy Widgets 1.0** is an abandoned-plugin stand-in. It runs on PHP 7.4
  and dies on PHP 8 (`each()` was removed), with a trail of 8.1 to 8.4
  deprecations. Version 2.0 fixes it and still runs on 7.4.
- **Modern Forms 2.0** is a maintained plugin whose new release needs
  PHP 8.3, like Contact Form 7 6.2. Like Composer-built plugins, it refuses to
  load on older PHP, which takes the whole site down if it ships too early.

`demo-scenario.sh` walks through the upgrade and checks each step:

```
################ Summary (PHP 7.4 -> 8.4)
ok        1. original plugins: pass
ok        2. original plugins: FAIL
ok        3. Legacy Widgets 2.0: pass
ok        4. Legacy Widgets 2.0: pass
ok        5. + Modern Forms 2.0 too early: FAIL
ok        6. + Modern Forms 2.0 after switch: pass
```

Steps 4 and 5 are the point. A fix that runs on **both** PHP versions can
ship before the PHP switch. A release that **requires** the new PHP has to
ship after it. Getting that order wrong is how upgrades turn into outages.

The static scan sees the same thing before anything runs:

```
$ bin/compat-scan.sh 8.4 demo/wp-content/plugins/legacy-widgets
    1  legacy-widgets | ERROR | PHPCompatibility.FunctionUse.RemovedFunctions.eachDeprecatedRemoved
    ...
$ bin/compat-scan.sh 7.4 demo/upgrades
    1  modern-forms | ERROR | PHPCompatibility.Classes.NewTypedConstants.Found
```

Run any single step yourself:

```bash
PHP_VERSION=8.4 docker compose up -d --force-recreate wordpress
PHP_VERSION=8.4 bin/crawl-local.sh
bin/demo-upgrade.sh legacy-widgets          # or --revert
```

## Use it on your own site

```bash
# .env: SITE_DIR=./site, WPE_PROD_ENV, WPE_STAGING_ENV, PROD_DOMAIN
bin/pull-site.sh                       # code -> ./site, database -> ./.local (both gitignored)
PHP_VERSION=7.4 docker compose up -d   # today's production PHP
bin/import-db.sh
CURRENT_PHP=7.4 bin/plugin-audit.sh
bin/compat-scan.sh 8.4
PHP_VERSION=7.4 bin/crawl-local.sh     # baseline
PHP_VERSION=8.4 docker compose up -d --force-recreate wordpress
PHP_VERSION=8.4 bin/crawl-local.sh     # what breaks
```

Then follow [the playbook](docs/playbook.md): update in the sandbox until
both PHP versions crawl clean, prove it on staging, and roll out to
production with the [portal checklist](docs/wp-engine-checklist.md) next to
you.

Your site's code belongs in its own private repository. Keep `./site` out of
this one (it is gitignored) and use `bin/deploy-wpengine.sh` from that repo.

## Security notes

- The sandbox holds a copy of a production database: it listens on
  `127.0.0.1` only, and dumps live in `.local/`, which is gitignored.
- On WP Engine, keep debug logs in `_wpeprivate/`. A log under `wp-content/`
  can be downloaded by anyone who guesses its name.
- Never `git push` a repo like this straight to WP Engine: it serves the repo
  root as the site root. `bin/deploy-wpengine.sh` ships `wp-content` only.
- Use a dedicated SSH key per purpose (personal, lab, CI deploy), never a
  personal key in CI.

## License

MIT. See [LICENSE](LICENSE).
