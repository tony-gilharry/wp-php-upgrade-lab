#!/bin/bash
# Deploy wp-content to a WP Engine environment with Git push, without shipping
# anything else from the repo.
#   bin/deploy-wpengine.sh <git-remote> [commit] [site-root]
# Run it from inside the repository you are deploying: usually your site's
# own private repo (call it by path: ~/wp-php-upgrade-lab/bin/deploy-wpengine.sh).
#   .../deploy-wpengine.sh wpengine-staging                  # main, wp-content at repo root
#   bin/deploy-wpengine.sh wpe-dev main examples/headless-wp # from this repo
# Never add a host remote to this public lab repo for a client site.
#
# WP Engine serves the repo root as the site root, so README.md, bin/ and
# docker-compose.yml would be publicly downloadable if pushed directly. This
# builds a deploy-only commit whose tree holds just <site-root>/wp-content,
# parented on whatever the remote last received, and pushes that.
# Files dropped between deploys are deleted on the server; empty directories
# are left behind (docs/gotchas.md).
set -euo pipefail
START_DIR=$PWD
. "$(dirname "$0")/lib.sh"
# lib.sh moves to the lab root; deploy the repository the command was run from.
REPO=$(cd "$START_DIR" && git rev-parse --show-toplevel 2>/dev/null) || die "run this from inside the Git repository to deploy"
cd "$REPO"

REMOTE=${1:?git remote for a WP Engine environment, e.g. wpengine-staging}
SOURCE=$(git rev-parse --verify "${2:-main}^{commit}")
ROOT=${3:-.}

git fetch -q "$REMOTE" main 2>/dev/null || true
PARENT=$(git rev-parse -q --verify "refs/remotes/$REMOTE/main" || true)

if [ "$ROOT" = "." ]; then
	TREE=$(git ls-tree "$SOURCE" -- wp-content | git mktree)
else
	TREE=$(git ls-tree "$SOURCE:$ROOT" -- wp-content | git mktree)
fi
[ "$(git ls-tree "$TREE" | wc -l)" -gt 0 ] || die "no wp-content in $SOURCE:$ROOT"

if [ -n "$PARENT" ] && [ "$(git rev-parse "$PARENT^{tree}")" = "$TREE" ]; then
	echo "$REMOTE already has this tree; nothing to deploy."
	exit 0
fi

COMMIT=$(git commit-tree "$TREE" ${PARENT:+-p "$PARENT"} -m "Deploy $(git log -1 --format='%h %s' "$SOURCE")")
echo "Deploying $(git rev-parse --short "$SOURCE") ($ROOT/wp-content) to $REMOTE as $(git rev-parse --short "$COMMIT")"
if [ -n "$PARENT" ]; then
	git diff --stat "$PARENT" "$COMMIT" | tail -1
fi
git push "$REMOTE" "$COMMIT:refs/heads/main" 2>&1 |
	sed 's/\x1b\[[0-9;]*m//g; s/\^\[(B//g' |
	grep -E 'success|complete|error|rejected|fatal' || true
git fetch -q "$REMOTE" main
