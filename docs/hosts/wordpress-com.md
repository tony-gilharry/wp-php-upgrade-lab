# WordPress.com (Business and Commerce plans)

Checked against WordPress.com's support and developer docs on 2026-10-23.

| Need | How | Source |
|---|---|---|
| Change PHP | Hosting Dashboard → site → Settings → Server → **PHP** → version → Save. Offered: **8.3 and 8.4**. | [PHP version switching](https://wordpress.com/support/php-version-switching/) · [PHP environment](https://wordpress.com/support/php-environment/) |
| Staging | Business and Commerce: Production drop-down → "+ Add staging site" (one per site) | [Staging](https://wordpress.com/support/how-to-create-a-staging-site/) |
| Sync | Sync → **Pull from Production** / **Push to Production**: all or chosen files, optional database | [Sync](https://wordpress.com/support/how-to-create-a-staging-site/sync-staging-site/) |
| SSH and WP-CLI | Business and Commerce: Settings → SFTP/SSH → Create credentials → Enable SSH access; `ssh.wp.com`, port 22 | [SSH](https://wordpress.com/support/ssh/) · [WP-CLI](https://developer.wordpress.com/docs/developer-tools/wp-cli/) |
| Deploy code | **GitHub Deployments** (Deployments in the sidebar) | [GitHub Deployments](https://developer.wordpress.com/docs/developer-tools/github-deployments/) |
| Backup | Real-time Jetpack VaultPress backups; restore at Jetpack → Backup | [Restore](https://wordpress.com/support/restore/) |
| PHP log | Sidebar **Logs** → PHP errors (30 days) | [Site logs](https://wordpress.com/support/site-logs/) |

**PHP does not sync.** "The PHP version on your production site doesn't
automatically update to match staging"
([Sync](https://wordpress.com/support/how-to-create-a-staging-site/sync-staging-site/)).
After pushing tested code, switch production's PHP yourself.

**WordPress.com manages PHP.** "In the event an update to your site's PHP
version is required, WordPress.com updates it for you", and you cannot roll
back below the listed versions
([PHP version switching](https://wordpress.com/support/php-version-switching/)).
With 8.3 as the oldest option, the 7.4 → 8.x jump has likely been made for
you already; the lab is still useful for the 8.3 → 8.4 step.

**Conflicts in the docs.** The site-logs page says logs are available on
Personal and Premium too; the site-monitoring page says Business and
Commerce only
([monitoring](https://developer.wordpress.com/docs/troubleshooting/site-monitoring/)).
A "Back up now" button appears on the Jetpack Backup plugin page but not in
the support guides.
