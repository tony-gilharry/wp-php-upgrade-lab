# Runbook: OPSEC for publishing and maintaining a public repo

**Owner:** Repository maintainer | **Frequency:** Before every release; as needed for incidents
**Last Updated:** 2026-10-24 | **Last Run:** 2026-10-24 (pre-publish check)

### Purpose

The commands for the [OPSEC process](process.md): the pre-publish gate, a
private-then-public release, checking what a live site exposes, leak
response, and credential rotation. The *why* and *who decides* are in the
process document; this page is only *how*.

Run everything from the repository root. Replace `OWNER/REPO`, `DOMAIN`
and `<env>` with real values **in your terminal only**, never in tracked
files.

### Prerequisites
- [ ] `git`, `gh` (logged in as the account that will own the repo), `jq`, `curl`
- [ ] `gitleaks` (`brew install gitleaks`) and `git-filter-repo` (`brew install git-filter-repo`) for history work
- [ ] A local `.opsec-denylist` (gitignored): one case-insensitive term per line, every Tier 2 identifier from the [process](process.md#what-counts-as-sensitive)
- [ ] Access to the host's portal (key and credential rotation)

---

## Procedure A: Pre-publish check

Run before the first push to a public remote and before every release.

#### A1: Confirm the denylist exists and is not tracked
```bash
test -s .opsec-denylist && git check-ignore -q .opsec-denylist && echo "denylist ok"
```
**Expected result:** `denylist ok`
**If it fails:** create `.opsec-denylist` (install names, domains, client and business names, emails, phone numbers, local usernames, key fingerprints) and make sure `.gitignore` lists it.

#### A2: Run the automated gate
```bash
bin/opsec-check.sh                    # this repository
<lab>/bin/opsec-check.sh /path/to/repo  # any other repository (uses its .opsec-denylist)
```
**Expected result:** gitleaks reports no leaks, `checked N terms` with no `FOUND` lines, every commit identity `ok`, final line `== CLEAN`, exit status 0.
**If it fails:** fix each finding. A finding inside history (not just the working tree) needs Procedure D step D3 to rewrite history, then run A2 again.

#### A3: Inventory tracked files for things that should never be there
```bash
git ls-files | grep -Ei '(^|/)(\.env$|wp-config\.php$|.*\.(sql|sql\.gz|pem|key|p12)$|id_(rsa|ed25519|ecdsa)$|.*\.log$)' || echo "none"
git ls-files -z | xargs -0 du -k 2>/dev/null | sort -n | tail -10
```
**Expected result:** `none`, and no unexpectedly large files (database dumps, archives, media from a real site).
**If it fails:** `git rm --cached <file>`, add it to `.gitignore`, and if it was ever committed, rewrite history (D3).

#### A4: Human read-through
```bash
git log --all --format='%h %an <%ae> | %cn <%ce> | %s' | less
git log -p --all | less
```
**Expected result:** a Reviewer (a second person, a second sitting, or an independent review agent given the files) finds no Tier 1 to 3 material, including in AI-written docs and commit messages.
**If it fails:** fix, rewrite history if needed, restart at A2.

---

## Procedure B: Private-then-public release (GitHub)

#### B1: Create the repository private and push
```bash
gh auth status                                  # confirm the active account owns OWNER
gh repo create OWNER/REPO --private --source=. --remote=origin --push
```
**Expected result:** the repository exists, private, with your commits.
**If it fails:** wrong account: `gh auth switch --user OWNER` and retry.

#### B2: Review it as the public will
Open `https://github.com/OWNER/REPO` and read the rendered README, the file
tree, and the commit list (authors and messages).
**Expected result:** nothing you would not show a stranger.

#### B3: Make it public
```bash
gh repo edit OWNER/REPO --visibility public --accept-visibility-change-consequences
```
**Expected result:** `curl -s -o /dev/null -w '%{http_code}\n' https://github.com/OWNER/REPO` returns `200` without logging in.

#### B4: Protect the default branch
```bash
for f in .github/rulesets/*.json; do gh api -X POST repos/OWNER/REPO/rulesets --input "$f"; done
gh api repos/OWNER/REPO/rulesets --jq '.[] | "\(.name): \(.enforcement)"'
```
**Expected result:** `Protect main: active` (no force pushes or deletion, no
bypass) and `Require CI: active` (pull requests need the CI checks;
repository admins may push directly).
**If it fails:** rulesets on private repositories need a paid plan; apply
them right after B3 makes the repository public.

#### B5: Turn on secret scanning and push protection
```bash
gh api -X PATCH repos/OWNER/REPO \
  -f 'security_and_analysis[secret_scanning][status]=enabled' \
  -f 'security_and_analysis[secret_scanning_push_protection][status]=enabled'
gh api repos/OWNER/REPO --jq '.security_and_analysis'
```
**Expected result:** both show `"status": "enabled"`. These are free on public repositories; on private repositories they need GitHub's paid secret protection.
**If it fails:** enable them in the repository's Settings → Code security.

---

## Procedure C: Check that nothing from the repo is served from a live site

Run after any deploy from a repository that contains more than web content.

#### C1: Request every top-level repository path from the site
```bash
DOMAIN=example.com
for f in $(git ls-tree --name-only HEAD | grep -v '^wp-content$'); do
  printf '%s %s\n' "$(curl -s -o /dev/null -w '%{http_code}' "https://$DOMAIN/$f")" "$f"
done
```
**Expected result:** every line `403` or `404`.
**If it fails:** a `200` means the file is public. Remove it from the server (deploy only `wp-content` from now on: `bin/deploy-wpengine.sh`), and treat it as a leak (Procedure D) if it held anything Tier 1 or 2.

#### C2: Check for public debug logs
```bash
for p in wp-content/debug.log wp-content/debug-staging.log _wpeprivate/debug-lab.log; do
  printf '%s %s\n' "$(curl -s -o /dev/null -w '%{http_code}' "https://$DOMAIN/$p")" "$p"
done
```
**Expected result:** `403` or `404` for every path.
**If it fails:** delete the log on the server and move logging outside the web root (on WP Engine, `_wpeprivate/`).

---

## Procedure D: Leak response

Something Tier 1 or 2 is in public material. Work in this order: the
secret must be assumed copied the moment it became public, so rotation
comes before cleanup.

#### D1: Contain
```bash
gh repo edit OWNER/REPO --visibility private --accept-visibility-change-consequences   # a repo
```
For a file served from a live site, delete it on the server (Procedure C).
**Expected result:** the material is no longer reachable by URL.
**Note:** public forks are not made private with the original. List them with `gh api repos/OWNER/REPO/forks --jq '.[].full_name'` and include them in D4.

#### D2: Rotate every exposed secret
Follow Procedure E for each Tier 1 item **before** cleaning history.
**Expected result:** the leaked values no longer work.

#### D3: Purge it from history
```bash
git clone --mirror https://github.com/OWNER/REPO.git repo-purge.git && cd repo-purge.git
git filter-repo --path .env --invert-paths      # a whole file: removes it from every commit
git push --force --mirror origin
```
For a string inside a file that must stay, create `../replacements.txt` **in an
editor** (one `old==>REDACTED` rule per line), never with `echo` or `printf`,
which would write the secret into your shell history, then run
`git filter-repo --replace-text ../replacements.txt` and push as above. Delete
the file afterwards.

Branch protection blocks the force push: temporarily set the "Protect main"
ruleset's enforcement to `disabled` (repository Settings → Rules →
Rulesets), push, then set it back to `active` and confirm with
`gh api repos/OWNER/REPO/rulesets`.

**Expected result:** in a fresh clone, `git log --all -- .env` prints nothing,
or a search for a fragment of the leaked value finds nothing.
**If it fails:** `filter-repo` removes the `origin` remote after rewriting; re-add it with `git remote add origin <url>` before pushing. Collaborators must re-clone; old clones still contain the data.

#### D4: Ask the host to clear cached copies
Ask GitHub Support to remove cached views and unreferenced commits for the
repository, giving the old commit SHAs
(<https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository>).
Ask fork owners to delete their forks.
**Expected result:** old commit URLs return 404.

#### D5: Verify and notify
```bash
bin/opsec-check.sh
```
**Expected result:** `== CLEAN`. Then tell the client if their information was exposed, and write an incident note (what, when, how found, how fixed) in the History table below.

---

## Procedure E: Rotate credentials

#### E1: WP Engine SSH key (gateway and Git push)
```bash
ssh-keygen -t ed25519 -C "<purpose>" -f ~/.ssh/<new-key>
ssh-add --apple-use-keychain ~/.ssh/<new-key>
pbcopy < ~/.ssh/<new-key>.pub
```
Add the public key in the portal: **Profile → SSH Keys** (gateway) and
**Git push → Add developer** on each environment. Point `IdentityFile` in
`~/.ssh/config` at the new key, then test:
```bash
ssh -T git@git.wpengine.com info                   # lists the installs this key can push to
ssh <env>@<env>.ssh.wpengine.net 'php -v'
```
**Expected result:** both succeed with the new key. Then delete the old key in both portal places and locally (`rm ~/.ssh/<old-key> ~/.ssh/<old-key>.pub`), and confirm the old key is refused.

#### E2: WP Engine API credentials
Regenerate them in the portal under **API Access**, then replace the
Keychain entry:
```bash
security delete-generic-password -s wpe-api
security add-generic-password -s wpe-api -a <API-user-ID> -w
bin/wpe-api.sh status
```
**Expected result:** `status` succeeds with the new credentials; the old ones return HTTP 401.

#### E3: GitHub token
```bash
gh auth logout --user OWNER && gh auth login
```
Revoke any personal access tokens that may have leaked at
`https://github.com/settings/tokens`.
**Expected result:** `gh auth status` shows the new login; the old token is gone from the list.

#### E4: WordPress secrets (if `wp-config.php` or a database dump leaked)
```bash
ssh <env>@<env>.ssh.wpengine.net 'bash -s' <<'EOF'
cd ~/sites/<env> && wp config shuffle-salts
EOF
```
Reset administrator passwords, and ask the host to rotate the database
password (on WP Engine, through support).
**Expected result:** every logged-in session is ended; the leaked password
hashes and salts no longer work.

---

### Verification
- [ ] `bin/opsec-check.sh` ends with `== CLEAN`
- [ ] A3 lists no forbidden file types
- [ ] C1 and C2 return only `403`/`404` on every live site deployed from this repo
- [ ] Both rulesets show `active` (B4); secret scanning and push protection show `enabled` (B5)
- [ ] After any incident: rotated credentials tested, old ones refused

### Troubleshooting
| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `opsec-check.sh` flags a commit email | Committed with a personal address | `git config user.email <id>+<user>@users.noreply.github.com`, then rewrite history with `git filter-repo --mailmap` |
| A denylist term matches inside unrelated words | The term is too short or generic | Use a longer, more specific term in `.opsec-denylist` |
| gitleaks flags a sample value in docs or vendored code | Example credentials that look real (e.g. a library README's sample private key) | Confirm it is a published example, then add its fingerprint to `.gitleaksignore` with a comment saying why; never ignore a whole rule or path |
| A deleted file is still downloadable from the live site | The host leaves files from a first deploy in place | Delete it on the server by hand (Procedure C) |
| `gh repo edit --visibility` refused | Organisation policy or wrong account | `gh auth switch`, or change it in the repository settings |

### Rollback
- Visibility: `gh repo edit OWNER/REPO --visibility private --accept-visibility-change-consequences`.
- History rewrites cannot be undone on the remote. Keep the mirror clone from D3 **encrypted and offline** until the incident is closed, then delete it: it still contains the leak.
- A rotated credential cannot be un-rotated; that is the point.

### Escalation
| Situation | Contact | Method |
|-----------|---------|--------|
| Cached views or forks still show leaked data | GitHub Support | `https://support.github.com` |
| Database password or server-level secret exposed | The host's support | WP Engine: portal chat or ticket |
| A client's information was exposed | The client's named contact | Direct message, then written follow-up |

### History
| Date | Run By | Notes |
|------|--------|-------|
| 2026-10-24 | Maintainer | Pre-publish check before the first public release of this repository. |
