# ksefuj skills

Claude skills for Polish KSeF (Krajowy System e-Faktur) e-invoicing, from the team behind
[ksefuj.to](https://ksefuj.to).

| Skill                                          | What it does                                                                                                                                                                        |
| ---------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`ksef-fa3`](skills/ksef-fa3/SKILL.md)         | Generates FA(3) invoice XML from invoice data (PDF, text, form). Covers domestic sales, reverse charge (EU/non-EU), WDT, export, VAT exemption, margin procedure, advance invoices. |
| [`ksef-korekta`](skills/ksef-korekta/SKILL.md) | Interactive wizard for corrective invoices (KOR, KOR_ZAL, KOR_ROZ), including the two-document flow for a wrong buyer NIP.                                                          |

Generated XML should pass [`@ksefuj/validator`](https://www.npmjs.com/package/@ksefuj/validator):

```bash
npx @ksefuj/validator invoice.xml
```

## Installation

### Claude Code

```
/plugin marketplace add ksefuj/skills
/plugin install ksef@ksefuj
```

### Claude.ai

Download the `.skill` files from [Releases](https://github.com/ksefuj/skills/releases) and upload
them in the skills section of Claude settings.

## Reference architecture

Each skill is self-contained: its `references/` folder bundles focused extracts (~150 lines each) of
the canonical sources, which live in [ksefuj/ksefuj](https://github.com/ksefuj/ksefuj):

- [`packages/validator/docs/fa3-information-sheet.md`](https://github.com/ksefuj/ksefuj/blob/main/packages/validator/docs/fa3-information-sheet.md)
  — schema and validation rules
- [`docs/knowledge-base/briefs/podrecznik-ksef-20-czesc-ii.md`](https://github.com/ksefuj/ksefuj/blob/main/docs/knowledge-base/briefs/podrecznik-ksef-20-czesc-ii.md)
  — MF operational rules

Extracts instead of copies: full copies drift from the source, and links break once a skill is
packaged on its own.

### Updating references

When a canonical source changes (schema update, new MF publication):

1. Check whether the change affects any skill's `references/` (grep for the section number).
2. Update the extract.
3. Validate the skill's example XML with `npx @ksefuj/validator`.

### Skill authority block

Each `SKILL.md` opens with a block listing what ships with the skill and what is maintainer-only
context:

```markdown
> **Bundled references (self-contained for standalone use):**
>
> - `references/foo.md` — what it covers
>
> **Canonical sources in ksefuj/ksefuj (not bundled — for maintainers):**
>
> - `path/to/canonical.md` — full document
```

## Releasing

Push a `v*` tag. The release workflow zips each skill into a `.skill` file and attaches it to a
GitHub release.

## License

[Apache 2.0](LICENSE)
