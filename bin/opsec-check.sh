#!/bin/bash
# Pre-publish check: nothing private in a repository's working tree or history.
#   bin/opsec-check.sh                 # this repository
#   bin/opsec-check.sh <path-to-repo>  # any other Git repository
# 1. gitleaks over the full history (secrets, keys, tokens).
# 2. Every term in the denylist searched in tracked files, in every commit's
#    content, and in commit authors and messages. The denylist is the target
#    repo's .opsec-denylist (gitignored; one term per line: install names,
#    domains, client names, emails, phone numbers), or the file named by
#    OPSEC_DENYLIST.
# 3. Commit author and committer emails must be GitHub no-reply addresses.
# Exit status 0 means clean. Procedure: docs/opsec/runbook.md, procedure A.
. "$(dirname "$0")/lib.sh"

if [ -n "${1:-}" ]; then
	cd "$1" || die "no such directory: $1"
fi
git rev-parse --git-dir >/dev/null 2>&1 || die "$(pwd) is not a Git repository"
DENYLIST=${OPSEC_DENYLIST:-.opsec-denylist}
FAIL=0
echo "== target: $(pwd)"

echo "== gitleaks (full history)"
if command -v gitleaks >/dev/null 2>&1; then
	gitleaks git --no-banner --redact . || FAIL=1
else
	echo "gitleaks not installed (brew install gitleaks)"
	FAIL=1
fi

echo "== denylist"
REVS=()
while IFS= read -r rev; do REVS+=("$rev"); done < <(git rev-list --all)
if [ -f "$DENYLIST" ]; then
	if [ "$DENYLIST" = ".opsec-denylist" ] && ! git check-ignore -q .opsec-denylist; then
		echo "FOUND: .opsec-denylist is not gitignored; it would publish the very names it protects"
		FAIL=1
	fi
	terms=0
	while IFS= read -r term || [ -n "$term" ]; do
		case $term in '' | '#'*) continue ;; esac
		terms=$((terms + 1))
		hits=""
		[ ${#REVS[@]} -gt 0 ] && hits=$(git grep -i -F -l -e "$term" "${REVS[@]}" -- 2>/dev/null | head -5)
		hits+=$(git log --all -i -F --format='%h %an <%ae> %s' --grep="$term" | head -3)
		hits+=$(git log --all --format='%h %an <%ae> %cn <%ce>' | grep -i -F -e "$term" | head -3)
		hits+=$(git grep -i -F -l -e "$term" -- . 2>/dev/null | head -5)
		if [ -n "$hits" ]; then
			echo "FOUND: denylist term on line $(grep -n -F -x -- "$term" "$DENYLIST" | cut -d: -f1)"
			echo "$hits" | sed 's/^/    /'
			FAIL=1
		fi
	done < "$DENYLIST"
	echo "checked $terms terms"
else
	echo "no denylist at $DENYLIST: create one with the real names that must never appear"
	FAIL=1
fi

echo "== commit identities"
while read -r email; do
	case $email in
		*@users.noreply.github.com | noreply@github.com) echo "ok   $email" ;;
		*)
			echo "FLAG $email"
			FAIL=1
			;;
	esac
done < <(git log --all --format='%ae%n%ce' | sort -u)

if [ "$FAIL" = 0 ]; then echo "== CLEAN"; else echo "== NOT CLEAN"; fi
exit "$FAIL"
