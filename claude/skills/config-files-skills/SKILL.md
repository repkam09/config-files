---
name: config-files-skills
description: Use this skill whenever you create, author, draft, edit, improve, package, or install a Claude skill for Mark, or when Mark mentions his "config-files" repo, dotfiles, or managing skills across machines. It records that Mark keeps version-controlled skills in his config-files git repo and that any NEW skill must be authored INTO that repo (under claude/skills/), not directly into the live ~/.claude/skills folder. Always consult this skill before writing a new SKILL.md so the skill lands in the right place and stays in version control.
metadata:
  version: 0.1.0
---

# Skill: config-files-skills

## Why this skill exists

Mark version-controls his Claude skills in a `config-files` git repo and syncs them across machines with symlinks. The live skills directory (`~/.claude/skills`) is treated as generated output, not the source of truth. So any skill we build together must be authored into the repo, then symlinked, so it survives reinstalls and travels between machines.

If a new skill is written straight into `~/.claude/skills`, it is effectively untracked and will be lost or drift out of sync. Avoid that.

## Locating the config-files repo

The repo path differs per machine. Detect it rather than assuming:

```bash
CONFIG_FILES=""
for p in \
  "${CONFIG_FILES_DIR:-}" \
  "/Volumes/Personal/config-files" \
  "/home/mark/Software/config-files" \
  "$HOME/Software/config-files" \
  "$HOME/config-files"; do
  if [ -n "$p" ] && [ -d "$p/.git" ]; then CONFIG_FILES="$p"; break; fi
done
echo "${CONFIG_FILES:-NOT_FOUND}"
```

Known locations so far:
- macOS: `/Volumes/Personal/config-files`
- Linux: `/home/mark/Software/config-files`

If detection returns `NOT_FOUND`, ask Mark for the path instead of guessing, and consider suggesting he export `CONFIG_FILES_DIR` so future sessions find it automatically. In Cowork, the repo must be a connected folder before you can write to it; request access to the detected path if it is not already mounted.

Skills live at `<config-files>/claude/skills/<skill-name>/`. The symlink bootstrap is `<config-files>/claude/link-skills.sh`.

## Creating a new skill (the rule)

1. Author the skill directly under `<config-files>/claude/skills/<skill-name>/`, with `SKILL.md` plus any `references/`, `scripts/`, or `assets/`. Use the `skill-creator` skill for the authoring methodology (drafting the description, structure, references, evals); this skill only governs WHERE the result goes.
2. Do not write the new skill into `~/.claude/skills` directly. That folder is populated by symlinks, not hand-authored files.
3. After authoring, link it so it becomes active:

   ```bash
   "<config-files>/claude/link-skills.sh"
   ```

   The script symlinks every folder under `claude/skills/` into `~/.claude/skills`. It is idempotent. Note that skills are read at session/app startup, so a restart is needed to pick up a brand-new or edited skill.
4. Remind Mark to commit:

   ```bash
   cd "<config-files>" && git add claude && git commit -m "Add <skill-name> skill"
   ```

## Editing or improving an existing skill

Edit the copy under `<config-files>/claude/skills/<skill-name>/`, never the symlink target's resolved path elsewhere. Because `~/.claude/skills/<name>` is a symlink back into the repo, edits in the repo are immediately the live version (after a restart). Then commit as above.

## Installed-elsewhere gotcha

If a skill of the same name was previously installed via the desktop app's "Save skill" or ZIP upload, a real (non-symlink) folder may already sit at `~/.claude/skills/<name>`. `ln -sfn` will not replace a real directory, so remove that copied folder first, then run `link-skills.sh` so the symlink takes its place.

## Hygiene

Keep secrets out of skill files, since the repo travels between machines and may have remotes. Reference environment variables instead.
