# skills-analyzer

## Shared scripts

`scripts/list-skill-files-with-token-count.sh` discovers every `SKILL.md` beneath a directory and counts its tokens with `ttok`.

```bash
scripts/list-skill-files-with-token-count.sh repos/example
scripts/list-skill-files-with-token-count.sh --format tsv repos/example
scripts/list-skill-files-with-token-count.sh --output output/example-skill-files.md repos/example
```

Markdown is the default presentation format. The TSV format is intended for skills and other automated consumers; it emits `type`, `path`, and `tokens` columns with a final `total` row. When `--output FILE` is supplied, the script replaces that file atomically after successfully generating the complete report.

## Analyze skills

Run the interactive analysis command with one repository folder beneath `repos/`:

```text
/analyze-skills example
```

The command asks for optional analysis context, processes each `SKILL.md` sequentially, and writes `output/example-skill-analysis.md`. Repositories exceeding 100,000 reported skill tokens require explicit confirmation before analysis.

Run its integration tests with:

```bash
tests/list-skill-files-with-token-count.test.sh
```
