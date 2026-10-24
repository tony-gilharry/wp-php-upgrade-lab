# Third-party notices

The [MIT License](LICENSE) covers the original work in this repository: the
`bin/` scripts, `docker-compose.yml`, the demo plugins in `demo/`, the docs in
`docs/`, and the Claude Code skills in `.claude/skills/`.

It does **not** cover the third-party code in
[`examples/headless-wp/`](examples/headless-wp/), which is included so the
worked example can be read and reproduced. That code is stored alongside
this project, not combined with it, and each component keeps its own
license and authors. The full GPL texts are in
[`examples/headless-wp/LICENSES/`](examples/headless-wp/LICENSES/).

## WordPress plugins and theme

| Component | Version | License | Authors / source |
|---|---|---|---|
| WPGraphQL (`plugins/wp-graphql`) | 2.25.0 | GPL-3.0 ([text](examples/headless-wp/LICENSES/GPL-3.0.txt)) | WPGraphQL, <https://github.com/wp-graphql/wp-graphql> |
| WPGraphQL development build (`plugins/wp-graphql-develop`, in the "as found" commit only) | 0.10.3 | GPL-3.0 | WPGraphQL |
| WP Gatsby (`plugins/wp-gatsby`) | 2.3.3 (0.4.13 in the "as found" commit) | GPL-3.0 (its own `license.txt`) | GatsbyJS, Jason Bahl, Tyler Barnes, <https://github.com/gatsbyjs/wp-gatsby> |
| "Travel Agency" theme (`themes/travel agency 2.0`) | 1.0 | GPL-2.0-or-later ([text](examples/headless-wp/LICENSES/GPL-2.0.txt)) | Exported with Pinegrow Web Editor (theme author field left as "Your name"). Its nav menu walker, `inc/wp_smart_navwalker.php`, is by Matjaz Trontelj (@pinegrow) and is **modified** here: see the notice in that file and the upgrade commit. |

The theme and plugins are unchanged except for that one file.

## Libraries bundled inside the plugins and theme

Shipped by their upstream authors as part of the components above, each
with its license notice in its own files.

| Library | Version | License | Copyright |
|---|---|---|---|
| webonyx/graphql-php (in WPGraphQL) | 15.38.1 | MIT | Webonyx, LLC |
| ivome/graphql-relay-php (in WPGraphQL) | 0.7.0 | BSD-3-Clause | Ivo Meißner |
| appsero/client (in WPGraphQL) | 2.0.7 | MIT (per the plugin's Composer metadata) | Appsero |
| firebase/php-jwt (in WP Gatsby) | as bundled | BSD-3-Clause | Neuman Vong |
| ircmaxell/random-lib, ircmaxell/security-lib (in WP Gatsby) | as bundled | MIT | "The Authors" (per their LICENSE files) |
| composer/semver (in WP Gatsby) | as bundled | MIT | Composer |
| Bootstrap (in the theme) | 4.0.0 | MIT | The Bootstrap Authors and Twitter, Inc. |
| Popper.js (in the theme) | 1.12.5 | MIT | Federico Zivolo and contributors |
| Holder.js (in the theme) | not stated in the file | MIT | Ivan Malopinsky |
| jQuery (in the theme) | 3.1.0 | MIT | jQuery Foundation |

If you redistribute anything from `examples/`, follow that component's
license, not this repository's MIT license.

## Names and trademarks

WordPress, WP Engine, Gatsby, Pinegrow, Claude and Anthropic are trademarks
of their respective owners. They are used here only to identify the
software and services the project works with; no endorsement is implied.
