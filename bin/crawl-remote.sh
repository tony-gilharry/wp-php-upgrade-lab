#!/bin/bash
# Crawl a WP Engine environment over HTTPS (published URLs + admin screens) and
# summarize status codes plus PHP errors from a debug log on the server.
#   bin/crawl-remote.sh <environment>
#   LOG=_wpeprivate/debug-lab.log bin/crawl-remote.sh <environment>
# LOG defaults to /dev/null (status codes only). Keep debug logs in
# _wpeprivate/, which WP Engine never serves: a log under wp-content/ is
# downloadable by anyone who guesses its name. Turning a debug log on and off
# is covered in docs/playbook.md. Needs working WP-CLI on the SSH Gateway.
# Results are kept in .local/crawl-<environment>/ (gitignored).
. "$(dirname "$0")/lib.sh"

ENV=${1:?environment name}
LOG=${LOG:-/dev/null}
OUT=".local/crawl-$ENV"
mkdir -p "$OUT"

BASE=$(remote "$ENV" "wp option get home" 2>/dev/null)
[ -n "$BASE" ] || die "WP-CLI on $ENV returned nothing. Is the gateway's CLI PHP older than a plugin requires? (docs/gotchas.md)"
remote "$ENV" ": > $LOG"

{
	echo "$BASE/"
	remote "$ENV" "wp post list --post_type=any --post_status=publish --field=url" 2>/dev/null
	echo "$BASE/feed/"
	echo "$BASE/?s=a"
} | sort -u > "$OUT/urls.txt"

COOKIE=$(remote_script "$ENV" 2>/dev/null <<'EOF'
cd ~/sites/$1
wp eval '
	$id  = get_users( array( "role" => "administrator", "number" => 1, "fields" => "ID" ) )[0];
	$exp = time() + 600;
	echo SECURE_AUTH_COOKIE . "=" . rawurlencode( wp_generate_auth_cookie( $id, $exp, "secure_auth" ) ) . "; " .
	     LOGGED_IN_COOKIE   . "=" . rawurlencode( wp_generate_auth_cookie( $id, $exp, "logged_in" ) );
'
EOF
)

: > "$OUT/status.txt"
while read -r url; do
	code=$(curl -s -o "$OUT/last.html" -w '%{http_code}' --max-time 60 "$url")
	grep -q "critical error" "$OUT/last.html" && code="$code CRITICAL"
	echo "$code $url" >> "$OUT/status.txt"
done < "$OUT/urls.txt"
for p in index.php plugins.php edit.php edit.php?post_type=page post-new.php options-general.php themes.php tools.php site-health.php; do
	code=$(curl -s -o "$OUT/last.html" -w '%{http_code}' --max-time 60 -b "$COOKIE" "$BASE/wp-admin/$p")
	grep -q "critical error" "$OUT/last.html" && code="$code CRITICAL"
	grep -q 'id="loginform"' "$OUT/last.html" && code="$code LOGIN-REDIRECT"
	echo "$code ADMIN $p" >> "$OUT/status.txt"
done

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

# The PHP version serving web requests. The gateway's CLI PHP can lag behind it.
WEB_PHP=$(curl -s -b "$COOKIE" "$BASE/wp-admin/site-health.php?tab=debug" | grep -oE 'PHP version</th><td>[0-9.]+' | head -1 | sed 's/.*<td>//')
# No quotes in remote commands: the gateway re-splits them (docs/gotchas.md).
CLI_PHP=$(remote "$ENV" "php -v" 2>/dev/null | awk 'NR==1 {print $2}')
remote "$ENV" "cat $LOG" > "$OUT/debug.log" 2>/dev/null

echo "== $ENV: web PHP ${WEB_PHP:-unknown}, gateway CLI PHP ${CLI_PHP:-unknown}"
echo "== HTTP status (non-200)"
awk '$1!="200" || $2=="CRITICAL" || $2=="LOGIN-REDIRECT" || $2=="GRAPHQL-ERROR"' "$OUT/status.txt"
OK=$(grep -cE '^200 (ADMIN|http|GRAPHQL ok)' "$OUT/status.txt" | tr -d ' ')
echo "($OK of $(wc -l < "$OUT/status.txt" | tr -d ' ') URLs returned 200)"
echo "== PHP errors by severity"
grep -oE 'PHP (Fatal error|Parse error|Warning|Deprecated|Notice)' "$OUT/debug.log" | sort | uniq -c
echo "== Fatal / warning / deprecated detail"
grep -E 'PHP (Fatal|Parse|Warning|Deprecated)' "$OUT/debug.log" |
	sed -E 's/^\[[^]]+\] //; s# in /[^ ]*/wp-content/# @ #; s/ on line [0-9]+//' |
	cut -c1-200 | sort | uniq -c | sort -rn | head -20
