#!/bin/bash
# Crawl the sandbox: every published page and post plus key admin screens, then
# summarize HTTP status and the PHP errors in the sandbox's debug log
# (/tmp/wp-debug.log in the web container, outside the document root).
#   PHP_VERSION=8.4 bin/crawl-local.sh
# Exit status: 0 when every URL returns 200 and PHP logged no fatal errors.
# Results are kept in .local/crawl/ (gitignored).
. "$(dirname "$0")/lib.sh"

BASE="http://localhost:$LAB_PORT"
OUT=.local/crawl
mkdir -p "$OUT"
LOG=/tmp/wp-debug.log

docker compose exec -T wordpress sh -c ": > $LOG; chown www-data $LOG" ||
	die "sandbox is not running: PHP_VERSION=$PHP_VERSION docker compose up -d"

WP_LOADS=yes
URLS=$(wpc post list --post_type=any --post_status=publish --field=url) || true
if [ -z "$URLS" ]; then
	# WP-CLI could not load WordPress, usually because a plugin refuses to run
	# on this PHP version. Fall back to the database for the page list.
	WP_LOADS=no
	PREFIX=${TABLE_PREFIX:-wp_}
	URLS=$(docker compose exec -T db mariadb -uwordpress -pwordpress wordpress -N -e \
		"SELECT CONCAT('$BASE/?page_id=', ID) FROM ${PREFIX}posts WHERE post_status='publish' AND post_type IN ('page','post')")
fi
printf '%s\n' "$BASE/" "$URLS" "$BASE/feed/" "$BASE/?s=a" | grep -v '^$' | sort -u > "$OUT/urls.txt"

: > "$OUT/status.txt"
while read -r url; do
	code=$(curl -sL -o "$OUT/last.html" -w '%{http_code}' --max-time 60 "$url")
	grep -q "critical error" "$OUT/last.html" && code="$code CRITICAL"
	echo "$code $url" >> "$OUT/status.txt"
done < "$OUT/urls.txt"

if [ "$WP_LOADS" = yes ]; then
	ADMIN=$(wpc user list --role=administrator --field=ID --number=1)
	COOKIE=$(wpc eval "
		\$exp = time() + HOUR_IN_SECONDS;
		echo LOGGED_IN_COOKIE . '=' . rawurlencode( wp_generate_auth_cookie( $ADMIN, \$exp, 'logged_in' ) ) . '; ' .
		     AUTH_COOKIE . '=' . rawurlencode( wp_generate_auth_cookie( $ADMIN, \$exp, 'auth' ) );
	")
	for p in index.php plugins.php edit.php edit.php?post_type=page post-new.php options-general.php themes.php tools.php site-health.php; do
		code=$(curl -sL -o "$OUT/last.html" -w '%{http_code}' --max-time 60 -b "$COOKIE" "$BASE/wp-admin/$p")
		grep -q "critical error" "$OUT/last.html" && code="$code CRITICAL"
		grep -q 'id="loginform"' "$OUT/last.html" && code="$code LOGIN-REDIRECT"
		echo "$code ADMIN $p" >> "$OUT/status.txt"
	done
fi

# Headless sites: the GraphQL API is what the front end depends on. If the
# site answers on /graphql, send a small query and require data back.
GQL=$(curl -s -o "$OUT/graphql.json" -w '%{http_code}' --max-time 60 -H 'Content-Type: application/json' \
	--data '{"query":"{ generalSettings { title } posts(first: 3) { nodes { title } } }"}' "$BASE/graphql")
if [ "$GQL" != "404" ]; then
	if grep -q '"generalSettings"' "$OUT/graphql.json" && ! grep -q '"errors"' "$OUT/graphql.json"; then
		echo "$GQL GRAPHQL ok" >> "$OUT/status.txt"
	else
		echo "$GQL GRAPHQL-ERROR $(head -c 160 "$OUT/graphql.json")" >> "$OUT/status.txt"
	fi
fi

docker compose exec -T wordpress cat "$LOG" > "$OUT/debug.log"

echo "== sandbox: PHP $(docker compose exec -T wordpress php -r 'echo PHP_VERSION;'), site: $SITE_DIR"
[ "$WP_LOADS" = no ] && echo "!! WP-CLI cannot load this site on PHP $PHP_VERSION (admin screens skipped)"
echo "== HTTP status (non-200)"
awk '$1!="200" || $2=="CRITICAL" || $2=="LOGIN-REDIRECT" || $2=="GRAPHQL-ERROR"' "$OUT/status.txt"
OK=$(grep -cE '^200 (ADMIN|http|GRAPHQL ok)' "$OUT/status.txt")
TOTAL=$(wc -l < "$OUT/status.txt" | tr -d ' ')
echo "($OK of $TOTAL URLs returned 200)"
echo "== PHP errors by severity"
grep -oE 'PHP (Fatal error|Parse error|Warning|Deprecated|Notice)' "$OUT/debug.log" | sort | uniq -c
echo "== Fatal / warning / deprecated, by plugin or theme"
grep -E 'PHP (Fatal|Parse|Warning|Deprecated)' "$OUT/debug.log" |
	sed -E 's/^\[[^]]+\] //; s# in /var/www/html/wp-content/(plugins|themes)/([^/]+)/([^ ]+) on line [0-9]+# [\2] \3#' |
	cut -c1-200 | sort | uniq -c | sort -rn | head -25

FATALS=$(grep -cE 'PHP (Fatal|Parse) error' "$OUT/debug.log")
[ "$OK" = "$TOTAL" ] && [ "$FATALS" = 0 ]
