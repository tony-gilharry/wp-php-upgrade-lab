# SiteGround

Checked against SiteGround's documentation on 2026-10-23.

| Need | How | Source |
|---|---|---|
| Change PHP | Site Tools → Devs → **PHP Manager** → pencil icon → Managed PHP or a manual version | [Managed PHP](https://www.siteground.com/kb/what-is-managed-php) |
| Staging PHP | Staging copies always use "Standard PHP", which allows per-instance PHP management | [Change PHP setup](https://www.siteground.com/kb/change-php-setup/) |
| Staging | Staging tool → choose the install → Create (files and database) | [Create staging](https://www.siteground.com/tutorials/staging/create-staging) |
| Push staging → live | **Full Deploy** (files and database) or **Custom Deploy** (chosen files and tables) | [Deploy](https://www.siteground.com/tutorials/staging/deploy) |
| SSH and WP-CLI | Site Tools → Devs → SSH Keys Manager; key-based, **port 18765**, `ssh USER@HOST -p18765`; WP-CLI on all plans | [Enable SSH](https://www.siteground.com/tutorials/ssh/enable-ssh) · [Log in](https://www.siteground.com/kb/how_to_log_in_to_my_shared_account_via_ssh_in_linux) · [WP-CLI](https://www.siteground.com/tutorials/wordpress/wp-cli) |
| Deploy code | Site Tools Git tool (GoGeek and higher): a server-side repository you clone and commit back to | [SG Git](https://www.siteground.com/kb/what-is-sg-git/) · [Clone](https://www.siteground.com/tutorials/sg-git/clone-git-repository) |
| Backup | Site Tools → Security → Backups → name → **Create** (5 free manual slots on GrowBig and higher) | [Backups](https://www.siteground.com/kb/backup-service) |
| PHP log | Site Tools → Statistics → **Error Log** | [Error log](https://www.siteground.com/kb/can-export-error-logs) |

**Managed PHP.** Sites on Managed PHP move to the new server default
automatically; a manually chosen version is not auto-updated
([Managed PHP](https://www.siteground.com/kb/what-is-managed-php)). Pin the
current version manually while you test, then switch on purpose.

**PHP2Shell.** SiteGround's blog says server-level fixes for October 2026's
PHP vulnerabilities were applied
([blog](https://www.siteground.com/blog/critical-php-vulnerabilities-october-2026)).
That patches the PHP builds; it does not move a site off an unsupported
version.

**Gaps and conflicts.** The list of offered PHP versions and how to refresh
an existing staging copy from live were not found in the docs. The database
size limit for staging is 5 GB on one page (2026) and 2 GB on another (2022).
