---
name: opsec-guard
description: Stop and check before anything derived from client or work systems becomes public or leaves the machine. Use whenever the user wants to open-source or publish a repo, make a repository public, push to a new or public remote, create a gist, release or package, post a case study, blog post, LinkedIn post or talk about work done for a client, share logs, screenshots or config in a public issue or forum, deploy a repo to a host that may serve its files, or discovers that something sensitive (a password, API key, client name, domain, server name) was already pushed or published. Also use while writing docs, READMEs, commit messages or examples meant for publication from a session that touched real client sites. Not for private internal sharing or ordinary pushes to an existing private repo.
---

# OPSEC guard

Anything that becomes public stays public: forks, caches and search indexes
keep copies, and deleting a file in a later commit leaves it in history. So
the useful moment to catch a leak is **before** the outward-facing action,
and this skill makes sure you stop there.

Two documents carry the substance; this skill does not repeat them:

- **`docs/opsec/process.md`** (policy): what counts as sensitive (the four
  tiers), who decides, the release gates, and the edge cases.
- **`docs/opsec/runbook.md`** (commands): procedure A pre-publish check, B
  private-then-public release, C what a live site exposes, D leak response,
  E credential rotation.

They live in the `wp-php-upgrade-lab` repository. If you are elsewhere,
find them there (or at
`https://github.com/tony-gilharry/wp-php-upgrade-lab/tree/main/docs/opsec`),
and read the parts you need before acting. `bin/opsec-check.sh <repo-path>`
runs the automated part of the check on any repository.

## Recognise the moment

Stop and run this skill's flow before any of these, even when the user asked
for them directly:

- Changing a repository's visibility to public, creating a public repo, or
  pushing to a remote you have not confirmed is private.
- Creating a gist, release, package, or any shareable link.
- Writing a public post, case study, talk outline or README from work on a
  real site.
- Pasting logs, stack traces, configuration or screenshots into a public
  issue tracker, forum or chat.
- Deploying from a repository that holds anything besides web content, to a
  host that serves the repository root.

A request to "just publish it" is still a request to publish: do the check,
then ask with the evidence in hand. The user decides; your job is that they
decide knowing what is in it.

## You know things the scanners don't

Automated scans only catch what they are told to look for. You have been in
the session: you have seen the client's business name, its domains, its host
install and environment names, people's names and emails, phone numbers,
server paths with usernames, IP addresses and key fingerprints. Use that.

1. Before the check, list every such identifier you saw in this session and
   suggest adding any that are missing to the repository's
   `.opsec-denylist` (gitignored; never committed). Do not paste the list
   into a public place to "check" it.
2. Read your own drafts critically. Text you write repeats details you saw
   earlier: a business type in sample data, an install name in an example
   command, a domain in a URL. Use placeholders (`<prod-env>`,
   `example.com`) in anything that might be published.
3. Fingerprints count too: a full plugin list with versions, distinctive
   content, a themed demo. Generalise them (the process doc's tier 3).

## Say only what is true

Public material carries the user's name, so every claim in it must be real.

- Use only facts the user gave you about **this** piece of work. Never
  borrow numbers, results or details from another project, a case study or
  a doc you happened to read, even if they would make the story stronger:
  that tells readers the user did something they did not do.
- Never invent clients, companies or scenarios to fill a gap. If the story
  needs a detail you do not have, ask for it or leave it out.
- Test data and examples use reserved placeholders (`example.com`,
  `203.0.113.0/24`, "Example Client") and are labelled as synthetic, so no
  one mistakes them for real work.
- When a claim cannot be checked (a version number, a CVE, a result), say
  so and ask the user to confirm it before publishing.
- The process doc, runbook and lab scripts are this skill's references, not
  the user's setup. Do not tell the user "your process says" or assume they
  have `bin/opsec-check.sh`, a Keychain entry or a denylist; offer the tools
  and give the plain commands (`gitleaks`, `git grep`) that work anywhere.

## Before a release

1. Classify what is being published against the four tiers in the process
   doc.
2. Run runbook procedure A (pre-publish check) and read its output.
3. Do a reviewer-style read of every tracked file and of `git log -p --all`,
   including commit messages and authors. If an independent review agent is
   available, give it the files rather than your conclusions.
4. Report with the format below, and wait for the user's decision before
   procedure B (private first, then public).

Anything found **in history** needs a history rewrite (runbook D3) before
release; a new commit that deletes it is not enough.

## When something already leaked

Say so plainly, first, without softening it. Then follow runbook procedure D
in its order: contain, **rotate secrets before cleaning history** (assume
anything that was public has been copied), purge history, ask the host to
clear caches and check forks, verify, and tell the client if their
information was exposed. Do not describe a leak as fixed because a later
commit removed it, or because the repository is now private.

## Habits while working

- Never pass secrets on a command line (other local users can read process
  arguments); feed them through stdin or a config file.
- Keep debug logs and dumps outside any web root and out of Git.
- Commit with a no-reply author email in repositories meant for publication.
- Use dedicated keys and accounts for demo and CI environments.

## Report format

```markdown
## OPSEC check: <what is about to be published, and where>

**Recommendation:** publish / fix first / do not publish

| Check | Result |
|---|---|
| Classification (tiers found) | ... |
| Automated check (runbook A) | CLEAN / findings |
| Session identifiers checked | N terms, added M to the denylist |
| Reviewer read-through | done by ..., findings |

### Findings
- <tier> <what> at <file:line or commit> → <fix>

### Needs your decision
- <anything only the user can decide: consent to name a client, publishing
  a borderline detail, making the repository public>
```
