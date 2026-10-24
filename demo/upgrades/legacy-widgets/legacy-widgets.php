<?php
/**
 * Plugin Name: Legacy Widgets (lab demo)
 * Description: The fixed release of the lab's deliberately outdated plugin. Runs cleanly on PHP 7.4 through 8.4, so it can ship before the PHP switch.
 * Version:     2.0.0
 * Requires PHP: 7.4
 * License:     MIT
 *
 * Fixes, matching the breakages listed in 1.0.0:
 *   each() loop             -> foreach
 *   optional-before-required -> parameters in WordPress's shortcode callback order
 *   strlen( null )          -> cast to string
 *   dynamic property        -> declared property
 *   implicit nullable       -> explicit default handling
 */

class Legacy_Widgets {

	/** @var array */
	private $settings;

	public function __construct() {
		$this->settings = get_option( 'legacy_widgets_settings', array( 'title' => 'Featured items' ) );

		add_shortcode( 'legacy_widgets', array( $this, 'render' ) );
	}

	public function render( $atts = array(), $content = null, $tag = '' ) {
		$atts  = shortcode_atts( array( 'items' => 'Alpha,Bravo,Charlie,Delta' ), $atts, $tag );
		$items = explode( ',', $atts['items'] );

		$out  = '<h3>' . esc_html( $this->settings['title'] ) . '</h3>';
		$out .= '<p>Shortcode content length: ' . strlen( (string) $content ) . '</p>';
		$out .= '<ul class="legacy-widgets">';

		foreach ( $items as $item ) {
			$out .= '<li>' . esc_html( trim( $item ) ) . '</li>';
		}

		return $out . '</ul>';
	}
}

new Legacy_Widgets();
