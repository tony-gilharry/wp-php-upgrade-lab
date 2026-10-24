# Flywheel

Checked against Flywheel's help center on 2026-10-23. Flywheel is part of WP
Engine but has its own platform and dashboard.

| Need | How | Source |
|---|---|---|
| Change PHP | Site → **Advanced** tab (bottom right); for staging, the **Staging** tab, so the two can differ. Offered: **7.4 and 8.4 only**; new sites default to 8.4. | [PHP on Flywheel](https://getflywheel.com/wordpress-support/php-on-flywheel/) |
| Bulk PHP changes | Through support | [Growth Suite](https://getflywheel.com/wordpress-support/growth-suite-bulk-site-management/) |
| Staging | All current plans, not Multisite: toggle in the Advanced tab. **Reset Staging** copies live → staging | [Staging](https://getflywheel.com/wordpress-support/staging-on-flywheel/) |
| Push staging → live | **Move staging changes to live site**: files always; the database only if you tick "Copy staging database to production" | [Staging](https://getflywheel.com/wordpress-support/staging-on-flywheel/) |
| SSH and WP-CLI | SSH Gateway `ssh.getflywheel.com`, user `username+site-slug@…` or `username+staging+site-slug@…`; WP-CLI installed, some commands unsupported | [SSH](https://getflywheel.com/wordpress-support/ssh-key-access-and-management/) |
| Deploy code | No native Git deploy; GitHub Actions over SSH and rsync | [GitHub Actions](https://getflywheel.com/wordpress-support/deploying-to-flywheel-via-ssh-and-github-actions/) |
| Backup | Backups tab → **Create new backup** | [Backups](https://getflywheel.com/wordpress-support/backups-on-flywheel/) |
| PHP log | Advanced tab → **Export Logs** (emailed, up to 7 days); not readable over SSH | [Logs](https://getflywheel.com/wordpress-support/can-i-view-the-access-logs-and-error-logs/) |

**Watch out.**
- With only 7.4 and 8.4 on offer, an upgrade from 7.4 is a straight jump to
  8.4. Test with the sandbox on exactly those two versions.
- **Staging sites are not backed up.** Make a production backup before
  pushing anything.
- The backups page contradicts itself about scope ("everything in your
  WordPress folder" versus "only the wp-content folder, your database…").
- The logs page dates from 2023.
