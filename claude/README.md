claude
======

Claude skills, version-controlled here and symlinked into `~/.claude/skills`
(read by both Claude Code and the Claude desktop app / Cowork).

Setup on a new machine:

```
./claude/link-skills.sh
```

This symlinks each folder under `skills/` into `~/.claude/skills`. It is
idempotent, so re-run it after adding a new skill. Restart the Claude
session or app afterward, since skills are read at startup.

Skills:

- `config-files-skills` - meta-skill: records that skills are version-controlled
  here and that any new skill must be authored into `claude/skills/` (not the
  live `~/.claude/skills`). Knows how to locate this repo across machines.
- `self-hosted-temporal` - deploying, configuring, and securing a self-hosted
  (open-source) Temporal Service: Docker Compose, local dev server, cluster
  config, mTLS, and custom ClaimMapper/Authorizer (OIDC RBAC).

Keep secrets out of skill files, they reference env vars instead.
