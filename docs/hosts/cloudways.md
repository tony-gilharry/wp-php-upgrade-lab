# Cloudways (Flexible)

Checked against Cloudways' support center on 2026-10-23 (no page dates
shown).

| Need | How | Source |
|---|---|---|
| Change PHP | Application → Application Settings → **PHP Settings** → edit → version → Proceed. Per-application PHP is in **public preview** on servers launched from 2026-08-08. | [Per-app PHP](https://support.cloudways.com/en/articles/16145921-how-to-change-the-php-version-for-a-specific-application-on-cloudways) · [Upgrade PHP](https://support.cloudways.com/en/articles/5121564-how-to-upgrade-php-version-on-cloudways) |
| Offered | 7.4 to 8.4 (8.4 on Flexible only), default 8.2 | [Upgrade PHP](https://support.cloudways.com/en/articles/5121564-how-to-upgrade-php-version-on-cloudways) |
| Staging | All plans: Staging Management → Launch Staging Application → "Create as Staging". Push files and/or database (overwrite or incremental); Pull copies live into staging. | [Staging](https://support.cloudways.com/en/articles/5124886-how-to-create-a-staging-environment) |
| SSH and WP-CLI | All plans; master credentials by default, application credentials need SSH enabled; your IP must be whitelisted | [SSH/SFTP](https://support.cloudways.com/en/articles/5119485-guide-to-connecting-to-your-application-using-ssh-sftp) |
| Deploy code | Deployment via Git: the server pulls a branch from your repository's SSH URL | [Git](https://support.cloudways.com/en/articles/5124087-how-to-deploy-code-to-your-application-using-git-on-cloudways-flexible) |
| Backup | Application → **Take Backup Now** (`public_html`, `private_html`, database) | [Backup](https://support.cloudways.com/en/articles/5123364-how-to-backup-a-specific-application) |
| PHP log | Monitoring → Logs → Access/Error (last 1,000 entries); older ones in the app's `logs` folder | [Logs](https://support.cloudways.com/en/articles/5126359-how-to-view-application-logs-using-the-cloudways-platform) |

**WP-CLI can run the wrong PHP.** With per-application PHP, a bare `wp` or
`php` in cron or the master crontab "resolves to … the server default PHP
version, not the application's"
([Per-app PHP](https://support.cloudways.com/en/articles/16145921-how-to-change-the-php-version-for-a-specific-application-on-cloudways)).
Use `WP_CLI_PHP=/usr/bin/phpX.Y wp …` or the application's `.cw/bin/wp`.
This is the same class of problem as WP Engine's gateway lag
([gotcha 10](../gotchas.md)): always compare the shell's `php -v` with Site
Health.

**Conflicts in the docs.** The PHP upgrade page does not list 8.5.
