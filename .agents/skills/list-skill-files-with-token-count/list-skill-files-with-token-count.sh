#!/usr/bin/env bash

if [[ $# -ne 1 ]]; then
    printf 'Usage: %s DIRECTORY\n' "$0" >&2
    exit 1
fi

if [[ ! -d "$1" ]]; then
    printf 'Error: directory not found: %s\n' "$1" >&2
    exit 1
fi

if ! command -v ttok >/dev/null 2>&1; then
    printf 'Error: ttok is required but is not available on PATH.\n' >&2
    exit 1
fi

total=0

printf '| Skill file | Tokens |\n'
printf '| --- | ---: |\n'

while IFS= read -r -d '' file; do
    token_count=$(ttok < "$file")
    printf '| %s | %s |\n' "$file" "$token_count"
    ((total += token_count))
done < <(find "$1" -type f -name 'SKILL.md' -print0 | sort -z)

printf '| **Total** | **%s** |\n' "$total"
