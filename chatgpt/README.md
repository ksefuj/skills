# ChatGPT custom GPT

The two skills in this repo also work as a ChatGPT custom GPT, so people without Claude can use them
from a single link. The GPT is created by hand in the ChatGPT GPT builder. This folder holds what
you paste in; the knowledge files are generated from the skill sources so they never drift.

| Builder field | Source                                                                       |
| ------------- | ---------------------------------------------------------------------------- |
| Instructions  | [`instructions.md`](instructions.md), pasted as is (under 8000 characters)   |
| Knowledge     | the files from `chatgpt-knowledge.zip` (release asset, or built locally)     |

## Build the knowledge files

Download `chatgpt-knowledge.zip` from the latest [release](https://github.com/ksefuj/skills/releases)
and unzip it, or build it locally:

```bash
scripts/build-chatgpt-knowledge.sh
```

This writes `dist/chatgpt-knowledge/` and `dist/chatgpt-knowledge.zip`. ChatGPT needs unique file
names, so the script flattens the skills:

- `ksef-invoice.md` and `ksef-correction.md` (the `SKILL.md` files)
- `<skill>--<reference>.md` for every reference, for example `ksef-invoice--vat-scenarios.md`

The files are verbatim copies. If you add a skill or a reference, update the file mapping in
`instructions.md` to match the script output.

Total size is about 65 KB, well under the ChatGPT knowledge limits.

## Create the GPT

In chatgpt.com open Explore GPTs, Create, and switch to the Configure tab.

**Name**

```
KSeF: faktury
```

**Description** (Polish, under 300 characters)

```
Pomaga przygotować fakturę lub korektę w formacie KSeF FA(3): pyta o brakujące dane, tworzy plik XML do pobrania i podpowiada, jak go sprawdzić za darmo przed wysłaniem do KSeF. Dla freelancerów i małych firm. Nie zastępuje księgowego.
```

**Instructions**: paste the full contents of [`instructions.md`](instructions.md).

**Conversation starters** (one per field)

```
Chcę wystawić klientowi fakturę za usługi z zeszłego miesiąca.
Wystawiam fakturę za usługę dla firmy z Niemiec. Jaki VAT wpisać?
Na wystawionej fakturze jest błędny NIP nabywcy. Co teraz?
Walidator znalazł błąd w mojej fakturze. Co trzeba poprawić?
```

**Knowledge**: upload all files from `chatgpt-knowledge.zip` (unzip first and select the `.md`
files).

**Capabilities**

- Web Search: off
- Canvas: optional
- Image generation: off
- Code Interpreter & Data Analysis: on (the GPT uses it to write the downloadable `.xml` file)

**Actions**: none.

**Additional settings**: turn off "Use conversation data in your GPT to improve our models".

## Publish

1. Share, then choose GPT Store, with the category Productivity.
2. Under the builder profile (Settings, Builder profile) show the website `ksefuj.to`. ChatGPT asks
   for domain verification: add the DNS TXT record it shows to the `ksefuj.to` zone, then verify.
3. Open the GPT once with a test case (a domestic 23% invoice and a wrong-NIP correction) and check
   that it produces a downloadable `.xml` and reminds about the validator.
4. Put the GPT link in the root [README](../README.md).

## Keeping it in sync

On each release:

1. Download the new `chatgpt-knowledge.zip` from the release.
2. In the GPT builder, remove the old knowledge files and upload the new ones.
3. If `instructions.md` changed, paste it again.
4. Run the test cases from step 3 above before saving.

The GPT does not run the validator. It always points users to https://ksefuj.to/validator for the
check.
