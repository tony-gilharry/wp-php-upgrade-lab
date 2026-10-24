<?php
/**
 * Plugin Name: Modern Forms (lab demo)
 * Description: Stand-in for a maintained plugin whose next release requires a newer PHP. Version 1.x runs on PHP 7.4+; version 2.x (in demo/upgrades/) needs PHP 8.3.
 * Version:     1.9.0
 * Requires PHP: 7.4
 * License:     MIT
 */

require_once __DIR__ . '/includes/class-modern-forms.php';

add_shortcode( 'modern_form', array( 'Modern_Forms', 'render' ) );
