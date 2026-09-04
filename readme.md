# skills-analyzer

## Shared scripts

`scripts/list-skill-files-with-token-count.sh` discovers every `SKILL.md` beneath a given directory (relative or absolute) and counts its tokens with `ttok`.

```bash
scripts/list-skill-files-with-token-count.sh path/to/skills
scripts/list-skill-files-with-token-count.sh --format tsv path/to/skills
scripts/list-skill-files-with-token-count.sh --output output/skills-skill-files.md path/to/skills
```

Markdown is the default presentation format. The TSV format is intended for skills and other automated consumers; it emits `type`, `path`, and `tokens` columns with a final `total` row. When `--output FILE` is supplied, the script replaces that file atomically after successfully generating the complete report.

## Analyze skills

Run the interactive analysis command with any directory path (relative or absolute):

```text
/analyze-skills path/to/skills
```

The command asks for optional analysis context, analyzes one `SKILL.md` per isolated read-only subagent in parallel batches of up to eight, and writes `output/<label>-skill-analysis.md`, where `<label>` is the target directory's final path component. Detail sections remain in the token listing's deterministic path order regardless of worker completion order.

Run its integration tests with:

```bash
tests/list-skill-files-with-token-count.test.sh
```
