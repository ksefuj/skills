# CLAUDE.md

Claude skills for Polish KSeF FA(3) e-invoicing. Part of the ksefuj project
([ksefuj.to](https://ksefuj.to), monorepo at [ksefuj/ksefuj](https://github.com/ksefuj/ksefuj)).

## Layout

- `skills/<name>/SKILL.md` — skill entry point with YAML frontmatter (`name`, `description`)
- `skills/<name>/references/` — bundled extracts, loaded on demand
- `.claude-plugin/marketplace.json` — Claude Code plugin marketplace manifest; list new skills here
- `.github/workflows/release.yml` — packages `.skill` files on `v*` tags

## Rules

- Every tax or schema claim must trace to the canonical sources in ksefuj/ksefuj
  (`packages/validator/docs/fa3-information-sheet.md`,
  `docs/knowledge-base/briefs/podrecznik-ksef-20-czesc-ii.md`). Never invent rules.
- Skills must stay self-contained: never reference files outside the skill folder at runtime.
- XML examples must pass `npx @ksefuj/validator`.
- Prose in English; FA(3) element names (`Podmiot1`, `FaWiersz`, `Adnotacje`) stay as in the schema.
- Conventional commits (`feat(skill):`, `fix(skill):`, `docs:`).
