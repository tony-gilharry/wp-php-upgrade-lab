<?php

class Modern_Forms {

	const VERSION = '1.9.0';

	public static function render() {
		return '<form class="modern-form" method="post" action="#">'
			. '<label>Email <input type="email" name="email"></label> '
			. '<button type="submit">Send</button>'
			. '</form><p><small>Modern Forms ' . self::VERSION . '</small></p>';
	}
}
