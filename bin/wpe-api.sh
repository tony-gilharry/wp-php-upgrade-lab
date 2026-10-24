#!/bin/bash
# Small client for the WP Engine Hosting Platform API, for the portal steps
# that can be scripted. Changing an environment's PHP version cannot: the
# API exposes php_version read-only, so that stays a portal action.
#
#   bin/wpe-api.sh status
#   bin/wpe-api.sh installs                      # name, environment, PHP, domain
#   bin/wpe-api.sh php <install>                 # PHP version the portal is set to
#   bin/wpe-api.sh backup <install> "<note>" <email>   # waits until completed
#   bin/wpe-api.sh copy <from-install> <to-install> <email> [--files-only|--db-only]
#   bin/wpe-api.sh purge <install> [all|page|object|cdn]
#
# Credentials (generate them in the WP Engine portal under API Access):
#   macOS Keychain, preferred:
#     security add-generic-password -s wpe-api -a <API user ID> -w
#   or environment variables (CI): WPE_API_USER and WPE_API_PASSWORD.
# Reference: https://developers.wpengine.com/docs/managed-hosting-platform/api/
. "$(dirname "$0")/lib.sh"

API=https://api.wpengineapi.com/v1
command -v jq >/dev/null 2>&1 || die "jq is required (brew install jq)"

credentials() {
	if [ -z "${WPE_API_USER:-}" ] && command -v security >/dev/null 2>&1; then
		WPE_API_USER=$(security find-generic-password -s wpe-api 2>/dev/null | sed -n 's/.*"acct"<blob>="\(.*\)"/\1/p')
		WPE_API_PASSWORD=$(security find-generic-password -s wpe-api -w 2>/dev/null)
	fi
	[ -n "${WPE_API_USER:-}" ] && [ -n "${WPE_API_PASSWORD:-}" ] ||
		die "no API credentials: add them to the Keychain (service wpe-api) or set WPE_API_USER and WPE_API_PASSWORD"
}

# api METHOD PATH [JSON-BODY]: prints the response body, fails on HTTP >= 400.
api() {
	local method=$1 path=$2 body=${3:-} out code
	out=$(mktemp)
	code=$(curl -s -o "$out" -w '%{http_code}' -X "$method" -u "$WPE_API_USER:$WPE_API_PASSWORD" \
		-H 'Content-Type: application/json' ${body:+--data "$body"} "$API$path")
	if [ "$code" -ge 400 ]; then
		echo "error: $method $path returned HTTP $code: $(head -c 300 "$out")" >&2
		rm -f "$out"
		return 1
	fi
	cat "$out"
	rm -f "$out"
}

# All installs, following pagination.
all_installs() {
	local path="/installs?limit=100" page
	while [ -n "$path" ]; do
		page=$(api GET "$path") || return 1
		printf '%s' "$page" | jq -c '.results[]'
		path=$(printf '%s' "$page" | jq -r '.next // empty' | sed "s#^$API##")
	done
}

install_id() {
	local id
	id=$(all_installs | jq -r --arg n "$1" 'select(.name == $n) | .id')
	[ -n "$id" ] || die "no install named $1"
	echo "$id"
}

credentials
CMD=${1:-}
shift || true

case $CMD in
	status)
		api GET /status | jq .
		;;
	installs)
		all_installs | jq -r '[.name, (.environment // "-"), (.php_version // "-"), (.primary_domain // .cname // "-")] | @tsv' |
			sort | column -t
		;;
	php)
		NAME=${1:?install name}
		api GET "/installs/$(install_id "$NAME")" | jq -r '"\(.name): portal PHP \(.php_version // "unknown"), WordPress \(.wp_version // "unknown")"'
		;;
	backup)
		NAME=${1:?install name}
		NOTE=${2:?description}
		EMAIL=${3:?notification email}
		ID=$(install_id "$NAME")
		BODY=$(jq -n --arg d "$NOTE" --arg e "$EMAIL" '{description: $d, notification_emails: [$e]}')
		BACKUP=$(api POST "/installs/$ID/backups" "$BODY") || exit 1
		BID=$(printf '%s' "$BACKUP" | jq -r .id)
		echo "Backup $BID requested for $NAME"
		for _ in $(seq 1 120); do
			STATUS=$(api GET "/installs/$ID/backups/$BID" | jq -r .status)
			echo "  $(date +%H:%M:%S) $STATUS"
			case $STATUS in
				completed) exit 0 ;;
				aborted) die "backup aborted" ;;
			esac
			sleep 15
		done
		die "backup still not complete after 30 minutes; check the portal"
		;;
	copy)
		FROM=${1:?source install}
		TO=${2:?destination install}
		EMAIL=${3:?notification email}
		case ${4:-} in
			--files-only) OPTS='{include_files: true, include_db: false}' ;;
			--db-only) OPTS='{include_files: false, include_db: true}' ;;
			*) OPTS='{include_files: true, include_db: true}' ;;
		esac
		BODY=$(jq -n --arg s "$(install_id "$FROM")" --arg d "$(install_id "$TO")" --arg e "$EMAIL" \
			"{source_environment_id: \$s, destination_environment_id: \$d, notification_emails: [\$e], custom_options: $OPTS}")
		echo "Copying $FROM -> $TO (overwrites $TO). The PHP version is not copied; check it afterwards with: bin/wpe-api.sh php $TO"
		api POST /install_copy "$BODY" | jq .
		echo "The copy runs asynchronously; $EMAIL is emailed when it completes."
		;;
	purge)
		NAME=${1:?install name}
		TYPE=${2:-all}
		api POST "/installs/$(install_id "$NAME")/purge_cache" "$(jq -n --arg t "$TYPE" '{type: $t}')" >/dev/null &&
			echo "Cache purge ($TYPE) queued for $NAME"
		;;
	*)
		sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'
		exit 1
		;;
esac
