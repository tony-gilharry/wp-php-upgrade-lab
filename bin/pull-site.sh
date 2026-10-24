#!/bin/bash
# Pull a WP Engine site's code and database into the lab:
#   wp-content (themes, plugins, your own mu-plugins) -> ./site/wp-content
#   database export                                   -> ./.local/<env>.sql.gz
# Both paths are gitignored: your site never enters this repo.
#   bin/pull-site.sh                 # uses WPE_PROD_ENV from .env
#   bin/pull-site.sh <environment>
# Then set SITE_DIR=./site in .env and run bin/import-db.sh.
. "$(dirname "$0")/lib.sh"

ENV=${1:-$WPE_PROD_ENV}
[ -n "$ENV" ] || die "pass an environment name or set WPE_PROD_ENV in .env"
HOST="$ENV@$ENV.ssh.wpengine.net"
mkdir -p site .local

# WP Engine installs and updates these itself; they are not your code.
WPE_MANAGED=(
	'force-strong-passwords/' 'mu-plugin.php' 'slt-force-strong-passwords.php'
	'wpe-cache-plugin*' 'wpe-update-source-selector*' 'wpe-wp-sign-on-plugin*'
	'wpengine-common/' 'wpengine-security-auditor.php' 'local-by-flywheel-live-link-helper.php'
)
EXCLUDES=()
for p in "${WPE_MANAGED[@]}" '.DS_Store' '*.log'; do EXCLUDES+=(--exclude="$p"); done

echo "Pulling wp-content from $ENV ..."
rsync -az --stats "${EXCLUDES[@]}" \
	--include='/wp-content/' --include='/wp-content/themes/***' \
	--include='/wp-content/plugins/***' --include='/wp-content/mu-plugins/***' --exclude='*' \
	"$HOST:sites/$ENV/" site/ | grep -E 'Number of files:|Total file size'

echo "Exporting the database ..."
remote "$ENV" "wp db export - --single-transaction --quick" | gzip > ".local/$ENV.sql.gz"
ls -lh ".local/$ENV.sql.gz"
echo "Table prefix: $(remote "$ENV" 'wp db prefix')  (set TABLE_PREFIX in .env if it is not wp_)"
remote "$ENV" "wp core version" > ".local/$ENV.wp-version"
echo "WordPress $(cat ".local/$ENV.wp-version") on the server; bin/import-db.sh installs the same version locally."
