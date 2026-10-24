#!/bin/bash
# For every plugin in $SITE_DIR, compare the installed version with the latest
# on WordPress.org and flag what will get in the way of a PHP upgrade.
#   bin/plugin-audit.sh            # flags against the target PHP in PHP_VERSION
# Flags:
#   CLOSED      removed from WordPress.org; no more security fixes
#   STALE       no release in over two years
#   NEEDS-PHP   latest release needs a newer PHP than CURRENT_PHP: deploy it
#               only after the PHP switch
#   NOT-ON-ORG  premium or custom: check with the vendor or read the code
. "$(dirname "$0")/lib.sh"

CURRENT_PHP=${CURRENT_PHP:-7.4}
PLUGINS="$SITE_DIR/wp-content/plugins"
[ -d "$PLUGINS" ] || die "no plugins directory at $PLUGINS"

header() { grep -m1 -iE "^[ \t/*#@]*$2:" "$1" 2>/dev/null | sed -E 's/.*:[[:space:]]*//; s/[[:space:]]*$//'; }

printf '%-34s %-10s %-10s %-9s %-11s %s\n' PLUGIN INSTALLED LATEST "NEEDS PHP" "UPDATED" FLAGS
for dir in "$PLUGINS"/*/; do
	slug=$(basename "$dir")
	main=$(grep -l -m1 -E '^[ \t/*#@]*Plugin Name:' "$dir"*.php 2>/dev/null | head -1)
	[ -n "$main" ] || continue
	installed=$(header "$main" Version)

	info=$(curl -s --max-time 20 "https://api.wordpress.org/plugins/info/1.2/?action=plugin_information&request%5Bslug%5D=$slug&request%5Bfields%5D%5Bsections%5D=0&request%5Bfields%5D%5Bversions%5D=0")
	read -r latest needs updated closed < <(printf '%s' "$info" | php -d display_errors=stderr -r '
		$d      = json_decode( stream_get_contents( STDIN ), true ) ?: array();
		$closed = isset( $d["error"] ) ? ( stripos( ( $d["description"] ?? "" ) . $d["error"], "closed" ) !== false ? "closed" : "missing" ) : "open";
		printf(
			"%s %s %s %s",
			( $d["version"] ?? "" ) ?: "-",
			( $d["requires_php"] ?? "" ) ?: "-",
			substr( ( $d["last_updated"] ?? "" ) ?: "-", 0, 10 ),
			$closed
		);
	')

	flags=""
	case $closed in
		closed) flags="CLOSED" ;;
		missing) flags="NOT-ON-ORG" ;;
	esac
	if [ "$updated" != "-" ] && [ "$(date -j -f %Y-%m-%d "$updated" +%s 2>/dev/null || date -d "$updated" +%s)" -lt "$(( $(date +%s) - 730*86400 ))" ]; then
		flags="$flags STALE"
	fi
	if [ "$needs" != "-" ] && [ "$(printf '%s\n%s\n' "$CURRENT_PHP" "$needs" | sort -V | tail -1)" != "$CURRENT_PHP" ]; then
		flags="$flags NEEDS-PHP"
	fi
	printf '%-34s %-10s %-10s %-9s %-11s %s\n' "$slug" "${installed:--}" "$latest" "$needs" "$updated" "$flags"
done
