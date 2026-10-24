# Process Document: Publishing open-source work derived from client work

**Owner:** Repository maintainer | **Last Updated:** 2026-10-24 | **Review Cadence:** Before every first public release, and annually

This is the *policy and process*: what counts as sensitive, who decides,
and the gates a release passes. The step-by-step commands live in the
[OPSEC runbook](runbook.md). The [`opsec-guard` skill](../../.claude/skills/opsec-guard/SKILL.md)
makes Claude follow both.

### Purpose

Consultants and agencies learn the most useful lessons on client sites. This
process lets that knowledge be shared publicly (tools, playbooks, case
studies) **without exposing a client, a site, a credential or the
maintainer's own infrastructure**. A leak cannot be fully undone once a
repository is public: forks, caches and search indexes keep copies. So the
process puts its effort before publication.

### Scope

**In scope**
- Any public repository, gist, package, blog post, talk or artifact whose
  content was derived from work on a client's or employer's systems.
- Code, docs, commit history, commit metadata (author emails), screenshots,
  logs, sample data and AI-assisted text in those artifacts.
- The maintainer's own access material used along the way (SSH keys, API
  credentials, host accounts).

**Out of scope**
- The private client repositories themselves (governed by the client
  agreement), except that they are the *source* this process filters.
- Incident response for a compromise of a client site (that is the client's
  security process; this process covers leaks *from* published material).

### What counts as sensitive

| Tier | What | Examples | Rule |
|---|---|---|---|
| 1. Secrets | Anything that grants access | Passwords, API keys and tokens, SSH private keys, `wp-config.php`, database dumps, session cookies, `.env` files | **Never published.** A leak triggers rotation, not just deletion. |
| 2. Identifiers | Anything that points at a real client, site or account | Client and business names, domains, host install/environment names, emails, phone numbers, street addresses, analytics and pixel IDs, server IPs, SSH usernames, key fingerprints, local paths with usernames | **Not published** without the client's written consent. Use placeholders. |
| 3. Fingerprints | Details that are harmless alone but identify in combination | The exact plugin list with versions, distinctive content or wording, industry-themed sample data, screenshots of a real site, a branded theme | **Generalise** ("a premium SEO plugin with a lapsed license"), or replace with synthetic material. |
| 4. Public facts | Already public and not tied to the client | CVE identifiers, a plugin's public changelog, a host's public documentation, generic error messages | Publish freely, with sources. |

When unsure between two tiers, treat it as the higher one.

### RACI Matrix

| Step | Responsible | Accountable | Consulted | Informed |
|------|------------|-------------|-----------|----------|
| 1. Classify source material | Author | Maintainer | Client (if anything Tier 2 is wanted) | — |
| 2. Start a separate public repo | Author | Maintainer | — | — |
| 3. Abstract and anonymise | Author | Maintainer | Client (case studies) | — |
| 4. Identity and access hygiene | Author | Maintainer | — | — |
| 5. Pre-publish review gate | Author + Reviewer | Maintainer | — | — |
| 6. Private, then public release | Maintainer | Maintainer | Reviewer | Client (if named) |
| 7. Post-release monitoring | Maintainer | Maintainer | — | — |
| 8. Leak response | Maintainer | Maintainer | Client, host support | Client, affected parties |

For a solo consultant, Author, Reviewer and Maintainer can be one person,
but the **Reviewer pass must be a separate sitting** (or a second person,
or an independent review agent given the files, not the author's
conclusions). The author reliably misses their own leaks.

### Process Flow

```
 client work (private)
        │
        ▼
 [1] classify ──► Tier 1/2 needed? ──yes──► client consent ──no──► drop it
        │ no
        ▼
 [2] new public repo (fresh history, no copied .git)
        │
        ▼
 [3] abstract: placeholders, synthetic demo, generalised case study
        │
        ▼
 [4] identity hygiene: no-reply author email, dedicated keys, local denylist
        │
        ▼
 [5] GATE: automated scans + human read-through ──fail──► fix, rewrite history, repeat [5]
        │ pass
        ▼
 [6] publish PRIVATE ─► reviewer reads it on the host ─► flip to PUBLIC
        │
        ▼
 [7] monitor (secret scanning alerts, denylist re-check on each release)
        │ leak found
        ▼
 [8] leak response (runbook): contain → rotate → purge → verify → notify
```

### Detailed Steps

#### Step 1: Classify the source material
- **Who**: Author
- **When**: Before writing anything intended for publication.
- **How**: List what the public artifact needs from the client work (a
  technique, numbers, a code pattern, a story). Classify each item with the
  tier table. Tier 1 is out. Tier 2 is out unless the client agrees in
  writing to be named. Tier 3 gets generalised or replaced.
- **Output**: A short list of what will be shared, at which level of detail.

#### Step 2: Start a separate public repository
- **Who**: Author
- **When**: Before the first public commit.
- **How**: Create the public project from scratch. Never make a client repo
  public, never copy its `.git` directory, never fork it. Deleting a file in
  a later commit does not remove it from history.
- **Output**: An empty repository with no shared history.

#### Step 3: Abstract and anonymise
- **Who**: Author
- **When**: While building the public material.
- **How**:
  - Environment, site and account names become placeholders (`<prod-env>`)
    in tracked files; real values live only in gitignored local config.
  - Real sites are replaced by a **synthetic demo** that reproduces the
    behaviour (a plugin written to fail the same way), or by a site the
    maintainer owns outright.
  - Case studies describe categories ("a closed block library"), not the
    stack, and say "a site I manage" instead of naming the client.
  - Sample content is neutral: no hints at the client's industry or
    location.
  - Real data (database dumps, uploads, logs, screenshots) never enters the
    public repo, even temporarily.
- **Output**: Material that teaches the lesson and identifies no one.

#### Step 4: Identity and access hygiene
- **Who**: Author
- **When**: When the repo is created, and when access is set up for any
  demo or CI environment.
- **How**:
  - Commit as the hosting service's no-reply address unless a public email
    is intended.
  - Keep a **local denylist** of every Tier 2 string (gitignored, never
    published) for the automated checks to search for.
  - Use a **dedicated SSH key and, where the host allows, a dedicated
    account** for demo and CI environments, so a leaked lab credential
    cannot reach client sites.
  - Never put a personal key or credential in automation; never pass
    secrets on a command line where other local users can read them.
- **Output**: A repository whose metadata and tooling cannot point back at
  client access.

#### Step 5: Pre-publish review gate
- **Who**: Author runs the checks; Reviewer reads.
- **When**: Before the first push to any remote that is or will become
  public, and before every release.
- **How**: Run the runbook's *Pre-publish check* procedure: secret scan of
  the full history, denylist search of every commit's content, authors and
  messages, author-email check, and a link and file-inventory review. Then
  the Reviewer reads every tracked file and the full `git log -p` with the
  tier table in hand, including AI-generated text, which repeats names it
  saw earlier.
- **Output**: A pass, or a list of findings. Any finding in history means a
  history rewrite before release, then the gate runs again from the start.

#### Step 6: Publish privately, then publicly
- **Who**: Maintainer
- **When**: After the gate passes.
- **How**: Push to a **private** repository first, turn on the host's secret
  scanning and push protection, and have the Reviewer look at it as the
  public will (rendered README, file browser, commit list). Only then change
  visibility to public. Tell the client first if they are named.
- **Output**: A public repository that has been seen once, in its final
  form, by someone looking for leaks.

#### Step 7: Monitor after release
- **Who**: Maintainer
- **When**: Continuously, and before each release.
- **How**: Keep secret-scanning alerts on, re-run the gate before each
  release, and re-check anything a deployment serves publicly (a pushed
  repository root can be downloadable from a live site).
- **Output**: Early warning.

#### Step 8: Respond to a leak
- **Who**: Maintainer
- **When**: Any Tier 1 or Tier 2 item is found in public material.
- **How**: Follow the runbook's *Leak response*: contain (make private or
  remove the file from the live site), rotate any Tier 1 secret
  **first**, purge history, ask the host to clear caches, verify, and
  notify the client if their information was exposed. Rotation comes before
  cleanup because a secret must be assumed copied the moment it was public.
- **Output**: A closed incident with a written note of cause and fix.

### Exceptions and Edge Cases

| Scenario | What to Do |
|----------|-----------|
| The client wants to be credited | Get written consent naming exactly what may be published; keep it with the project records. Everything not listed stays Tier 2. |
| The work was on a site the maintainer owns (a demo site) | Its code may be published, but its **install names, domains and account details** stay out of the repo; use local config. |
| A tool was deployed to a live site from a repo that also holds tooling | Treat as a possible leak: the repo root may be served publicly. Check the live URLs; deploy only the web content from then on. |
| A debug log was written inside the web root | Treat as a leak of server paths and errors: delete it, check it is no longer served, keep future logs in a non-public directory. |
| Sample content hints at the client's industry | Replace it with neutral data before release, and rewrite history if it was committed. |
| AI-generated docs or commit messages mention a real name | Same as any Tier 2 finding: fix and rewrite history. AI assistants repeat what they saw in the session. |
| A finding is in the history of an already-public repo | Leak response (step 8), not a quiet fix commit. |
| A third-party plugin or theme is included in an example | Check its license allows redistribution, and that it carries no client branding or configuration. |
| Unsure whether something is sensitive | Treat it as the higher tier and ask the Reviewer. |

### Metrics

| Metric | Target | How to Measure |
|--------|--------|----------------|
| Denylist and secret-scan findings at first public release | 0 | Pre-publish check output |
| Releases that went private → public with a reviewer pass | 100% | Release notes |
| Time from finding a Tier 1 leak to rotation | < 1 hour | Incident note timestamps |
| Public repositories with secret scanning and push protection on | 100% | Repository settings |
| Client-identifying details published without written consent | 0 | Reviewer pass, incident log |

### Related Documents
- [OPSEC runbook](runbook.md): the commands for every step above.
- [`opsec-guard` skill](../../.claude/skills/opsec-guard/SKILL.md): how Claude applies this process.
- [`bin/opsec-check.sh`](../../bin/opsec-check.sh): the automated part of the gate.
- [Gotchas](../gotchas.md): items 11, 15 and 18 cover the OPSEC risks of deploying to WP Engine.
