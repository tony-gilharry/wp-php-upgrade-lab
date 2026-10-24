# Gotchas

Things to watch for when upgrading a WordPress site's PHP. Host-specific
items say which host; check your host's own documentation (linked from
[hosts/](hosts/)) because platforms change.

## PHP and plugins

1. **A static scan reports code that never runs.** On the worked example,
   PHPCompatibility found 11 errors for `mcrypt` (removed in PHP 7.2) in a
   plugin. The site ran fine on PHP 8.4 because that code path is never
   reached. The reverse also happens: runtime problems such as `null` passed
   to string functions, dynamic properties and `TypeError`s are invisible to a
   scan. Use the scan to find suspects and the crawl to confirm.
2. **"Update unavailable" usually means a requirement is not met**, most
   often PHP. Contact Form 7 6.2 requires PHP 8.3, so on PHP 7.4 WordPress
   offers no update. It is not a licensing problem.
3. **Some plugins refuse to load at all on an older PHP.** Plugins built with
   Composer ship a platform check (`vendor/composer/platform_check.php`) that
   throws before anything else runs. Deploy such a release before the PHP
   switch and the whole site returns 500. Split updates into "runs on both
   PHP versions" (ship before the switch) and "requires the new PHP" (ship
   after). The demo reproduces this in step 5.
4. **A premium plugin with a lapsed license silently stops updating.** It
   shows an old version with no update offered. Renew it, or switch to the
   free edition if you do not use the premium features (check what data the
   premium edition holds first: redirects, for example).
5. **Closed plugins get no fixes.** WordPress.org returns `closed` for them
   (`bin/plugin-audit.sh` flags it). Their CSS or JavaScript may already be
   broken on current WordPress without anyone noticing.
6. **Development builds never update.** A plugin installed from a Git
   checkout (for example a `*-develop` folder) has a slug WordPress.org does
   not know, so it gets no updates. Replace it with the released plugin.
7. **The theme counts too.** A theme edited in place loses those edits on
   update. Diff it against the pristine release of the same version first.
   Starter or custom themes need their own fixes, such as reading array keys
   that are not set (a notice on PHP 7.4, a warning on PHP 8).
8. **Old Docker images bundle old WordPress.** `wordpress:php7.4-apache`
   ships WordPress 6.1, whose own code throws deprecations on PHP 8.
   `bin/import-db.sh` installs the server's WordPress version.
9. **OPcache serves replaced files for a while.** After swapping plugin
   files in the sandbox, the next requests may still run the old code.
   `bin/demo-upgrade.sh` restarts the web container for this reason.

## WP Engine

10. **The SSH Gateway's PHP can lag the portal setting.** After a PHP switch
    the website runs the new version, but `php` and WP-CLI on the gateway
    may stay on the old one for a while (up to hours). Once a plugin that
    requires the new PHP is deployed, every WP-CLI command fails while the
    website is fine. Check the web PHP in Site Health
    (`bin/crawl-remote.sh` reports both), and if you must use WP-CLI
    meanwhile, skip that plugin: `wp --skip-plugins=<slug> ...`.
11. **WP Engine serves the repo root as the site root.** A pushed
    `docker-compose.yml` or `README.md` is downloadable from the live site.
    Deploy with `bin/deploy-wpengine.sh`, which ships `wp-content` only.
12. **The first push to an empty WP Engine repo only adds files.** Files
    deleted inside that first pushed history stay on the server. Later
    deploys delete files removed since the previous deploy, but leave empty
    directories behind.
13. **Deploy output always says "deploying to production environment"**,
    even when the remote is staging or development. Check which remote you
    pushed to.
14. **`wp config set` fails with "Unable to locate placement anchor"**
    because WP Engine's `wp-config.php` lacks the usual comment. Pass
    `--anchor="if ( !defined('ABSPATH') )" --placement=before`.
15. **Debug logs under `wp-content/` are public.** Put them in
    `_wpeprivate/`, which WP Engine does not serve, and delete them when
    done.
16. **The gateway's home directory is wiped between sessions.** Backups
    saved to `~` on the gateway are gone next time. Use the portal's backup
    points.
17. **A database copied by hand leaves the object cache stale.** Run
    `wp cache flush`, or use the portal's Copy environment, which avoids it.
18. **Gateway SSH keys belong to a portal user, not an install.** A key on
    your profile reaches every install you can access. Git push keys are per
    install. For a lab or CI key, create a portal user with access to only
    those environments.
19. **Old sites carry leftovers.** The demo site had two `hyperdb` plugin
    folders that were never loaded and use the `mysql_*` functions removed
    in PHP 7.0. Dead code like this shows up as scan errors; remove it.

20. **The SSH Gateway loses quotes inside remote commands.** It re-splits
    the command string, so `ssh env@env.ssh.wpengine.net "php -r 'echo
    PHP_VERSION;'"` arrives as `php -r echo PHP_VERSION;` and fails with a
    parse error. Send anything with quotes, parentheses or `$` as a script:
    `ssh env@env.ssh.wpengine.net 'bash -s' <<'EOF' ... EOF`.

## Process

21. **Compare against production before calling something a regression.**
    A 404 or a missing map might have been broken for years. Screenshot
    production next to the change.
22. **A 200 is not proof the page looks right.** Check key pages by eye,
    including on a phone-sized screen, and submit real forms.
23. **Test the API, not only the pages, on headless sites.** The crawlers
    send a GraphQL query when `/graphql` exists; a front end built on it
    breaks even when every page returns 200.
24. **zsh does not split words in variables.** `S="ssh host"; $S cmd`
    fails in zsh. Write the command out, or use a shell function.
