# CLAUDE.md

Claude skills for Polish KSeF FA(3) e-invoicing. Part of the ksefuj project
([ksefuj.to](https://ksefuj.to), monorepo at [ksefuj/ksefuj](https://github.com/ksefuj/ksefuj)).

## Layout

- `skills/<name>/SKILL.md`: skill entry point with YAML frontmatter (`name`, `description`)
- `skills/<name>/references/`: bundled extracts, loaded on demand
- `.claude-plugin/marketplace.json`: Claude Code plugin marketplace manifest; list new skills here
- `.github/workflows/release.yml`: packages every `skills/*` folder as a `.skill` file on `v*` tags

## Rules

- Every tax or schema claim must trace to the canonical sources in ksefuj/ksefuj
  (`packages/validator/docs/fa3-information-sheet.md`,
  `docs/knowledge-base/briefs/podrecznik-ksef-20-czesc-ii.md`). Never invent rules.
- Skills must stay self-contained: never reference files outside the skill folder at runtime. Skill
  files carry no maintainer notes and no links to the canonical sources; those live here.
- Skill text is loaded into a model's context. Keep it short and plain: no emoji, no shouted
  intensifiers, no counts or dates that go stale. Write descriptions in the third person with
  concrete trigger terms.
- XML examples must pass `npx @ksefuj/validator`.
- Prose in English; FA(3) element names (`Podmiot1`, `FaWiersz`, `Adnotacje`) stay as in the schema.
- Conventional commits (`feat(skill):`, `fix(skill):`, `docs:`).

## Maintenance

- The skills cite validator issue codes (`issue.code.code`, for example `P12_ENUMERATION`), defined
  in `packages/validator/src/error-codes.ts` in ksefuj/ksefuj. After a validator release, compare
  the "Validator Issue Codes" tables in `skills/ksef-invoice/SKILL.md` against that file.
- After an FA(3) schema update (`pnpm update-schemas` in the monorepo), update
  `fa3-information-sheet.md` there first, then the affected skill extracts here, then re-run
  `npx @ksefuj/validator` on every example XML in the skills.
- Reference extracts are deliberately partial copies. Full copies drift, and links break once a
  skill is packaged on its own.
