#!/bin/bash
# Static PHP compatibility scan with PHPCompatibility.
#   bin/compat-scan.sh 8.4                      # $SITE_DIR/wp-content themes + plugins
#   bin/compat-scan.sh 8.4 demo/upgrades        # any directory
# Exit status: 0 when no errors (warnings are reported but allowed).
# Installs PHP_CodeSniffer + PHPCompatibility's develop branch (which knows
# PHP 8.x) into .local/phpcs on first run. Needs local php and composer.
. "$(dirname "$0")/lib.sh"

TARGET=${1:?target PHP version, e.g. 8.4}
shift
if [ $# -eq 0 ]; then
	set -- "$SITE_DIR/wp-content/themes" "$SITE_DIR/wp-content/plugins"
fi
TOOLS=.local/phpcs
REPORT=.local/compat-$TARGET.json
mkdir -p .local

if [ ! -x "$TOOLS/vendor/bin/phpcs" ]; then
	mkdir -p "$TOOLS"
	printf '%s' '{"minimum-stability":"dev","prefer-stable":true,"config":{"allow-plugins":{"dealerdirect/phpcodesniffer-composer-installer":true}}}' > "$TOOLS/composer.json"
	composer --working-dir="$TOOLS" require --no-interaction --quiet \
		"phpcompatibility/php-compatibility:dev-develop" dealerdirect/phpcodesniffer-composer-installer ||
		die "could not install PHPCompatibility (needs php and composer)"
fi

# testVersion X-X, not "X-": an open range also checks future PHP versions.
"$TOOLS/vendor/bin/phpcs" -d memory_limit=4G --standard=PHPCompatibility \
	--runtime-set testVersion "$TARGET-$TARGET" --extensions=php --parallel=8 \
	--ignore='*/tests/*,*/test/*,*/node_modules/*' \
	--report=json --report-file="$REPORT" "$@" >/dev/null 2>&1

php -r '
$d  = json_decode( file_get_contents( $argv[1] ), true );
$by = array();
foreach ( $d["files"] as $f => $r ) {
	foreach ( $r["messages"] as $m ) {
		preg_match( "#(?:plugins|themes|upgrades)/([^/]+)/#", $f, $x );
		$key        = ( $x[1] ?? basename( $f ) ) . " | " . $m["type"] . " | " . $m["source"];
		$by[ $key ] = ( $by[ $key ] ?? 0 ) + 1;
	}
}
arsort( $by );
foreach ( $by as $k => $n ) {
	echo str_pad( $n, 5, " ", STR_PAD_LEFT ), "  $k\n";
}
echo "TOTAL for PHP {$argv[2]}: {$d["totals"]["errors"]} errors, {$d["totals"]["warnings"]} warnings\n";
exit( $d["totals"]["errors"] > 0 ? 1 : 0 );
' "$REPORT" "$TARGET"
