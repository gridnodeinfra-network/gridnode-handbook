# GRID//NODE Credentials — OWNED BY PIPE

**Owner:** Pipe (GRID//NODE founder)
**Custodians:** Mavis / Mavin instances (with explicit Pipe permission)
**Last updated:** 2026-06-22 (after rc27 deploy)

---

## ⚠️ AUTHORITY RULES

These credentials belong to **Pipe**, not to any Mavis/Mavin instance.

**You may:**
- ✅ Read this file on session start (via bootstrap)
- ✅ Use the credentials for routine Mavin work (deploys, pushes, status checks)
- ✅ Use the credentials for testing/verification

**You may NOT:**
- ❌ Share these credentials with anyone outside Mavis/Mavin (no chat logs, no documents, no public files)
- ❌ Use them for anything destructive without explicit Pipe approval (deleting repos, changing billing, rotating keys)
- ❌ Pass them to another session in plaintext
- ❌ Commit them to any repo

**When in doubt:** Ask Pipe before using. "Should I..." is always a fine question.

---

## GitHub

- **Account:** `gridnodeinfra-network` org
- **Primary PAT (push + workflow):** [stored in `/workspace/.gridnode-secrets/.tokens/github_push_workflow.txt`]
  - Scope: repo, workflow (NOT admin or delete)
  - Expires: 2026-12-31
  - Used for: pushing to `gridnode-handbook`, `gridnode-terminal`, future repos
- **Backup PAT (push, no workflow):** [stored in same file]
  - Scope: repo only
  - Used for: when you don't need workflow triggers
- **Read-only PAT:** [stored in same file]
  - Scope: read only
  - Used for: status checks, listing repos

**Repos owned by this org:**
- `gridnodeinfra-network/gridnode-handbook` — public handbook (methodology, bootstrap, deliverables)
- `gridnodeinfra-network/gridnode-terminal` — private app source
- `gridnodeinfra-network/gridnode-mavis-builder` — public builder skill + Foundation

**What you can do without Pipe approval:**
- Push to any of these repos
- Create PRs
- Read/list repos and their contents

**What needs Pipe approval:**
- Delete repos or branches
- Force push to `main`
- Change repo settings (visibility, collaborators, webhooks)
- Rotate/regenerate tokens

---

## Cloudflare

- **Account email:** `R3dp0is0n2012@gmail.com`
- **Account ID:** `f008e0b7e3867a6050b412d931a9abd9`
- **API token:** [stored in `/workspace/.gridnode-secrets/.tokens/cloudflare.txt`]
  - Scope: Pages:Edit, Account:Read
  - Used for: deploying to Cloudflare Pages via wrangler

**Projects owned by this account:**
- `gridnode` (production) — served at `gridnode.network` + `gridnode.pages.dev`

**What you can do without Pipe approval:**
- Deploy to existing Cloudflare Pages projects
- Check deployment status
- Read project settings

**What needs Pipe approval:**
- Create new projects
- Delete projects
- Change billing plan
- Add/remove custom domains
- Rotate API tokens

---

## Surge (DEPRECATED — IP-blocked from sandbox)

- **Login:** `gridnode.mvp@gmail.com`
- **Credentials:** [stored in `/root/.netrc`] (the surge line)
- **Status:** Currently unusable from sandbox (IP-blocked)
- **Note:** Do not attempt to deploy via Surge. Use Cloudflare instead.

---

## Porkbun (domain registrar)

- **Login:** `gridnode.infra@gmail.com`
- **Domain:** `gridnode.network` (registered here)
- **Credentials:** NOT stored in this sandbox (not needed for app work)

---

## How the next Mavis should use this

1. **On bootstrap:** Read this file. Note the credentials exist.
2. **For deploys:** Pipe has historically been okay with us using the GitHub PAT and Cloudflare token for routine deploys. If you're not sure, ask.
3. **For destructive ops:** Always ask Pipe first. Even if "destructive" seems obvious, the call is his.
4. **Never copy-paste these tokens** into chat logs, deliverables, public files, or commits.

---

## If you suspect a credential leak

1. **Don't panic.** Tokens can be rotated.
2. **Tell Pipe immediately** with: which token, when it might have leaked, where.
3. Pipe rotates the token in the relevant service's dashboard.
4. Update this file with the new credential.

---

## Versioning

- v1.0 (2026-06-22): Initial credential store, set up after rc27 deploy
