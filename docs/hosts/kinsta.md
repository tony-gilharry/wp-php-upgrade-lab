# Kinsta

Checked against Kinsta's documentation on 2026-10-23.

| Need | How | Source |
|---|---|---|
| Change PHP | Sites → site → Tools → PHP settings → **Change**. Bulk: Sites → Actions → Change PHP settings. Per environment. Offered: 7.4 to 8.5. | [Update PHP](https://kinsta.com/docs/wordpress-hosting/php/wordpress-restart-update-php/) · [PHP](https://kinsta.com/docs/wordpress-hosting/php/) · [8.5 changelog](https://kinsta.com/changelog/php-8-5-available/) |
| Staging | Live → Create new environment → Standard (free) or Premium; clone an existing environment | [Staging](https://kinsta.com/docs/wordpress-hosting/staging-environment/) |
| Push | Staging → live, live → staging, or between sites; selective push of files, database, folders or tables | [Push environments](https://kinsta.com/docs/wordpress-hosting/wordpress-push-environments/) |
| SSH and WP-CLI | All Managed WordPress plans. Sites → site → Info → SFTP/SSH; `ssh user@IP -p PORT` (each environment has its own port); WP-CLI v2 installed | [SSH](https://kinsta.com/docs/wordpress-hosting/connect-to-ssh/) · [WP-CLI](https://kinsta.com/docs/wordpress-hosting/site-management/wordpress-wp-cli/) |
| Deploy code | No `git push kinsta`; `git pull` over SSH | [Git](https://kinsta.com/docs/wordpress-hosting/site-management/git/) |
| Backup | Backups → Manual → **Back up now** (up to 5, kept at least 14 days) | [Backups](https://kinsta.com/docs/wordpress-hosting/wordpress-backups-and-disaster-recovery/wordpress-backups/) |
| PHP log | Sites → site → **Logs** → `error.log` (up to 4 days) | [Server logs](https://kinsta.com/docs/wordpress-hosting/wordpress-troubleshooting/view-server-logs/) |

**The trap: a push carries PHP.** "Redirects, geolocation, PHP, and Nginx
configurations are always included" in a push and overwrite the destination
([Push environments](https://kinsta.com/docs/wordpress-hosting/wordpress-push-environments/)).
If staging runs PHP 8.4 to test the upgrade and you push staging to live,
**live switches to 8.4 with that push**, including any plugin that requires
it. That breaks the lab's ordering (ship the both-versions code first, switch
PHP, then ship the new-PHP-only code) unless you plan for it:

- Push code that runs on both versions while staging is still on the old PHP,
  or
- treat the staging → live push as the PHP switch itself: back up first,
  and only push once staging is fully tested on the new PHP.

**Automatic updates.** On by default: a site is upgraded when its PHP reaches
end of life. Choosing an LTS version (7.4 or 8.0) turns automatic updates
off ([Update PHP](https://kinsta.com/docs/wordpress-hosting/php/wordpress-restart-update-php/) ·
[EOL changelog](https://kinsta.com/changelog/end-of-life-php-support/)). The
front end stays up during a switch; wp-admin may drop for a few seconds.

**Conflicts in the docs.** The update page still says "the latest officially
supported PHP version is 8.1"; the PHP overview and changelog list up to 8.5.
