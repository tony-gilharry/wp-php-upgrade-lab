<?php

// Typed class constants are PHP 8.3 syntax: this file is a parse error on
// anything older, which is why the platform check runs first.
final class Modern_Forms {

	public const string VERSION = '2.0.0';

	public static function render(): string {
		return '<form class="modern-form" method="post" action="#">'
			. '<label>Email <input type="email" name="email" required></label> '
			. '<button type="submit">Send</button>'
			. '</form><p><small>Modern Forms ' . self::VERSION . '</small></p>';
	}
}
