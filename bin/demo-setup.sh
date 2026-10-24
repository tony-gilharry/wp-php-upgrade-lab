#!/bin/bash
# Install WordPress in the sandbox with the demo plugins and pages.
#   docker compose up -d && bin/demo-setup.sh
# Safe to re-run: skips the install if WordPress is already set up.
. "$(dirname "$0")/lib.sh"

[ "$SITE_DIR" = "./demo" ] || die "demo-setup.sh only runs against SITE_DIR=./demo"

URL="http://localhost:$LAB_PORT"

if ! wpc core is-installed; then
	PASS=$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom 2>/dev/null | head -c 20)
	wpc core install --url="$URL" --title="PHP Upgrade Lab" \
		--admin_user=lab-admin --admin_password="$PASS" --admin_email=admin@example.com --skip-email
	echo "Admin login: lab-admin / $PASS  ($URL/wp-admin/)"
fi

# Older wordpress:php7.x images ship an old WordPress whose own code throws
# deprecations on PHP 8.x. Bring core current first, as on a real site.
wpc core update
wpc core update-db

wpc plugin activate legacy-widgets modern-forms
wpc rewrite structure '/%postname%/'

page() {
	local slug=$1 title=$2 content=$3
	if [ -z "$(wpc post list --post_type=page --name="$slug" --field=ID)" ]; then
		wpc post create --post_type=page --post_status=publish --post_name="$slug" \
			--post_title="$title" --post_content="$content" >/dev/null
	fi
}

page widgets  "Widgets"    '<!-- wp:paragraph --><p>Rendered by the Legacy Widgets plugin:</p><!-- /wp:paragraph -->[legacy_widgets]'
page contact  "Contact"    '<!-- wp:paragraph --><p>Rendered by the Modern Forms plugin:</p><!-- /wp:paragraph -->[modern_form]'
page about    "About"      '<!-- wp:paragraph --><p>A plain page with no plugin output.</p><!-- /wp:paragraph -->'

echo "Demo site ready on PHP $(docker compose exec -T wordpress php -r 'echo PHP_VERSION;') at $URL"
