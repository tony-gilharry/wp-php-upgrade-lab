#!/bin/bash
# Swap a demo plugin for its upgraded release from demo/upgrades/, or put the
# original back. Stands in for `wp plugin update` on a real site.
#   bin/demo-upgrade.sh legacy-widgets           # install the upgrade
#   bin/demo-upgrade.sh legacy-widgets --revert  # back to the original
. "$(dirname "$0")/lib.sh"

PLUGIN=${1:?plugin slug: legacy-widgets or modern-forms}
DEST="demo/wp-content/plugins/$PLUGIN"
[ -d "demo/upgrades/$PLUGIN" ] || die "no upgrade for $PLUGIN in demo/upgrades/"

if [ "${2:-}" = "--revert" ]; then
	git checkout -- "$DEST" && git clean -fdq -- "$DEST"
else
	rm -rf "$DEST" && cp -R "demo/upgrades/$PLUGIN" "$DEST"
fi

grep -E '^ \* (Version|Requires PHP):' "$DEST/$PLUGIN.php"

# OPcache keeps serving the replaced files for a while; a restart makes the
# next crawl test the code that is actually on disk.
docker compose restart wordpress >/dev/null 2>&1 && echo "Restarted the sandbox web server (clears OPcache)."
