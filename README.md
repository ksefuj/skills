# ksefuj skills

Claude skills for Polish KSeF (Krajowy System e-Faktur) e-invoicing, from the team behind
[ksefuj.to](https://ksefuj.to).

| Skill                                                | What it does                                                                                                                                                                        |
| ---------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`ksef-invoice`](skills/ksef-invoice/SKILL.md)       | Generates FA(3) invoice XML from invoice data (PDF, text, form). Covers domestic sales, reverse charge (EU/non-EU), WDT, export, VAT exemption, margin procedure, advance invoices. |
| [`ksef-correction`](skills/ksef-correction/SKILL.md) | Interactive wizard for corrective invoices (KOR, KOR_ZAL, KOR_ROZ), including the two-document flow for a wrong buyer NIP.                                                          |

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

## Releasing

Push a `v*` tag. The release workflow zips each skill into a `.skill` file and attaches it to a
GitHub release.

## License

[Apache 2.0](LICENSE)
