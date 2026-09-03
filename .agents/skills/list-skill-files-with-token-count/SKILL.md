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

After all checks pass, set `list_skill_tokens_dir` to the absolute directory containing this loaded `SKILL.md`. Run the bundled script with `./repos/{folder-name}` and write its standard output to the output file. Resolve the repository root from `list_skill_tokens_dir` so the command works from any current directory:

```bash
list_skill_tokens_dir="/absolute/path/to/.agents/skills/list-skill-files-with-token-count"
list_skill_tokens_repo_root="$(cd "$list_skill_tokens_dir/../../.." && pwd)"
list_skill_tokens_folder_name="<repository-folder name from the invoking request>"
list_skill_tokens_folder="$list_skill_tokens_repo_root/repos/$list_skill_tokens_folder_name"
"$list_skill_tokens_dir/list-skill-files-with-token-count.sh" "$list_skill_tokens_folder" > "$list_skill_tokens_repo_root/output/${list_skill_tokens_folder_name}-skill-files.md"
```

Tell the user the path of the generated file. The script produces the Markdown table, including the total token count.

Do not check `ttok` yourself. If the script exits unsuccessfully, respond with a message beginning `🔴` that warns the user about the script failure, then stop.
