#!/bin/bash
# Pre-publish check: nothing private in the working tree or anywhere in history.
#   bin/opsec-check.sh
# 1. gitleaks over the full history (secrets, keys, tokens).
# 2. Every string in .opsec-denylist (gitignored, one per line: real install
#    names, domains, client names, emails, phone numbers) searched in tracked
#    files and in every commit's content, author and message.
# 3. Commit author emails must be GitHub no-reply addresses.
# Exit status 0 means clean.
. "$(dirname "$0")/lib.sh"

FAIL=0

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
if [ -f .opsec-denylist ]; then
	while IFS= read -r term || [ -n "$term" ]; do
		case $term in '' | '#'*) continue ;; esac
		hits=""
		[ ${#REVS[@]} -gt 0 ] && hits=$(git grep -i -F -l -e "$term" "${REVS[@]}" -- 2>/dev/null | head -5)
		hits+=$(git log --all -i -F --format='%h %an <%ae> %s' --grep="$term" | head -3)
		hits+=$(git grep -i -F -l -e "$term" -- . 2>/dev/null | head -5)
		if [ -n "$hits" ]; then
			echo "FOUND: (term #$(grep -n -F -x -- "$term" .opsec-denylist | cut -d: -f1) in .opsec-denylist)"
			echo "$hits" | sed 's/^/    /'
			FAIL=1
		fi
	done < .opsec-denylist
	echo "checked $(grep -cvE '^(#|$)' .opsec-denylist) terms"
else
	echo "no .opsec-denylist: create one with the real names that must never appear"
	FAIL=1
fi

echo "== commit identities"
git log --all --format='%ae%n%ce' | sort -u | while read -r email; do
	case $email in
		*@users.noreply.github.com | noreply@github.com) echo "ok   $email" ;;
		*) echo "FLAG $email"; echo 1 > .local/opsec-flag ;;
	esac
done
if [ -f .local/opsec-flag ]; then
	rm -f .local/opsec-flag
	FAIL=1
fi

[ "$FAIL" = 0 ] && echo "== CLEAN" || echo "== NOT CLEAN"
exit "$FAIL"
