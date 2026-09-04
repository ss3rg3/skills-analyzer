# skills-analyzer

## To-Do's 

This thing is conceptionally trash. It loads the skill files one-by-one into context and then summarizes them, i.e. it 
sends the WHOLE history for every subsequent request. If you want to talk to documents, just load them all at once into context.
If you want to process each, then have external API calls or subagents (if you want to use the subscription).
Just create a Python script that walks the subdirs, provide it with a system prompt from a file, and the content 
of each file as user prompt, store the results into a file. Then a big LLM can summarize or classify them or whatever.  

See `.agents/minimal-one-shot-subagents.md` for using subagents to use your subscription instead. 


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

The command asks for optional analysis context, processes each `SKILL.md` sequentially, and writes `output/<label>-skill-analysis.md`, where `<label>` is the target directory's final path component. Directories exceeding 100,000 reported skill tokens require explicit confirmation before analysis.

Run its integration tests with:

```bash
tests/list-skill-files-with-token-count.test.sh
```
