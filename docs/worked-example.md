# Worked example: a headless WordPress site, PHP 7.4 → 8.4 on WP Engine

A real demo site, upgraded with this lab through local Docker, then WP
Engine's Development, Staging and Production environments. The site's
theme and plugins are in [`examples/headless-wp/`](../examples/headless-wp/),
and the two commits there show the site **as found** and **after the
upgrade**, so the whole change can be read as a diff.

## The site

A headless WordPress install serving content to a Gatsby front end through
GraphQL. On production:

| | |
|---|---|
| PHP | 7.4 |
| WordPress | 7.1.3 |
| Theme | "Travel Agency", a Bootstrap theme exported from Pinegrow |
| WPGraphQL | `wp-graphql-develop` **0.10.3**, a development build installed from Git |
| WP Gatsby | **0.4.13** |

For a headless site the API is the product: every crawl here also sends a
GraphQL query and requires real data back.

## 1. Audit and scan

```
$ CURRENT_PHP=7.4 bin/plugin-audit.sh
PLUGIN              INSTALLED  LATEST  NEEDS PHP  UPDATED     FLAGS
wp-gatsby           0.4.13     2.3.3   7.3        2022-05-04  STALE
wp-graphql-develop  0.10.3     -       -          -           NOT-ON-ORG
```

- WP Gatsby's last release was in May 2022: effectively unmaintained.
- The WPGraphQL folder is a development build. WordPress.org does not know
  the slug `wp-graphql-develop`, so it has never been offered an update. The
  released plugin, `wp-graphql`, was at 2.25.0.

```
$ bin/compat-scan.sh 8.4 <plugins and active theme>
TOTAL for PHP 8.4: 20 errors, 49 warnings
```

Eleven of the errors were `mcrypt` calls in WP Gatsby (removed from PHP in
7.2), two were `mysql_*` calls in WPGraphQL's bundled code. The theme
scanned clean.

## 2. Sandbox, before

The site's code and database were pulled into the sandbox
(`bin/pull-site.sh`, `bin/import-db.sh`, which also installed WordPress
7.1.3 to match production).

| Sandbox | Pages | GraphQL | PHP log |
|---|---|---|---|
| PHP 7.4 | all 200 | ok | 18 notices |
| PHP 8.4 | all 200 | ok | **6 warnings**, 14 deprecations |

Two lessons in that table:

- **None of the 20 static-scan errors fired.** The `mcrypt` and `mysql_*`
  code is never reached. The scan found suspects; the crawl cleared them.
- **The real bug was in the theme.** `Undefined array key 0` in its nav
  walker, six times per request. A notice on PHP 7.4 that nobody had seen,
  a warning on PHP 8.

## 3. The upgrade

One commit, [`Worked example: upgrade the headless site for PHP 8.4`](../examples/headless-wp/):

- Replace the WPGraphQL development build with **WPGraphQL 2.25.0** from
  WordPress.org.
- Update **WP Gatsby 0.4.13 → 2.3.3**.
- Fix the theme: it indexed the output of `array_filter()` from 0, but
  `array_filter()` keeps the original keys. Walk the keys that exist:

```diff
-        for($i = 0; $i < count($classes); $i++) {
-            if($classes[$i] == 'current-menu-item') {
-                $classes[$i] = self::$options['current_class'];
+        foreach ( $classes as $key => $class ) {
+            if ( 'current-menu-item' === $class ) {
+                $classes[ $key ] = self::$options['current_class'];
```

| Sandbox | Pages | GraphQL | PHP log |
|---|---|---|---|
| PHP 7.4 | all 200 | ok | clean |
| PHP 8.4 | all 200 | ok | 1 deprecation, inside WPGraphQL 2.25.0 itself |

The remaining deprecation is upstream and deliberate: WPGraphQL's own code
comment says fixing it would be a breaking change. Every change runs on
both PHP versions, so all of it ships **before** the PHP switch.

## 4. Rollout on WP Engine

The same sequence on each environment, with the private debug log in
`_wpeprivate/` turned on for every crawl:

1. Deploy the "as found" commit (the first push to an empty WP Engine repo
   only adds files, so this sets the baseline later deploys delete from).
2. Deactivate the development build (it cannot run beside the released
   plugin: same class names).
3. Deploy the upgrade, activate WPGraphQL, flush the cache.
4. Crawl on PHP 7.4.
5. Switch PHP (in the portal), crawl on PHP 8.4.

| Environment | PHP 7.4, upgraded | PHP 8.4 | Notes |
|---|---|---|---|
| Development | 15/15, GraphQL ok, log clean | 15/15, GraphQL ok, log clean | The gateway's CLI reported PHP 8.4 while the web ran 7.4: the lag works both ways |
| Staging | 15/15, GraphQL ok, log clean | 15/15, GraphQL ok, log clean | Preview PHP 8.4 (cookie) matched the real switch. The switch took about two minutes to reach the web server |
| Production | 15/15, GraphQL ok, log clean | 15/15, GraphQL ok, log clean | Previewed on 8.4 with the `wpengine_php` cookie before the switch: also clean. Eight hours after the switch the gateway's CLI still ran PHP 7.4 |

After the rollout: debug settings and logs removed on all three
environments, and the development build's folder, which the deploy had
emptied but left behind as 45 empty directories, deleted.

## What it took

- Two commits in the site's code: as found, and the upgrade. The PHP
  switch itself is a portal setting, not code.
- One real bug fixed (the theme), two plugins replaced or updated, zero
  failed requests on any environment.
- The checks a person did in the portal: backups, the environment copy, and
  each PHP switch.
