#!/bin/bash
# Shared setup for bin/ scripts: repo root, .env, Docker CLI, small helpers.
# shellcheck disable=SC2034  # variables are used by the scripts that source this

LAB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$LAB_ROOT" || exit 1

if [ -f .env ]; then
	set -a
	# shellcheck disable=SC1091
	. ./.env
	set +a
fi

PHP_VERSION=${PHP_VERSION:-8.4}
LAB_PORT=${LAB_PORT:-8083}
SITE_DIR=${SITE_DIR:-./demo}
export PHP_VERSION LAB_PORT SITE_DIR

# Docker Desktop on macOS does not put its CLI on PATH by default.
if ! command -v docker >/dev/null 2>&1 && [ -x /Applications/Docker.app/Contents/Resources/bin/docker ]; then
	PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
fi

# WP-CLI inside the sandbox, on the sandbox's PHP version.
wpc() {
	docker compose run --rm -T cli wp "$@" 2>/dev/null
}

die() {
	echo "error: $*" >&2
	exit 1
}

# SSH to a WP Engine environment and run a command in its site directory.
# The SSH Gateway re-splits the command string, so quotes inside it are lost:
# anything with quotes, parentheses or $ must go through remote_script.
remote() {
	local env=$1
	shift
	ssh -o BatchMode=yes "$env@$env.ssh.wpengine.net" "cd ~/sites/$env && $*"
}

# Run a script read from stdin on a WP Engine environment, with $1 = env name.
remote_script() {
	local env=$1
	ssh -o BatchMode=yes "$env@$env.ssh.wpengine.net" "bash -s -- $env"
}
