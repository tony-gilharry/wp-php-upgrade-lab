<?php
/**
 * Plugin Name: Legacy Widgets (lab demo)
 * Description: Deliberately outdated plugin for wp-php-upgrade-lab. Works on PHP 7.4 and breaks on PHP 8.x the way abandoned plugins do in the wild. Do not use on a real site.
 * Version:     1.0.0
 * Requires PHP: 5.6
 * License:     MIT
 *
 * What breaks, by PHP version:
 *   8.0  each() was removed: the [legacy_widgets] shortcode is a fatal error.
 *   8.0  Optional parameter before a required one: deprecation at compile time.
 *   8.1  strlen( null ): deprecation on every page with the shortcode.
 *   8.2  Dynamic property $settings: deprecation on every request.
 *   8.4  Implicitly nullable parameter: deprecation at compile time.
 */

class Legacy_Widgets {

	public function __construct() {
		// Dynamic property (no declaration): deprecated in PHP 8.2.
		$this->settings = get_option( 'legacy_widgets_settings', array( 'title' => 'Featured items' ) );

		add_shortcode( 'legacy_widgets', array( $this, 'render' ) );
	}

	/**
	 * Optional $atts before required $tag, and an implicitly nullable $content:
	 * both are compile-time deprecations on PHP 8.x.
	 */
	public function render( $atts = array(), string $content = null, $tag ) {
		$atts  = shortcode_atts( array( 'items' => 'Alpha,Bravo,Charlie,Delta' ), $atts, $tag );
		$items = explode( ',', $atts['items'] );

		$out  = '<h3>' . esc_html( $this->settings['title'] ) . '</h3>';
		$out .= '<p>Shortcode content length: ' . strlen( $content ) . '</p>'; // strlen( null ): deprecated in 8.1.
		$out .= '<ul class="legacy-widgets">';

		// each() was deprecated in 7.2 and removed in 8.0: fatal error on PHP 8.
		reset( $items );
		while ( list( , $item ) = each( $items ) ) {
			$out .= '<li>' . esc_html( trim( $item ) ) . '</li>';
		}

		return $out . '</ul>';
	}
}

new Legacy_Widgets();
