#!/bin/bash
# Load a pulled database into the sandbox and point its URLs at localhost.
#   bin/import-db.sh                     # .local/$WPE_PROD_ENV.sql.gz
#   bin/import-db.sh path/to/dump.sql.gz
. "$(dirname "$0")/lib.sh"

DUMP=${1:-.local/$WPE_PROD_ENV.sql.gz}
[ -f "$DUMP" ] || die "no dump at $DUMP (run bin/pull-site.sh first)"
[ -n "${PROD_DOMAIN:-}" ] || die "set PROD_DOMAIN in .env (e.g. example.com)"

gunzip -c "$DUMP" | docker compose exec -T db mariadb -uwordpress -pwordpress wordpress

# Run the same WordPress core as the server: the Docker image bundles its own.
VERSION_FILE="${DUMP%.sql.gz}.wp-version"
if [ -f "$VERSION_FILE" ]; then
	wpc core update --version="$(cat "$VERSION_FILE")" --force
	wpc core update-db
fi
for from in "https://$PROD_DOMAIN" "http://$PROD_DOMAIN" "https://www.$PROD_DOMAIN" "http://www.$PROD_DOMAIN"; do
	wpc search-replace "$from" "http://localhost:$LAB_PORT" --all-tables --skip-columns=guid --format=count
done
wpc cache flush
echo "Imported. Site: http://localhost:$LAB_PORT"
