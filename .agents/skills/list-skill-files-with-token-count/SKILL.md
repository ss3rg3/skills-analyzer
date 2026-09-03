---
name: list-skill-files-with-token-count
description: Generate a Markdown table of every SKILL.md file under a given directory path (relative or absolute) and its ttok token count.
disable-model-invocation: true
---

# List Skill Files With Token Count

Use the directory path supplied by the invoking request. The path may be relative (resolved from the workspace root) or absolute. Generate `output/{label}-skill-files.md` at the repository root, where `{label}` is the target directory's final path component as derived below.

Before doing anything else:

1. If the invoking request does not provide exactly one directory path, or the given path is not a folder, respond with a message beginning `🔴` and stop.
2. Derive `{label}` from the target path: strip trailing slashes (unless the path is exactly `/`), then take the text after the last `/` (or the whole path if it contains no `/`). If the path is exactly `/`, or the label is empty, `.`, or `..`, respond with a message beginning `🔴` and stop because no safe output name can be derived.
3. If the output file already exists, respond with a message beginning `🔴` that names the file and asks the user to explicitly confirm overwriting it. Stop until that confirmation is received.

After all checks pass, run the repository's shared script from the workspace root, passing the target path as a single quoted argument (it may contain spaces):

```bash
list_skill_tokens_target="<directory path from the invoking request>"
list_skill_tokens_label="<derived {label}>"
scripts/list-skill-files-with-token-count.sh \
    --output "output/${list_skill_tokens_label}-skill-files.md" \
    "$list_skill_tokens_target"
```

Tell the user the path of the generated file. The script produces the Markdown table, including the total token count. Its default output is Markdown; other skills that need machine-readable results may pass `--format tsv` before the directory argument.

Do not check `ttok` yourself. If the script exits unsuccessfully, respond with a message beginning `🔴` that warns the user about the script failure, then stop.
