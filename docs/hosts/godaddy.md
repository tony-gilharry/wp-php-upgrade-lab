# GoDaddy Managed Hosting for WordPress

Checked against GoDaddy's help center on 2026-10-23 (the pages show no
update dates).

| Need | How | Source |
|---|---|---|
| Change PHP | My Products → Managed Hosting for WordPress → Manage All → site → Settings → **Production Site** → PHP version → Change → Save. GoDaddy recommends testing on staging first. | [Change PHP](https://www.godaddy.com/help/change-my-php-version-32202) |
| Staging | All plans except Basic. Settings → Staging Site → Create | [Staging](https://www.godaddy.com/help/set-up-a-staging-site-for-my-managed-hosting-for-wordpress-site-12292) · [Create](https://www.godaddy.com/help/create-a-staging-site-16466) |
| Copy prod → staging | Staging Site → Actions → Sync Sites → **Pull production to staging** | [Pull](https://www.godaddy.com/help/pull-my-production-site-into-the-staging-site-16465) |
| Push staging → prod | **Push staging to production** | [Push](https://www.godaddy.com/help/push-my-staging-site-to-the-production-site-16467) |
| SSH and WP-CLI | Not on Basic. Settings → Production Site → SSH/SFTP login → Create New Login → SSH Enabled (this deletes the current SFTP login). Connect to the server IP, port 22; `cd html`, then `wp`. | [Enable SSH](https://www.godaddy.com/help/enable-ssh-on-managed-hosting-for-wordpress-24596) · [Connect](https://www.godaddy.com/help/connect-to-my-managed-wordpress-server-with-ssh-secure-shell-40060) · [WP-CLI](https://www.godaddy.com/help/use-wp-cli-to-manage-your-site-12066) |
| Deploy code | GitHub Actions CI/CD: Production or Staging Site → CI/CD Integration → Enable, add an SSH key and deploy user | [CI/CD](https://www.godaddy.com/help/set-up-cicd-deployments-via-github-actions-42702) |
| Backup | Settings → Backups → **Backup Now** | [Backups](https://www.godaddy.com/help/backup-and-restore-my-managed-hosting-for-wordpress-site-9187) |
| PHP log | Settings → Site Logs → View Logs (14 days, **production only**) | [Logs](https://www.godaddy.com/help/php-error-and-access-logs-on-managed-hosting-for-wordpress-42873) |

**Watch out.**
- Sync copies **files only by default** and only `/wp-content`. Tick
  **Overwrite content** to include the database.
- Whether staging has its own PHP setting is not stated; the PHP control is
  documented under "Production Site". Confirm in your dashboard before
  relying on staging to test a different PHP version.
- Staging has no error log in the dashboard. Use the sandbox's crawl, or
  turn on `WP_DEBUG_LOG` on staging over SSH (outside the web root).
- PHP 7.4 has paid Zend extended support "until November 2026"
  ([extended support](https://www.godaddy.com/help/extended-support-for-php-version-74-with-zendphp-42017)).

**Conflicts in the docs.** Offered versions are listed as 8.1 to 8.3 plus
7.4 extended support
([recommended version](https://www.godaddy.com/help/recommended-php-version-for-wordpress-32201)),
as 7.4, 8.1, 8.2 and 8.3
([installed software](https://www.godaddy.com/help/software-versions-installed-on-web-hosting-cpanel-windows-hosting-plesk-and-managed-hosting-for-wordpress-accounts-897)),
and "8.3 is the latest" (extended support page). No page lists 8.4; check
your dashboard.
