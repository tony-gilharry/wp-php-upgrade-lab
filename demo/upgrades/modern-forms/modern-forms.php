<?php
/**
 * Plugin Name: Modern Forms (lab demo)
 * Description: Stand-in for a maintained plugin whose new release requires PHP 8.3, like Contact Form 7 6.2. Deploying it before the server runs PHP 8.3 takes the whole site down, and it breaks WP-CLI wherever the command-line PHP is older.
 * Version:     2.0.0
 * Requires PHP: 8.3
 * License:     MIT
 */

// Same behaviour as Composer's generated vendor/composer/platform_check.php:
// refuse to load at all on an unsupported PHP, rather than fail half-way.
if ( PHP_VERSION_ID < 80300 ) {
	throw new RuntimeException(
		'Modern Forms requires a PHP version ">= 8.3.0". You are running ' . PHP_VERSION . '.'
	);
}

require_once __DIR__ . '/includes/class-modern-forms.php';

add_shortcode( 'modern_form', array( Modern_Forms::class, 'render' ) );
