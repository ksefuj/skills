---
name: ksef-invoice
description: >
  Generates and checks KSeF FA(3) invoice XML for Polish e-invoicing: maps invoice data (PDF, text,
  form fields) to the schema and picks P_12 rates, P_13_x totals, Adnotacje and buyer
  identification. Covers domestic sales, reverse charge, WDT, export, VAT exemption, margin, OSS,
  split payment, foreign currency, advance (ZAL) and settlement (ROZ) invoices, and explains
  @ksefuj/validator errors. Use when issuing an e-invoice to KSeF, building FA(3) XML, or fixing
  validation errors. To correct an invoice that was already issued, use ksef-correction.
---

# KSeF FA(3) Invoice Generation

Generate FA(3) invoice XML from the user's invoice data and check it with `@ksefuj/validator`. The
FA(3) schema uses `xs:sequence`, so element order matters everywhere. Corrective invoices are
summarized here; for step-by-step corrections of an issued invoice, use the ksef-correction skill.

Bundled references, loaded on demand:

- `references/vat-scenarios.md`: WDT, export, reverse charge, exemption, OSS, margin, split payment,
  foreign currency
- `references/advance-invoices.md`: advance (ZAL) and settlement (ROZ) invoices
- `references/corrections.md`: corrective invoices (KOR, KOR_ZAL, KOR_ROZ)

---

## Schema and Resources

- Namespace: `http://crd.gov.pl/wzor/2025/06/25/13775/`
- XSD: `https://crd.gov.pl/wzor/2025/06/25/13775/schemat.xsd`
- KSeF 2.0 (production): https://ap.ksef.mf.gov.pl/
- KSeF 2.0 test environment (fake data, no legal effect): https://ap-test.ksef.mf.gov.pl/web/
- KSeF documentation portal: https://ksef.podatki.gov.pl/

There is no standalone XML validator in KSeF; the system validates only on submission, so check the
XML with `@ksefuj/validator` first.

---

## Validate Your Output

Validate the XML after generating it:

```bash
npx @ksefuj/validator invoice.xml
```

or from Node.js:

```js
import { validate } from "@ksefuj/validator";
const result = await validate(xmlString);
if (!result.valid) console.log(result.issues);
```

The validator runs three layers:

1. XSD validation against the official FA(3) schema.
2. Semantic rules from the Ministry of Finance information sheet (see
   [Validator Issue Codes](#validator-issue-codes)).
3. Extra checks beyond what KSeF verifies: tax arithmetic, NBP exchange rates, bank account format.

---

## Top-Level XML Element Order

The schema uses `xs:sequence`, so element order is strictly enforced:

```
Faktura
  └── Naglowek
  └── Podmiot1           (seller, always identified by a Polish NIP)
  └── Podmiot2           (buyer)
  └── Podmiot3*          (additional entity, optional)
  └── PodmiotUpowazniony* (optional)
  └── Fa
        └── KodWaluty
        └── P_1
        └── P_1M*
        └── P_2
        └── WZ*
        └── P_6*         (single delivery/service date for all lines, only when different from P_1)
        └── OkresFa*     (billing period per art. 19a sec. 3/4/5 pt 4)
        └── P_13_1..P_13_11  (only include fields relevant to this transaction, omit zeros)
        └── P_14_1..P_14_5  (VAT amounts, only when P_13_x > 0)
        └── P_15
        └── KursWalutyZ* (only for advance invoices ZAL/KOR_ZAL, per art. 106b sec. 1 pt 4)
        └── Adnotacje
        └── RodzajFaktury
        └── ... (corrective/advance-specific elements, see references/)
        └── FaWiersz*    (line items, optional for advance invoices)
        └── Platnosc*
        └── WarunkiTransakcji*
```

`KursWalutyZ` at `Fa` level is only for advance invoices (ZAL/KOR_ZAL). On regular
foreign-currency invoices the exchange rate goes in `FaWiersz/KursWaluty`.

---

## Invoice Scenarios

### Scenario 1: Domestic Sale at 23% VAT

Most common case. Buyer is a Polish company (has NIP).

Key fields:
- `P_13_1` = net amount at 23% | `P_14_1` = VAT amount | `P_15` = gross total
- `FaWiersz/P_12 = "23"` | `Adnotacje/P_18 = 2` (no reverse charge)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Faktura xmlns="http://crd.gov.pl/wzor/2025/06/25/13775/">
  <Naglowek>
    <KodFormularza kodSystemowy="FA (3)" wersjaSchemy="1-0E">FA</KodFormularza>
    <WariantFormularza>3</WariantFormularza>
    <DataWytworzeniaFa>2026-03-01T10:00:00Z</DataWytworzeniaFa>
  </Naglowek>
  <Podmiot1>
    <DaneIdentyfikacyjne>
      <NIP>1234563218</NIP>
      <Nazwa>Seller Sp. z o.o.</Nazwa>
    </DaneIdentyfikacyjne>
    <Adres>
      <KodKraju>PL</KodKraju>
      <AdresL1>ul. Przykładowa 1</AdresL1>
      <AdresL2>00-001 Warszawa</AdresL2>
    </Adres>
  </Podmiot1>
  <Podmiot2>
    <DaneIdentyfikacyjne>
      <NIP>9876543210</NIP>
      <Nazwa>Buyer Sp. z o.o.</Nazwa>
    </DaneIdentyfikacyjne>
    <Adres>
      <KodKraju>PL</KodKraju>
      <AdresL1>ul. Kupiecka 5</AdresL1>
      <AdresL2>30-002 Kraków</AdresL2>
    </Adres>
    <JST>2</JST>
    <GV>2</GV>
  </Podmiot2>
  <Fa>
    <KodWaluty>PLN</KodWaluty>
    <P_1>2026-03-01</P_1>
    <P_2>FV/001/03/2026</P_2>
    <P_13_1>1000.00</P_13_1>
    <P_14_1>230.00</P_14_1>
    <P_15>1230.00</P_15>
    <Adnotacje>
      <P_16>2</P_16>
      <P_17>2</P_17>
      <P_18>2</P_18>
      <P_18A>2</P_18A>
      <Zwolnienie><P_19N>1</P_19N></Zwolnienie>
      <NoweSrodkiTransportu><P_22N>1</P_22N></NoweSrodkiTransportu>
      <P_23>2</P_23>
      <PMarzy><P_PMarzyN>1</P_PMarzyN></PMarzy>
    </Adnotacje>
    <RodzajFaktury>VAT</RodzajFaktury>
    <FaWiersz>
      <NrWierszaFa>1</NrWierszaFa>
      <P_7>Consulting services</P_7>
      <P_8A>h</P_8A>
      <P_8B>10</P_8B>
      <P_9A>100.00</P_9A>
      <P_11>1000.00</P_11>
      <P_12>23</P_12>
    </FaWiersz>
    <Platnosc>
      <TerminPlatnosci><Termin>2026-03-15</Termin></TerminPlatnosci>
      <FormaPlatnosci>6</FormaPlatnosci>
    </Platnosc>
  </Fa>
</Faktura>
```

---

### Scenario 2: Domestic Reverse Charge (Odwrotne obciążenie)

Used when the buyer is the VAT payer (art. 145e of the VAT Act, domestic reverse charge).

Key fields:
- `P_13_10` = net amount | no `P_14_x` (no VAT charged) | `P_15` = equals `P_13_10`
- `FaWiersz/P_12 = "oo"` | `Adnotacje/P_18 = 1`
- Optionally `FaWiersz/P_12_Zal_15 = "1"` if goods from Annex 15

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Faktura xmlns="http://crd.gov.pl/wzor/2025/06/25/13775/">
  <Naglowek>
    <KodFormularza kodSystemowy="FA (3)" wersjaSchemy="1-0E">FA</KodFormularza>
    <WariantFormularza>3</WariantFormularza>
    <DataWytworzeniaFa>2026-03-01T10:00:00Z</DataWytworzeniaFa>
  </Naglowek>
  <Podmiot1>
    <DaneIdentyfikacyjne>
      <NIP>1234563218</NIP>
      <Nazwa>Seller Sp. z o.o.</Nazwa>
    </DaneIdentyfikacyjne>
    <Adres>
      <KodKraju>PL</KodKraju>
      <AdresL1>ul. Stalowa 10</AdresL1>
      <AdresL2>00-001 Warszawa</AdresL2>
    </Adres>
  </Podmiot1>
  <Podmiot2>
    <DaneIdentyfikacyjne>
      <NIP>9876543210</NIP>
      <Nazwa>Buyer Sp. z o.o.</Nazwa>
    </DaneIdentyfikacyjne>
    <Adres>
      <KodKraju>PL</KodKraju>
      <AdresL1>ul. Fabryczna 3</AdresL1>
      <AdresL2>50-001 Wrocław</AdresL2>
    </Adres>
    <JST>2</JST>
    <GV>2</GV>
  </Podmiot2>
  <Fa>
    <KodWaluty>PLN</KodWaluty>
    <P_1>2026-03-01</P_1>
    <P_2>FV/002/03/2026</P_2>
    <P_13_10>5000.00</P_13_10>
    <P_15>5000.00</P_15>
    <Adnotacje>
      <P_16>2</P_16>
      <P_17>2</P_17>
      <P_18>1</P_18>
      <P_18A>2</P_18A>
      <Zwolnienie><P_19N>1</P_19N></Zwolnienie>
      <NoweSrodkiTransportu><P_22N>1</P_22N></NoweSrodkiTransportu>
      <P_23>2</P_23>
      <PMarzy><P_PMarzyN>1</P_PMarzyN></PMarzy>
    </Adnotacje>
    <RodzajFaktury>VAT</RodzajFaktury>
    <FaWiersz>
      <NrWierszaFa>1</NrWierszaFa>
      <P_7>Steel scrap (Annex 15)</P_7>
      <P_8A>kg</P_8A>
      <P_8B>1000</P_8B>
      <P_9A>5.00</P_9A>
      <P_11>5000.00</P_11>
      <P_12>oo</P_12>
      <P_12_Zal_15>1</P_12_Zal_15>
    </FaWiersz>
  </Fa>
</Faktura>
```

`"oo"` is for domestic reverse charge only. For foreign buyers use `"np I"` or `"np II"`; the
validator reports `OO_RATE_FOREIGN_BUYER` otherwise.

---

### Scenario 3: WDT (Intra-EU Supply, 0% VAT)

Supply of goods to an EU-registered business (Wewnątrzwspólnotowa Dostawa Towarów).

Key fields:
- `Podmiot2` uses `KodUE` + `NrVatUE` (not NIP)
- `P_13_6_2` = net value | no VAT | `P_15` = equals `P_13_6_2`
- `FaWiersz/P_12 = "0 WDT"` | `Adnotacje/P_18 = 2`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Faktura xmlns="http://crd.gov.pl/wzor/2025/06/25/13775/">
  <Naglowek>
    <KodFormularza kodSystemowy="FA (3)" wersjaSchemy="1-0E">FA</KodFormularza>
    <WariantFormularza>3</WariantFormularza>
    <DataWytworzeniaFa>2026-03-01T10:00:00Z</DataWytworzeniaFa>
  </Naglowek>
  <Podmiot1>
    <DaneIdentyfikacyjne>
      <NIP>1234563218</NIP>
      <Nazwa>Seller Sp. z o.o.</Nazwa>
    </DaneIdentyfikacyjne>
    <Adres>
      <KodKraju>PL</KodKraju>
      <AdresL1>ul. Eksportowa 5</AdresL1>
      <AdresL2>00-001 Warszawa</AdresL2>
    </Adres>
  </Podmiot1>
  <Podmiot2>
    <DaneIdentyfikacyjne>
      <KodUE>DE</KodUE>
      <NrVatUE>123456789</NrVatUE>
      <Nazwa>German Buyer GmbH</Nazwa>
    </DaneIdentyfikacyjne>
    <Adres>
      <KodKraju>DE</KodKraju>
      <AdresL1>Musterstraße 1</AdresL1>
      <AdresL2>10115 Berlin</AdresL2>
    </Adres>
    <JST>2</JST>
    <GV>2</GV>
  </Podmiot2>
  <Fa>
    <KodWaluty>PLN</KodWaluty>
    <P_1>2026-03-01</P_1>
    <P_2>FV/003/03/2026</P_2>
    <P_13_6_2>8000.00</P_13_6_2>
    <P_15>8000.00</P_15>
    <Adnotacje>
      <P_16>2</P_16>
      <P_17>2</P_17>
      <P_18>2</P_18>
      <P_18A>2</P_18A>
      <Zwolnienie><P_19N>1</P_19N></Zwolnienie>
      <NoweSrodkiTransportu><P_22N>1</P_22N></NoweSrodkiTransportu>
      <P_23>2</P_23>
      <PMarzy><P_PMarzyN>1</P_PMarzyN></PMarzy>
    </Adnotacje>
    <RodzajFaktury>VAT</RodzajFaktury>
    <FaWiersz>
      <NrWierszaFa>1</NrWierszaFa>
      <P_7>Industrial machinery parts</P_7>
      <P_8A>pcs</P_8A>
      <P_8B>4</P_8B>
      <P_9A>2000.00</P_9A>
      <P_11>8000.00</P_11>
      <P_12>0 WDT</P_12>
      <GTU>GTU_07</GTU>
    </FaWiersz>
  </Fa>
</Faktura>
```

---

### Scenario 4: Export (Non-EU, 0% VAT)

Export of goods to a country outside the EU.

Key fields:
- `Podmiot2` uses `KodKraju` + `NrID` as siblings in `DaneIdentyfikacyjne`
- `P_13_6_3` = net value | `P_15` = equals `P_13_6_3`
- `FaWiersz/P_12 = "0 EX"` | `Adnotacje/P_18 = 2`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Faktura xmlns="http://crd.gov.pl/wzor/2025/06/25/13775/">
  <Naglowek>
    <KodFormularza kodSystemowy="FA (3)" wersjaSchemy="1-0E">FA</KodFormularza>
    <WariantFormularza>3</WariantFormularza>
    <DataWytworzeniaFa>2026-03-01T10:00:00Z</DataWytworzeniaFa>
  </Naglowek>
  <Podmiot1>
    <DaneIdentyfikacyjne>
      <NIP>1234563218</NIP>
      <Nazwa>Seller Sp. z o.o.</Nazwa>
    </DaneIdentyfikacyjne>
    <Adres>
      <KodKraju>PL</KodKraju>
      <AdresL1>ul. Portowa 8</AdresL1>
      <AdresL2>80-001 Gdańsk</AdresL2>
    </Adres>
  </Podmiot1>
  <Podmiot2>
    <DaneIdentyfikacyjne>
      <KodKraju>US</KodKraju>
      <NrID>12-3456789</NrID>
      <Nazwa>US Buyer Inc.</Nazwa>
    </DaneIdentyfikacyjne>
    <Adres>
      <KodKraju>US</KodKraju>
      <AdresL1>123 Main Street</AdresL1>
      <AdresL2>New York, NY 10001</AdresL2>
    </Adres>
    <JST>2</JST>
    <GV>2</GV>
  </Podmiot2>
  <Fa>
    <KodWaluty>USD</KodWaluty>
    <P_1>2026-03-01</P_1>
    <P_2>FV/004/03/2026</P_2>
    <P_13_6_3>3000.00</P_13_6_3>
    <P_15>3000.00</P_15>
    <Adnotacje>
      <P_16>2</P_16>
      <P_17>2</P_17>
      <P_18>2</P_18>
      <P_18A>2</P_18A>
      <Zwolnienie><P_19N>1</P_19N></Zwolnienie>
      <NoweSrodkiTransportu><P_22N>1</P_22N></NoweSrodkiTransportu>
      <P_23>2</P_23>
      <PMarzy><P_PMarzyN>1</P_PMarzyN></PMarzy>
    </Adnotacje>
    <RodzajFaktury>VAT</RodzajFaktury>
    <FaWiersz>
      <NrWierszaFa>1</NrWierszaFa>
      <P_7>Software license</P_7>
      <P_8A>pcs</P_8A>
      <P_8B>1</P_8B>
      <P_9A>3000.00</P_9A>
      <P_11>3000.00</P_11>
      <P_12>0 EX</P_12>
      <KursWaluty>3.9500</KursWaluty>
    </FaWiersz>
  </Fa>
</Faktura>
```

For foreign currency invoices use `FaWiersz/KursWaluty`, not `Fa/KursWalutyZ`. All amounts in `Fa`
and `FaWiersz` are in the invoice currency. When VAT is charged at a non-zero rate, also provide
`P_14_xW` (VAT converted to PLN); the validator reports `FOREIGN_CURRENCY_TAX_PLN` otherwise.

---

### Scenario 5: VAT Exemption (Zwolnienie)

Invoice for VAT-exempt services or goods (art. 43, 113, 82 of the VAT Act).

Key fields:
- `P_13_7` = net value | no `P_14_x` | `P_15` = equals `P_13_7`
- `FaWiersz/P_12 = "zw"`
- `Adnotacje/Zwolnienie`: set `P_19 = 1` + exactly one of `P_19A`/`P_19B`/`P_19C` (omit `P_19N`)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Faktura xmlns="http://crd.gov.pl/wzor/2025/06/25/13775/">
  <Naglowek>
    <KodFormularza kodSystemowy="FA (3)" wersjaSchemy="1-0E">FA</KodFormularza>
    <WariantFormularza>3</WariantFormularza>
    <DataWytworzeniaFa>2026-03-01T10:00:00Z</DataWytworzeniaFa>
  </Naglowek>
  <Podmiot1>
    <DaneIdentyfikacyjne>
      <NIP>1234563218</NIP>
      <Nazwa>Medical Clinic Sp. z o.o.</Nazwa>
    </DaneIdentyfikacyjne>
    <Adres>
      <KodKraju>PL</KodKraju>
      <AdresL1>ul. Zdrowotna 3</AdresL1>
      <AdresL2>00-001 Warszawa</AdresL2>
    </Adres>
  </Podmiot1>
  <Podmiot2>
    <DaneIdentyfikacyjne>
      <NIP>9876543210</NIP>
      <Nazwa>Patient Company Sp. z o.o.</Nazwa>
    </DaneIdentyfikacyjne>
    <Adres>
      <KodKraju>PL</KodKraju>
      <AdresL1>ul. Biurowa 7</AdresL1>
      <AdresL2>00-002 Warszawa</AdresL2>
    </Adres>
    <JST>2</JST>
    <GV>2</GV>
  </Podmiot2>
  <Fa>
    <KodWaluty>PLN</KodWaluty>
    <P_1>2026-03-01</P_1>
    <P_2>FV/005/03/2026</P_2>
    <P_13_7>500.00</P_13_7>
    <P_15>500.00</P_15>
    <Adnotacje>
      <P_16>2</P_16>
      <P_17>2</P_17>
      <P_18>2</P_18>
      <P_18A>2</P_18A>
      <Zwolnienie>
        <P_19>1</P_19>
        <P_19A>Art. 43 ust. 1 pkt 19 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług</P_19A>
      </Zwolnienie>
      <NoweSrodkiTransportu><P_22N>1</P_22N></NoweSrodkiTransportu>
      <P_23>2</P_23>
      <PMarzy><P_PMarzyN>1</P_PMarzyN></PMarzy>
    </Adnotacje>
    <RodzajFaktury>VAT</RodzajFaktury>
    <FaWiersz>
      <NrWierszaFa>1</NrWierszaFa>
      <P_7>Medical consultation</P_7>
      <P_8A>visit</P_8A>
      <P_8B>1</P_8B>
      <P_9A>500.00</P_9A>
      <P_11>500.00</P_11>
      <P_12>zw</P_12>
    </FaWiersz>
  </Fa>
</Faktura>
```

When `P_19 = 1`, omit `P_19N` and include exactly one of `P_19A`/`P_19B`/`P_19C`. The validator
enforces this with `ZWOLNIENIE_LOGIC`.

---

### Scenario 6: Advance Invoice (ZAL) and Settlement Invoice (ROZ)

See `references/advance-invoices.md` for full details. Summary:

ZAL (advance invoice):
- `RodzajFaktury = "ZAL"`; requires a `Zamowienie` element; `FaWiersz` is allowed but optional
- For foreign currency: include `KursWalutyZ` at `Fa` level (valid only for ZAL/KOR_ZAL)
- A ZAL without `Zamowienie` triggers `RODZAJ_FAKTURY_SECTIONS`

ROZ (settlement / final invoice):
- `RodzajFaktury = "ROZ"`; requires a `FakturaZaliczkowa` element referencing the advance invoice(s)
- `P_15` = amount still to pay (total minus advance payments already paid)
- A ROZ without `FakturaZaliczkowa` triggers `RODZAJ_FAKTURY_SECTIONS`

---

### Scenario 7: Corrective Invoice (KOR)

See `references/corrections.md` for full details. Summary:

KOR (corrective invoice):
- `RodzajFaktury = "KOR"`; requires a `DaneFaKorygowanej` element
- P_13_x, P_14_x, P_15 contain the difference (delta), not the corrected total
- A KOR without `DaneFaKorygowanej` triggers `RODZAJ_FAKTURY_SECTIONS`
- Exactly one of `NrKSeF`/`NrKSeFN` must be set (`KOR_NRKSEF_CONSISTENCY`)

---

## Field Reference

### Naglowek

```xml
<Naglowek>
  <KodFormularza kodSystemowy="FA (3)" wersjaSchemy="1-0E">FA</KodFormularza>
  <WariantFormularza>3</WariantFormularza>
  <DataWytworzeniaFa>2026-MM-DDTHH:MM:SSZ</DataWytworzeniaFa>
</Naglowek>
```

### Podmiot1 (Seller, always identified by a Polish NIP)

```xml
<Podmiot1>
  <DaneIdentyfikacyjne>
    <NIP>XXXXXXXXXX</NIP>
    <Nazwa>Company name or First Last</Nazwa>
  </DaneIdentyfikacyjne>
  <Adres>
    <KodKraju>PL</KodKraju>
    <AdresL1>Street and number</AdresL1>
    <AdresL2>Postcode and city</AdresL2>  <!-- optional -->
  </Adres>
</Podmiot1>
```

### Podmiot2 (Buyer): Four Patterns

| Buyer type | Identifier fields | Notes |
|---|---|---|
| Polish company (NIP) | `<NIP>` | Most common |
| EU buyer with VAT-UE | `<KodUE>` + `<NrVatUE>` | KodUE is country prefix e.g. `DE` |
| Non-EU buyer | `<KodKraju>` + `<NrID>` | Siblings in DaneIdentyfikacyjne, not nested |
| No tax ID | `<BrakID>1</BrakID>` | Private individuals |

`JST` and `GV` are mandatory in `Podmiot2` (`PODMIOT2_JST_MISSING`, `PODMIOT2_GV_MISSING`); always
include them. A Polish NIP goes in `<NIP>`, not in `<NrVatUE>` (`NIP_IN_WRONG_FIELD`).

### Fa: Summary Amount Fields (P_13_x, P_14_x, P_15)

Include only the fields relevant to this transaction and omit zero-value fields.

| Field | Description | Use when |
|---|---|---|
| `P_13_1` | Net at 23% (or 22%) | Domestic 23% sales |
| `P_13_2` | Net at 8% (or 7%) | Domestic 8% sales |
| `P_13_3` | Net at 5% | Domestic 5% sales |
| `P_13_4` | Net, taxi flat rate | Taxis |
| `P_13_5` | Net, OSS procedure | Cross-border digital sales (OSS) |
| `P_13_6_1` | Net 0% domestic (not WDT, not export) | 0% e.g. art. 83 |
| `P_13_6_2` | Net 0% WDT | Intra-EU goods supply |
| `P_13_6_3` | Net 0% export | Goods export to non-EU |
| `P_13_7` | Net, VAT-exempt | VAT exemption |
| `P_13_8` | Net, outside PL (not OSS, not art. 100 pt 4) | Reverse charge non-EU / art.28b/28e |
| `P_13_9` | Net, art. 100 sec. 1 pt 4 services (EU) | Intra-EU service intrastat |
| `P_13_10` | Net, domestic reverse charge | Domestic reverse charge art. 145e |
| `P_13_11` | Net, margin procedure | Margin art. 119/120 |
| `P_14_1..5` | VAT amounts for corresponding P_13 | Only when P_13_x > 0 with a positive rate |
| `P_15` | Total amount due | Always mandatory |

`P_13_8` vs `P_13_9`: services to non-EU entities go in `P_13_8`; services to EU entities covered by
art. 100 sec. 1 pt 4 (VAT-UE summary declaration) go in `P_13_9`.

### Adnotacje: Complete Structure

All sub-elements of `Adnotacje` are required. The three selection blocks each take exactly one
choice:

```xml
<Adnotacje>
  <P_16>2</P_16>     <!-- 1=cash accounting method, 2=no -->
  <P_17>2</P_17>     <!-- 1=self-billing, 2=no -->
  <P_18>2</P_18>     <!-- 1=reverse charge (domestic OR foreign), 2=no -->
  <P_18A>2</P_18A>   <!-- 1=split payment (MPP) >15k PLN, 2=no -->

  <!-- Zwolnienie: EITHER P_19N=1 (not exempt) OR P_19=1 + exactly one of P_19A/B/C -->
  <Zwolnienie>
    <P_19N>1</P_19N>
  </Zwolnienie>

  <!-- NoweSrodkiTransportu: EITHER P_22N=1 OR P_22=1 + vehicle details -->
  <NoweSrodkiTransportu>
    <P_22N>1</P_22N>
  </NoweSrodkiTransportu>

  <P_23>2</P_23>     <!-- 1=simplified triangular EU invoice, 2=no -->

  <!-- PMarzy: EITHER P_PMarzyN=1 OR P_PMarzy=1 + exactly one margin type -->
  <PMarzy>
    <P_PMarzyN>1</P_PMarzyN>
  </PMarzy>
</Adnotacje>
```

`P_18=1` applies to both domestic reverse charge (art. 145e) and cross-border reverse charge
(services outside PL where the buyer accounts for VAT in their country).

### RodzajFaktury Values

| Value | Description |
|---|---|
| `VAT` | Standard invoice |
| `KOR` | Corrective invoice |
| `ZAL` | Advance invoice |
| `ROZ` | Settlement invoice (after advances) |
| `UPR` | Simplified invoice (up to 450 PLN / 100 EUR) |
| `KOR_ZAL` | Corrective advance invoice |
| `KOR_ROZ` | Corrective settlement invoice |

### FaWiersz: Field Order (xs:sequence)

```
NrWierszaFa → UU_ID* → P_6A* → P_7* → Indeks* → GTIN* → PKWIU* → CN* → PKOB*
→ P_8A* → P_8B* → P_9A* → P_9B* → P_10* → P_11* → P_11A* → P_11Vat*
→ P_12* → P_12_XII* → P_12_Zal_15* → KwotaAkcyzy* → GTU* → Procedura*
→ KursWaluty* → StanPrzed*
```

Key FaWiersz fields:

| Field | Description | Notes |
|---|---|---|
| `NrWierszaFa` | Line number (1, 2, 3…) | Mandatory |
| `P_7` | Item/service description (max 512 chars) | Almost always |
| `P_8A` | Unit of measure (e.g. `h`, `pcs`, `kg`) | Optional |
| `P_8B` | Quantity (max 6 decimal places) | Optional |
| `P_9A` | Unit price net (max 8 decimal places) | Optional |
| `P_11` | Net line value (max 2 decimal places) | Optional |
| `P_12` | Tax rate code, see enumeration below | Optional |
| `GTU` | `GTU_01`…`GTU_13` as element value | Optional; max 1 per line |
| `KursWaluty` | NBP exchange rate for this line | Foreign currency invoices only |
| `StanPrzed` | `1` = before-correction state row | Corrective invoices only |

### P_12 Tax Rate Enumeration

Use exactly these values; the validator reports anything else as `P12_ENUMERATION`:

```
"23"    23% (standard rate)
"22"    22%
"8"     8%
"7"     7%
"5"     5%
"4"     4%
"3"     3%
"0 KR"  0%, domestic (not WDT, not export)
"0 WDT" 0%, intra-EU supply (WDT)
"0 EX"  0%, export
"zw"    VAT exempt
"oo"    domestic reverse charge (art. 145e)
"np I"  outside PL territory (not art. 100 pt 4, not OSS): foreign/cross-border reverse charge
"np II" services under art. 100 sec. 1 pt 4: intra-EU services
```

`"NP"`, `"np"`, `"np1"` and `"npI"` are invalid. The space matters: `"np I"`.

### GTU Codes

GTU is a text value in one element: `<GTU>GTU_12</GTU>`

- The old format `<GTU_12>1</GTU_12>` is an XSD error (`GTU_FORMAT`)
- Maximum 1 GTU per line item
- GTU_01–GTU_10: goods; GTU_11–GTU_13: intangible services
- Optional, but it should match the JPK_VAT markings

### Date Fields

| Field | Scope | When to use |
|---|---|---|
| `Fa/P_6` | All lines | Single delivery/service date for all lines, only when different from P_1 |
| `Fa/OkresFa` (`P_6_Od`+`P_6_Do`) | All lines | Billing period (e.g. monthly subscription) per art. 19a |
| `FaWiersz/P_6A` | Per line | Different dates on different lines |

When the service/delivery date equals the invoice date (`P_1`), leave `P_6` out. `P_6` and `P_6A`
are mutually exclusive (`P6_P6A_MUTUAL_EXCLUSION`).

### Decimal Precision

| Fields | Max decimal places | Example |
|---|---|---|
| P_11, P_13_x, P_14_x, P_15 (general amounts) | 2 | `1230.50` |
| P_9A, P_9B (unit prices) | 8 | `75.12345678` |
| P_8B (quantities) | 6 | `80.123456` |
| KursWaluty, KursWalutyZ (exchange rates) | 6 | `3.707500` |

Use `.` as the decimal separator and no thousand separators (`DECIMAL_PRECISION`,
`AMOUNT_NO_SEPARATORS`).

### Payment (Platnosc, optional)

```xml
<Platnosc>
  <TerminPlatnosci>
    <Termin>YYYY-MM-DD</Termin>
  </TerminPlatnosci>
  <FormaPlatnosci>6</FormaPlatnosci>  <!-- 6=bank transfer -->
  <RachunekBankowy>
    <NrRB>PL49...</NrRB>              <!-- IBAN without spaces; Polish IBAN = 28 chars (PL + 26 digits) -->
    <SWIFT>BREXPLPWMBK</SWIFT>        <!-- optional -->
    <NazwaBanku>mBank S.A.</NazwaBanku>  <!-- NazwaBanku not NazwaBank -->
  </RachunekBankowy>
</Platnosc>
```

FormaPlatnosci values: 1=cash, 2=card, 3=voucher, 4=cheque, 5=credit, 6=bank transfer, 7=mobile

---

## Validator Issue Codes

Each semantic issue has a `code` (the CLI prints `Code: <CODE>`) and a severity. Errors make the
invoice invalid; warnings do not. Use the code to find the rule that was broken.

### Podmiot

| Code | Severity | Rule |
|---|---|---|
| `PODMIOT2_JST_MISSING` | error | `JST` is mandatory in `Podmiot2` |
| `PODMIOT2_GV_MISSING` | error | `GV` is mandatory in `Podmiot2` |
| `JST_REQUIRES_PODMIOT3` | error | `JST=1` requires a `Podmiot3` with `Rola=8` |
| `GV_REQUIRES_PODMIOT3` | error | `GV=1` requires a `Podmiot3` with `Rola=10` |
| `NIP_IN_WRONG_FIELD` | warning | A Polish NIP (10 digits) belongs in `NIP`, not `NrVatUE` |
| `PODMIOT3_UDZIAL_REQUIRES_ROLE_4` | error | `Udzial` is allowed only with `Rola=4` |
| `PODMIOT3_ROLE_MISSING` | error | `Podmiot3` needs `Rola`, or `RolaInna` with `OpisRoli` |
| `SELF_BILLING_PODMIOT3_CONFLICT` | warning | Self-billing (`P_17=1`) conflicts with a `Podmiot3` with `Rola=5` |

### Fa core

| Code | Severity | Rule |
|---|---|---|
| `P15_MISSING` | error | `P_15` is mandatory |
| `P6_P6A_MUTUAL_EXCLUSION` | error | `Fa/P_6` and `FaWiersz/P_6A` cannot both be present |
| `RODZAJ_FAKTURY_SECTIONS` | error | KOR, KOR_ZAL and KOR_ROZ need `DaneFaKorygowanej`; ZAL needs `Zamowienie`; ROZ needs `FakturaZaliczkowa` |
| `KURS_WALUTY_Z_PLACEMENT` | error | `Fa/KursWalutyZ` is only for ZAL and KOR_ZAL |
| `FOREIGN_CURRENCY_TAX_PLN` | warning | Foreign currency with VAT at `P_13_1`..`P_13_4` needs the matching `P_14_xW` (PLN) |

### Adnotacje

| Code | Severity | Rule |
|---|---|---|
| `ADNOTACJE_P16_MISSING` | error | `P_16` is mandatory |
| `ADNOTACJE_P17_MISSING` | error | `P_17` is mandatory |
| `ADNOTACJE_P18_MISSING` | error | `P_18` is mandatory |
| `ADNOTACJE_P18A_MISSING` | error | `P_18A` is mandatory |
| `ADNOTACJE_ZWOLNIENIE_MISSING` | error | `Zwolnienie` is mandatory |
| `ADNOTACJE_NST_MISSING` | error | `NoweSrodkiTransportu` is mandatory |
| `ADNOTACJE_P23_MISSING` | error | `P_23` is mandatory |
| `ADNOTACJE_PMARZY_MISSING` | error | `PMarzy` is mandatory |
| `ZWOLNIENIE_LOGIC` | error | Exactly one of `P_19`/`P_19N` is 1; with `P_19=1`, exactly one of `P_19A`/`P_19B`/`P_19C` |
| `NST_LOGIC` | error | Exactly one of `P_22`/`P_22N`; with `P_22=1`, `P_42_5` and `NowySrodekTransportu` are required |
| `PMARZY_LOGIC` | error | Exactly one of `P_PMarzy`/`P_PMarzyN`; with `P_PMarzy=1`, exactly one margin type |

### FaWiersz

| Code | Severity | Rule |
|---|---|---|
| `P12_ENUMERATION` | error | `P_12` must be one of the 14 valid codes |
| `OO_RATE_FOREIGN_BUYER` | warning | `"oo"` is domestic only; foreign buyers need `"np I"` or `"np II"` |
| `GTU_FORMAT` | error | `GTU` must be `GTU_01`..`GTU_13` as the element value |
| `DECIMAL_PRECISION` | error | Amounts, prices, quantities and rates respect their decimal limits |

### Corrective invoices and reverse charge

| Code | Severity | Rule |
|---|---|---|
| `KOR_NRKSEF_CONSISTENCY` | error | Exactly one of `NrKSeF`/`NrKSeFN` is 1; with `NrKSeF=1`, `NrKSeFFaKorygowanej` is required |
| `REVERSE_CHARGE_CONSISTENCY` | warning | `P_13_8`/`P_13_10` present requires `P_18=1`; `P_18=1` requires lines with `np I`, `np II` or `oo` |

### Payment and transaction

| Code | Severity | Rule |
|---|---|---|
| `PAYMENT_ZAPLACONO_DATE` | warning | `Zaplacono=1` requires `DataZaplaty` |
| `RACHUNEKBANKOWY_NRRB` | error | A non-empty `RachunekBankowy` needs `NrRB` |
| `NRRB_LENGTH` | warning | `NrRB` is 10 to 34 characters |
| `IPKSEF_FORMAT` | warning | `IPKSeF` is exactly 13 alphanumeric characters |
| `WALUTA_UMOWNA_PLN` | error | `WalutaUmowna` is never `PLN` |
| `KURS_WALUTA_PAIR` | error | `KursUmowny` and `WalutaUmowna` are both present or both absent |
| `TRANSPORT_MINIMUM_DATA` | warning | `Transport` needs the transport type and a cargo description |

### Format and additional checks

| Code | Severity | Rule |
|---|---|---|
| `AMOUNT_NO_SEPARATORS` | error | No thousand separators; `.` is the only decimal separator |
| `TAX_CALCULATION_MISMATCH` | error | `P_14_x` matches `P_13_x` times the rate and `P_15` equals the sum of all `P_13_x` and `P_14_x` (not checked on corrective invoices) |
| `INVALID_BANK_ACCOUNT_FORMAT` | error | A `PL` IBAN is 28 characters; a bare NRB is 26 digits |
| `DUPLICATE_LINE_NUMBERS` | error | `NrWierszaFa` is unique (corrective invoices excepted) |
| `NEGATIVE_QUANTITY_NOT_ALLOWED` | error | Negative `P_8B` only on corrective invoice types |
| `CURRENCY_RATE_MISMATCH` | warning | `KursWaluty` differs from the NBP mid-rate for the date required by art. 31a of the VAT Act |
| `CURRENCY_RATE_UNVERIFIABLE` | warning | The NBP rate could not be fetched or checked |

KSeF also rejects XML that contains processing instructions, a UTF-8 BOM, a non-UTF-8 declared
encoding, or W3C-discouraged control characters (`XML_PROCESSING_INSTRUCTION`, `XML_BOM_PRESENT`,
`XML_ENCODING_NOT_UTF8`, `XML_DISCOURAGED_CHARACTER`). Emit plain UTF-8 without them.

---

## Common Errors and Fixes

| Error | Cause | Fix |
|---|---|---|
| `PODMIOT2_JST_MISSING` / `PODMIOT2_GV_MISSING` | Both elements are mandatory | Add `<JST>2</JST><GV>2</GV>` to `Podmiot2` |
| "KursWalutyZ not expected" | `KURS_WALUTY_Z_PLACEMENT`: only ZAL/KOR_ZAL may use it | Remove it from `Fa`; use `FaWiersz/KursWaluty` |
| "NP not in enumeration" | `P12_ENUMERATION`: "NP" is not a valid `P_12` value | Use `"np I"` or `"np II"` (with a space) |
| `<GTU_12>1</GTU_12>` XSD error | `GTU_FORMAT`: wrong GTU format | Use `<GTU>GTU_12</GTU>` |
| "not expected, expected X" in `FaWiersz` | XSD sequence error | `GTU` must come before `KursWaluty` and `StanPrzed` |
| "NazwaBank not expected" | Typo in element name | The correct name is `NazwaBanku` |
| Reverse charge with wrong `P_18` | `REVERSE_CHARGE_CONSISTENCY` | Set `P_18=1` when using `"oo"`, `"np I"` or `"np II"` |
| `P_13_x` = 0 causing issues | The schema expects no zero-value `P_13_x` | Omit any `P_13_x` field with a zero value |
| "minOccurs" error on `Adnotacje` | `ADNOTACJE_*_MISSING`: incomplete block | Include all sub-elements: `Zwolnienie`, `NoweSrodkiTransportu`, `PMarzy` and the rest |
| `P_19` and `P_19N` both set | `ZWOLNIENIE_LOGIC`: mutual exclusion | Use `P_19N=1` or `P_19=1` with one of `P_19A`/`P_19B`/`P_19C` |
| Polish NIP in `NrVatUE` | `NIP_IN_WRONG_FIELD` | Move the 10-digit NIP to the `<NIP>` element |
