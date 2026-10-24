# WP Engine

The host this lab was built on. `bin/pull-site.sh`, `bin/crawl-remote.sh`
and `bin/deploy-wpengine.sh` target WP Engine directly.

Official docs, checked 2026-10-23:
[PHP guide](https://wpengine.com/support/php-guide/) ·
[Environments](https://wpengine.com/support/environments/) ·
[Copy an environment](https://wpengine.com/support/copy-site/) ·
[SSH Gateway](https://wpengine.com/support/ssh-gateway/) ·
[Git push](https://wpengine.com/support/git/) ·
[Backups](https://wpengine.com/support/restore/) ·
[Error logs](https://wpengine.com/support/troubleshoot-wordpress-wp-engine-error-log/) ·
[Plans](https://wpengine.com/plans/)

## The platform in one screen

| Need | Where | Notes |
|---|---|---|
| Change PHP | Sites → *environment* → Overview → Updates → PHP → version → Confirm ([PHP guide](https://wpengine.com/support/php-guide/)) | Per environment. Offered: **7.4, 8.2, 8.4** (no 8.3). Not copied when you copy an environment. |
| Preview a PHP version | "PHP Test Driver" / **Preview PHP** ([PHP guide](https://wpengine.com/support/php-guide/)) | Sets a `wpengine_php` cookie so only your browser sees the new PHP. Test production before switching it. |
| Environments | Up to three per site: Development, Staging, Production ([Environments](https://wpengine.com/support/environments/)) | |
| Copy prod → staging/dev | Environment → Actions → Push to / Pull from ([Copy](https://wpengine.com/support/copy-site/)) | **Full** (all files and tables) or **Custom**. The destination is backed up before and after. |
| SSH and WP-CLI | `ENV@ENV.ssh.wpengine.net`, key authentication ([SSH Gateway](https://wpengine.com/support/ssh-gateway/)) | Keys live on a portal **user's** profile and reach every install that user can access. |
| Deploy code | `git@git.wpengine.com:ENV.git`, one remote per environment ([Git push](https://wpengine.com/support/git/)) | Keys are added per install. Use `bin/deploy-wpengine.sh`, never a direct push of a repo with tooling in it. |
| Backup | Environment → Backups → **Create backup** ([Backups](https://wpengine.com/support/restore/)) | Kept 30 days. |
| PHP error log | Environment → Logs → Error ([Logs](https://wpengine.com/support/troubleshoot-wordpress-wp-engine-error-log/)) | Last 24 to 48 hours. |
| Auto-upgrades | ([PHP guide](https://wpengine.com/support/php-guide/)) | End-of-life versions are upgraded automatically and cannot be deferred. |

The PHP guide still mentions "beta support for PHP 8.4" for WordPress 6.7 and
newer, which reads as out of date, and says the selector is in "two
locations" while documenting one.

## Rollout on WP Engine

1. **[Human, portal]** Create a backup point on production.
2. **[Human, portal]** Copy production to Development (and later to
   Staging): Actions → Push to, Full copy. Check the PHP version on the
   destination afterwards; a copy does not carry it.
3. Deploy the code that runs on **both** PHP versions:
   `bin/deploy-wpengine.sh wpe-dev <commit>`. Do any plugin swaps over WP-CLI
   (deactivate the old plugin before its files disappear).
4. Turn on a debug log in `_wpeprivate/` (never under `wp-content/`):

   ```bash
   ssh ENV@ENV.ssh.wpengine.net 'bash -s' <<'EOF'
   cd ~/sites/ENV
   A="if ( !defined('ABSPATH') )"
   wp config set WP_DEBUG true --raw --anchor="$A" --placement=before --separator="\n"
   wp config set WP_DEBUG_DISPLAY false --raw --anchor="$A" --placement=before --separator="\n"
   wp config set WP_DEBUG_LOG "$HOME/sites/ENV/_wpeprivate/debug-lab.log" --anchor="$A" --placement=before --separator="\n\n"
   php -l wp-config.php
   EOF
   ```

5. Crawl: `LOG=_wpeprivate/debug-lab.log bin/crawl-remote.sh ENV`
6. **[Human, portal]** Switch the environment's PHP. Crawl again and check
   the **web** PHP version the crawl reports.
7. Deploy the code that **requires** the new PHP, then crawl.
8. Repeat 2 to 7 on Staging, then on Production (with Preview PHP first).
9. Remove the debug lines from `wp-config.php`, delete the log, and check
   **[Human, portal]** Logs → Error the next day.

## WP Engine gotchas

From [docs/gotchas.md](../gotchas.md), items 10 to 20. In short:

- The SSH Gateway's PHP can lag the portal setting by hours, in either
  direction. WP-CLI may break while the site is fine.
- The gateway re-splits remote commands: quotes are lost. Use `bash -s`.
- The repo root is the site root: anything pushed is downloadable.
- The first push to an empty repo only adds files; deletions start with the
  second deploy, and empty directories stay behind.
- `wp config set` needs an explicit `--anchor` on WP Engine.
- The gateway's home directory does not persist between sessions.
- Old sites may carry unused `hyperdb` plugin folders; they use `mysql_*`
  and are dead code.
