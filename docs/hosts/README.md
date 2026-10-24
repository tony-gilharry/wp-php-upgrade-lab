# Managed WordPress hosts

The lab's sandbox and checks work on any WordPress site. What differs by host
is how you change PHP, copy environments, get a shell, deploy code and read
logs. Each guide below maps the [playbook](../playbook.md) steps to that
host and **links to the host's own documentation** for every step. Follow the
host's docs when they disagree with these pages: platforms change.

Facts were checked against each host's official documentation on 2026-10-23.
Where a host's own pages contradict each other, the guide says so.

| Host | PHP set per environment? | Staging | SSH + WP-CLI | Git deploy | On-demand backup |
|---|---|---|---|---|---|
| [WP Engine](wp-engine.md) | Yes; not copied with an environment | Dev, Staging, Production; full or custom copy | SSH Gateway | Native Git push | Yes |
| [Pressable](pressable.md) | Yes (staging is its own site; clones keep the version) | Yes; Transfer Data | Yes | GitHub integration | Yes (files and DB separately) |
| [GoDaddy Managed WordPress](godaddy.md) | Not explicit in the docs | Yes, except Basic; syncs `/wp-content` only | Yes, except Basic | GitHub Actions CI/CD | Yes |
| [Kinsta](kinsta.md) | Yes, **but a push overwrites the destination's PHP** | Yes; selective push | Yes, all plans | No push; `git pull` over SSH | Yes (5 manual) |
| [Flywheel](flywheel.md) | Yes | Yes, not Multisite | Yes (SSH Gateway) | No; GitHub Actions + rsync guide | Yes (production only) |
| [SiteGround](siteground.md) | Per instance | Yes; full or custom deploy | Yes (port 18765) | Git tool, GoGeek and up | Yes |
| [WordPress.com](wordpress-com.md) | Yes; not synced on push | Business and Commerce plans | Business and Commerce plans | GitHub Deployments | Real-time backups |
| [Pantheon](pantheon.md) | In `pantheon.yml`, moves with code | Test environment | No shell; WP-CLI via Terminus | Native Git to Dev | Yes |
| [Cloudways](cloudways.md) | Yes per app (public preview) | Yes | Yes | Server pulls from Git | Yes |

## What to check on any host

1. **Which PHP versions are offered**, and whether the version you need is
   one of them. WP Engine, for example, offers 7.4, 8.2 and 8.4 but not 8.3.
2. **Whether the PHP version travels with an environment copy.** It does not
   on WP Engine or WordPress.com, it always does on a Kinsta push, and on
   Pantheon it moves with each code deploy. A staging test on the new PHP
   can silently put production on it (Kinsta), or production can stay on the
   old PHP after you push tested code (WP Engine).
3. **Whether WP-CLI runs on the same PHP as the website.** Only Cloudways
   documents the difference; WP Engine shows it in practice
   ([gotcha 10](../gotchas.md)). Check `php -v` in the shell against the PHP
   version in WordPress's Site Health screen.
4. **Whether the host upgrades PHP for you.** Most auto-upgrade end-of-life
   versions on their own schedule. Plan your upgrade before theirs.
