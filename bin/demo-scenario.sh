#!/bin/bash
# Run the whole demo upgrade story and check every step behaves as expected:
#
#   1. PHP 7.4, original plugins          -> passes (today's production)
#   2. PHP 8.4, original plugins          -> FAILS  (each() fatal in Legacy Widgets)
#   3. PHP 8.4, Legacy Widgets 2.0        -> passes
#   4. PHP 7.4, Legacy Widgets 2.0        -> passes (so it can ship before the switch)
#   5. PHP 7.4, Modern Forms 2.0 as well  -> FAILS  (needs PHP 8.3: ship it after)
#   6. PHP 8.4, both upgrades             -> passes (the end state)
#
#   bin/demo-scenario.sh            # reuse the running sandbox
#   bin/demo-scenario.sh --fresh    # start from empty volumes (what CI does)
# Exit status 0 when every step matched its expectation.
. "$(dirname "$0")/lib.sh"

FROM=${FROM_PHP:-7.4}
TO=${TO_PHP:-8.4}
RESULTS=()
MISMATCH=0

php_switch() {
	PHP_VERSION=$1 docker compose up -d --force-recreate wordpress >/dev/null 2>&1
	sleep 3
}

step() {
	local label=$1 php=$2 expect=$3 got
	echo
	echo "################ $label (PHP $php, expect $expect)"
	if PHP_VERSION=$php bin/crawl-local.sh; then got=pass; else got=FAIL; fi
	if [ "$got" = "$expect" ]; then
		RESULTS+=("ok        $label: $got")
	else
		RESULTS+=("MISMATCH  $label: expected $expect, got $got")
		MISMATCH=1
	fi
}

bin/demo-upgrade.sh legacy-widgets --revert >/dev/null
bin/demo-upgrade.sh modern-forms --revert >/dev/null

if [ "${1:-}" = "--fresh" ]; then
	docker compose down -v >/dev/null 2>&1
fi
PHP_VERSION=$FROM docker compose up -d >/dev/null 2>&1 || die "docker compose up failed"
for _ in $(seq 1 30); do
	PHP_VERSION=$FROM docker compose run --rm -T cli wp db check >/dev/null 2>&1 && break
	sleep 2
done
PHP_VERSION=$FROM bin/demo-setup.sh

php_switch "$FROM"
step "1. original plugins" "$FROM" pass
php_switch "$TO"
step "2. original plugins" "$TO" FAIL

bin/demo-upgrade.sh legacy-widgets
step "3. Legacy Widgets 2.0" "$TO" pass
php_switch "$FROM"
step "4. Legacy Widgets 2.0" "$FROM" pass

bin/demo-upgrade.sh modern-forms
step "5. + Modern Forms 2.0 too early" "$FROM" FAIL
php_switch "$TO"
step "6. + Modern Forms 2.0 after switch" "$TO" pass

bin/demo-upgrade.sh legacy-widgets --revert >/dev/null
bin/demo-upgrade.sh modern-forms --revert >/dev/null

echo
echo "################ Summary (PHP $FROM -> $TO)"
printf '%s\n' "${RESULTS[@]}"
exit "$MISMATCH"
