#!/usr/bin/env bash

set -u

usage() {
    printf 'Usage: %s [--format markdown|tsv] [--output FILE] DIRECTORY\n' "$0" >&2
}

format=markdown
output=

while [[ $# -gt 0 ]]; do
    case $1 in
        --format)
            if [[ $# -lt 2 ]]; then
                usage
                exit 1
            fi
            format=$2
            shift 2
            ;;
        --output)
            if [[ $# -lt 2 ]]; then
                usage
                exit 1
            fi
            if [[ -z $2 ]]; then
                usage
                exit 1
            fi
            output=$2
            shift 2
            ;;
        --)
            shift
            break
            ;;
        -*)
            printf 'Error: unsupported option: %s\n' "$1" >&2
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

if [[ $# -ne 1 ]]; then
    usage
    exit 1
fi

if [[ $format != markdown && $format != tsv ]]; then
    printf 'Error: unsupported format: %s\n' "$format" >&2
    exit 1
fi

directory=$1

if [[ ! -d $directory ]]; then
    printf 'Error: directory not found: %s\n' "$directory" >&2
    exit 1
fi

if ! command -v ttok >/dev/null 2>&1; then
    printf 'Error: ttok is required but is not available on PATH.\n' >&2
    exit 1
fi

if [[ -n $output ]]; then
    case $output in
        */*)
            output_dir=${output%/*}
            output_name=${output##*/}
            [[ -n $output_dir ]] || output_dir=/
            ;;
        *)
            output_dir=.
            output_name=$output
            ;;
    esac

    if [[ -z $output_name || ! -d $output_dir ]]; then
        printf 'Error: output directory not found: %s\n' "$output_dir" >&2
        exit 1
    fi
    if [[ -d $output ]]; then
        printf 'Error: output path is a directory: %s\n' "$output" >&2
        exit 1
    fi
fi

file_list=$(mktemp "${TMPDIR:-/tmp}/list-skill-files.XXXXXX") || {
    printf 'Error: could not create a temporary file.\n' >&2
    exit 1
}
output_temp=
cleanup() {
    rm -f "$file_list"
    if [[ -n $output_temp ]]; then
        rm -f "$output_temp"
    fi
}
trap cleanup EXIT

if ! find "$directory" -type f -name 'SKILL.md' -print0 > "$file_list"; then
    printf 'Error: failed to discover SKILL.md files under: %s\n' "$directory" >&2
    exit 1
fi

files=()
while IFS= read -r -d '' file; do
    if [[ $file == *$'\n'* ]]; then
        printf 'Error: paths containing newlines are not supported: %q\n' "$file" >&2
        exit 1
    fi
    if [[ $format == tsv && $file == *$'\t'* ]]; then
        printf 'Error: paths containing tabs are not supported in TSV output: %q\n' "$file" >&2
        exit 1
    fi
    files[${#files[@]}]=$file
done < "$file_list"

# Sort without GNU-specific sort -z so the script also works on macOS.
for ((i = 1; i < ${#files[@]}; i++)); do
    value=${files[i]}
    j=$((i - 1))
    while ((j >= 0)) && [[ ${files[j]} > "$value" ]]; do
        files[j + 1]=${files[j]}
        ((j--))
    done
    files[j + 1]=$value
done

counts=()
total=0
for file in "${files[@]}"; do
    if ! token_count=$(ttok < "$file"); then
        printf 'Error: ttok failed for: %s\n' "$file" >&2
        exit 1
    fi
    if [[ ! $token_count =~ ^[0-9]+$ ]]; then
        printf 'Error: ttok returned a non-numeric token count for: %s\n' "$file" >&2
        exit 1
    fi

    counts[${#counts[@]}]=$token_count
    ((total += token_count))
done

emit_report() {
    if [[ $format == markdown ]]; then
        printf '| Skill file | Tokens |\n' || return 1
        printf '| --- | ---: |\n' || return 1
        for ((i = 0; i < ${#files[@]}; i++)); do
            display_file=${files[i]//|/\\|}
            printf '| %s | %s |\n' "$display_file" "${counts[i]}" || return 1
        done
        printf '| **Total** | **%s** |\n' "$total" || return 1
    else
        printf 'type\tpath\ttokens\n' || return 1
        for ((i = 0; i < ${#files[@]}; i++)); do
            printf 'skill\t%s\t%s\n' "${files[i]}" "${counts[i]}" || return 1
        done
        printf 'total\t\t%s\n' "$total" || return 1
    fi
}

if [[ -z $output ]]; then
    if ! emit_report; then
        printf 'Error: failed to write the report.\n' >&2
        exit 1
    fi
else
    output_temp=$(mktemp "$output_dir/.${output_name}.XXXXXX") || {
        printf 'Error: could not create a temporary output file in: %s\n' "$output_dir" >&2
        exit 1
    }
    if ! emit_report > "$output_temp"; then
        printf 'Error: failed to write the report: %s\n' "$output" >&2
        exit 1
    fi
    if ! mv "$output_temp" "$output"; then
        printf 'Error: failed to replace the output file: %s\n' "$output" >&2
        exit 1
    fi
    output_temp=
fi
