# Third-party notices

The [MIT License](LICENSE) covers the original work in this repository: the
`bin/` scripts, `docker-compose.yml`, the demo plugins in `demo/`, the docs in
`docs/`, and the Claude Code skills in `.claude/skills/`.

It does **not** cover the third-party code in
[`examples/headless-wp/`](examples/headless-wp/), which is included unchanged
except where noted, so the worked example can be read and reproduced. Each
component keeps its own license and authors:

| Component | Version | License | Authors / source |
|---|---|---|---|
| WPGraphQL (`plugins/wp-graphql`) | 2.25.0 | GPL-3.0 | WPGraphQL, <https://github.com/wp-graphql/wp-graphql> |
| WP Gatsby (`plugins/wp-gatsby`) | 2.3.3 (and 0.4.13 in the "as found" commit) | GPL-3.0 | GatsbyJS, Jason Bahl, Tyler Barnes, <https://github.com/gatsbyjs/wp-gatsby> |
| WPGraphQL development build (`plugins/wp-graphql-develop`, "as found" commit only) | 0.10.3 | GPL-3.0 | WPGraphQL |
| "Travel Agency" theme (`themes/travel agency 2.0`) | 1.0 | GPL-2.0-or-later, per its `style.css` header | Exported with Pinegrow Web Editor; the author field was never filled in. **Modified** in this repo: `inc/wp_smart_navwalker.php` (PHP 8 fix, see the upgrade commit) |
| Bootstrap, bundled in the theme | 4.0.0 | MIT | The Bootstrap Authors and Twitter, Inc. |
| Popper.js, bundled in the theme | 1.12.5 | MIT | Federico Zivolo and contributors |
| Holder.js, bundled in the theme | not stated in the file | MIT | Ivan Malopinsky |
| jQuery, bundled in the theme | 3.1.0 | MIT | The jQuery Foundation and other contributors |
| firebase/php-jwt, bundled in WP Gatsby | as bundled | BSD-3-Clause | Neuman Vong (license file in `vendor/firebase/php-jwt/LICENSE`) |

License texts are in each component's own files where its authors ship them,
and at the URLs above. If you redistribute anything from `examples/`,
follow that component's license, not this repository's MIT license.
