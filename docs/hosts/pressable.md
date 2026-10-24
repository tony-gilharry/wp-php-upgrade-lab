# Pressable

Checked against Pressable's knowledge base on 2026-10-23.

| Need | How | Source |
|---|---|---|
| Change PHP | my.pressable.com → site → **PHP Version** dropdown; applies immediately. Per site; a staging site is its own site, and clones keep the source's PHP. | [Change PHP version](https://pressable.com/knowledgebase/how-to-change-your-php-version/) · [PHP FAQ](https://pressable.com/knowledgebase/php-update-faqs/) |
| Default for new sites | Account → Settings → Sites → Default PHP Version | [Account-level PHP](https://pressable.com/knowledgebase/change-account-level-php-version-for-new-sites/) |
| Staging | Site Actions → **Clone Site** → "Clone as Staging Site" (up to 20, not counted toward the site limit) | [Clone to staging](https://pressable.com/knowledgebase/how-to-clone-website-to-staging/) |
| Push / sync | Site Overview → Environments → settings → **Transfer Data**: full or selected; overwrites the destination, both sites backed up first | [Staging to production](https://pressable.com/knowledgebase/pushing-staging-to-production/) |
| SSH and WP-CLI | Credentials under Sites → site → Collaborators; `ssh <ssh-username>@ssh.pressable.com`; WP-CLI preinstalled | [SSH](https://pressable.com/knowledgebase/connect-to-ssh-on-pressable/) · [WP-CLI](https://pressable.com/knowledgebase/how-to-use-wp-cli/) |
| Deploy code | GitHub integration deploys on push to a chosen branch | [Deploy from GitHub](https://pressable.com/knowledgebase/deploy-from-github/) |
| Backup | Backups & Restores → On-demand Backups (files and database separately, 3 of each) | [Backups](https://pressable.com/knowledgebase/accessing-backups/) |
| PHP log | Site → **Logs** → PHP Logs, or `wp php-errors` | [Error logs](https://pressable.com/knowledgebase/accessing-wordpress-error-logs/) |

**PHP policy.** Each December Pressable retires the version leaving support
and upgrades sites still on it ([PHP version policy](https://pressable.com/knowledgebase/php-version-policy/));
the FAQ says 8.2 retires on 2026-12-08. The API documentation mentions
upgrades being rolled back automatically when checks fail
([API](https://my.pressable.com/documentation/api/v1)). Pressable also
publishes an MCP-assisted PHP rollout guide
([MCP guide](https://pressable.com/knowledgebase/using-mcp-to-safely-test-and-roll-out-php-version-updates-on-pressable/)).

**Conflicts in the docs.** Offered versions differ between pages: 8.2 to 8.4
([platform considerations](https://pressable.com/knowledgebase/service-platform-considerations/)),
8.1 to 8.4 "as of July 2025" (version policy), and 8.3 to 8.5 (API). Check the
dropdown. The SSH page's PuTTY steps say `sftp.pressable.com` where the rest
says `ssh.pressable.com`.

**Lab mapping.** Use `bin/crawl-local.sh` and the scans as usual. For the
remote crawl, `bin/crawl-remote.sh` assumes WP Engine's SSH layout; crawl the
staging URL with the same checks by hand, or adapt `remote()` in
`bin/lib.sh`.
