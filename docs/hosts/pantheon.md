# Pantheon

Checked against Pantheon's documentation on 2026-10-23.

| Need | How | Source |
|---|---|---|
| Change PHP | Set `php_version` in **`pantheon.yml`**; it is deployed with your code. View the current version at Dashboard → Settings → PHP version. | [pantheon.yml](https://docs.pantheon.io/pantheon-yml) · [PHP versions](https://docs.pantheon.io/guides/php/php-versions) |
| Offered | Fully supported: 8.2 to 8.5. PHP 7.4 stops being sold on 2026-12-31. | [PHP](https://docs.pantheon.io/guides/php) |
| Staging | The **Test** environment. Code moves up (Dev → Test → Live); content moves down. When deploying to Test, tick "Pull files and the database from the Live environment". | [Pantheon workflow](https://docs.pantheon.io/pantheon-workflow) |
| SSH and WP-CLI | **No shell over SSH.** WP-CLI through Terminus: `terminus remote:wp <site>.<env> -- <command>` | [SSH keys](https://docs.pantheon.io/ssh-keys) · [WP-CLI](https://docs.pantheon.io/guides/wp-cli) · [remote:wp](https://docs.pantheon.io/terminus/commands/remote-wp) |
| Deploy code | Native Git to Dev: Dev tab → Git mode → Clone with Git | [Git](https://docs.pantheon.io/guides/git/git-config) |
| Backup | Backups → **Create New Backup** per environment, or `terminus backup:create` | [Create backups](https://docs.pantheon.io/guides/backups/create-backups) |
| PHP log | `php-error.log` over SFTP, per environment | [Logs](https://docs.pantheon.io/guides/logs-pantheon) |

**PHP is code here.** Because `php_version` lives in `pantheon.yml`, the PHP
switch is a commit that travels Dev → Test → Live like any other. That makes
the lab's ordering natural:

1. Deploy code that runs on both PHP versions to Live.
2. Commit the `php_version` change and deploy it through Dev → Test → Live,
   crawling each environment.
3. Deploy code that requires the new PHP.

Multidev has caveats, and hotfix changes to `pantheon.yml` are not detected
([PHP versions](https://docs.pantheon.io/guides/php/php-versions)).

**Auto-upgrades.** Removed versions are upgraded to the oldest available
version. 8.0 and 7.x were due for removal on 2026-09-30; the page shows a
grace period ([PHP](https://docs.pantheon.io/guides/php)).

**Lab mapping.** `bin/crawl-remote.sh` needs a shell; on Pantheon, crawl the
environment URLs directly and read `php-error.log` over SFTP.
