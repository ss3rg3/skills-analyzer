---
name: list-skill-files-with-token-count
description: Generate a Markdown table of every SKILL.md file in a repository under ./repos and its ttok token count.
disable-model-invocation: true
---

# List Skill Files With Token Count

Use the repository-folder name supplied by the invoking request. Look for that folder beneath `./repos/` and generate `output/{folder-name}-skill-files.md` at the repository root.

Before doing anything else:

1. If the invoking request does not provide exactly one repository-folder name, the name contains a path separator, or `./repos/{folder-name}` is not a folder, respond with a message beginning `🔴` and stop.
2. If the output file already exists, respond with a message beginning `🔴` that names the file and asks the user to explicitly confirm overwriting it. Stop until that confirmation is received.

After all checks pass, run the repository's shared script from the workspace root:

```bash
list_skill_tokens_folder_name="<repository-folder name from the invoking request>"
scripts/list-skill-files-with-token-count.sh \
    --output "output/${list_skill_tokens_folder_name}-skill-files.md" \
    "repos/$list_skill_tokens_folder_name"
```

Tell the user the path of the generated file. The script produces the Markdown table, including the total token count. Its default output is Markdown; other skills that need machine-readable results may pass `--format tsv` before the folder argument.

Do not check `ttok` yourself. If the script exits unsuccessfully, respond with a message beginning `🔴` that warns the user about the script failure, then stop.
