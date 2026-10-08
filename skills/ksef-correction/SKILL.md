---
name: ksef-correction
description: >
  Guides the user through correcting an invoice that was already issued (korekta, faktura
  korygująca) and generates the corrective FA(3) XML: KOR, KOR_ZAL, KOR_ROZ, correction to zero,
  wrong buyer NIP (zero and reissue), changed seller or buyer data, batch corrections (korekta
  zbiorcza). Use when the user has a faulty invoice and says correct, fix, korekta, faktura
  korygująca, pomyłka w fakturze or błędny NIP. Asks for any missing data, then produces
  validator-passing XML.
---

# KSeF Corrective Invoice Wizard

Collect the original invoice, find out what was wrong, ask for missing data, then produce complete
corrective XML. Never put TODOs or placeholder values in the XML; ask the user instead.

Bundled references, loaded on demand:

- `references/invoice-base.md`: FA(3) skeleton with Podmiot patterns, Adnotacje, P_12 rates and
  field order
- `references/correction-procedures.md`: the Ministry of Finance rules for corrections
  (Podręcznik KSeF 2.0, Part II, section 2.13)

---

## Wizard Flow

### Step 1: Accept the Original Invoice

Ask for the original (faulty) invoice in one of these forms:

- XML file: the full FA(3) XML of the original invoice
- Pasted XML
- Key data, at minimum: seller NIP, buyer NIP, invoice number (P_2), issue date (P_1), original
  amounts (P_13_x, P_14_x, P_15), line items, and the KSeF number if it was submitted to KSeF

If the user gives a file path, read it. If they describe the invoice in words, extract what you can
and fill the gaps in Step 3.

### Step 2: Identify Correction Type

Based on what the user wants to fix, determine the correction scenario:

| Scenario | RodzajFaktury | Key rule |
|---|---|---|
| Fix amounts, quantities, prices, descriptions | `KOR` | Amounts are deltas (differences) |
| Fix advance invoice (ZAL) | `KOR_ZAL` | Delta amounts + Zamowienie before/after |
| Fix settlement invoice (ROZ) | `KOR_ROZ` | Delta amounts + FakturaZaliczkowa reference |
| Wrong buyer NIP | `KOR` (to zero) + new `VAT` | The NIP cannot be changed: zero and reissue |
| Wrong seller data (name, address) | `KOR` with `Podmiot1K` | Old data in Podmiot1K, correct in Podmiot1 |
| Wrong buyer data (name, address, not NIP) | `KOR` with `Podmiot2K` | Old data in Podmiot2K, correct in Podmiot2 |

Ask:

> What needs to be corrected? (e.g., wrong price, wrong quantity, wrong buyer name, wrong buyer
> NIP, add missing line, remove a line, change VAT rate)

### Step 3: Gather Missing Data

Based on the correction type, ask only for data you do not already have:

For amount or line corrections:
- Which line(s) need correcting?
- What are the correct values? (new quantity, new unit price, or new total)
- Reason for correction? (optional but recommended; fills `PrzyczynaKorekty`)

For a wrong buyer NIP:
- Confirm that two documents will be generated: a correction to zero and a new invoice with the
  correct NIP
- What is the correct buyer NIP?
- What is the correct buyer name and address?

For seller or buyer data corrections (not NIP):
- What are the correct data values?

For all corrections, confirm:
- Was the original invoice submitted to KSeF? (determines `NrKSeF` vs `NrKSeFN`)
- If yes: what is the KSeF number? (`NrKSeFFaKorygowanej`)
- What date should the correction have? (P_1, default today)
- What number should the corrective invoice have? (P_2)
- When should the correction take effect? (`TypKorekty`: 1=original date, 2=correction date,
  3=other)

### Step 4: Calculate Deltas

For amount corrections, calculate the differences:

```
Delta P_13_x = new_P_13_x - original_P_13_x
Delta P_14_x = new_P_14_x - original_P_14_x
Delta P_15   = new_P_15   - original_P_15
```

For "correction to zero":
```
Delta P_13_x = -original_P_13_x
Delta P_14_x = -original_P_14_x
Delta P_15   = -original_P_15
```

### Step 5: Generate XML

Produce the complete corrective invoice XML using the structure below.

---

## XML Structure

### Required Elements (All Corrective Types)

```xml
<RodzajFaktury>KOR</RodzajFaktury>
<PrzyczynaKorekty>...</PrzyczynaKorekty>  <!-- optional but recommended -->
<TypKorekty>2</TypKorekty>  <!-- 1=original date, 2=correction date, 3=other -->
<DaneFaKorygowanej>
  <DataWystFaKorygowanej>2026-03-01</DataWystFaKorygowanej>
  <NrFaKorygowanej>FV/001/03/2026</NrFaKorygowanej>
  <!-- Original was in KSeF: -->
  <NrKSeF>1</NrKSeF>
  <NrKSeFFaKorygowanej>9999999999-20260301-XXXXXX-YYYYYY-ZZ</NrKSeFFaKorygowanej> <!-- KSeF number assigned to the original invoice -->
  <!-- OR original was NOT in KSeF: -->
  <!-- <NrKSeFN>1</NrKSeFN> -->
</DaneFaKorygowanej>
```

Exactly one of `NrKSeF` or `NrKSeFN` must be set to `1` (`KOR_NRKSEF_CONSISTENCY`). When
`NrKSeF=1`, `NrKSeFFaKorygowanej` is required. When `NrKSeFN=1`, `NrKSeFFaKorygowanej` must be
absent.

### Delta Amounts

P_13_x, P_14_x, P_15 contain the difference, not the corrected total.

```xml
<!-- Correction in minus: reducing net by 100 PLN at 23% -->
<P_13_1>-100.00</P_13_1>
<P_14_1>-23.00</P_14_1>
<P_15>-123.00</P_15>

<!-- Correction in plus: increasing net by 50 PLN at 23% -->
<P_13_1>50.00</P_13_1>
<P_14_1>11.50</P_14_1>
<P_15>61.50</P_15>
```

### FaWiersz Correction Methods

Method 1, delta (difference only). Simplest, for plain amount changes:

```xml
<FaWiersz>
  <NrWierszaFa>1</NrWierszaFa>
  <P_7>Product A</P_7>
  <P_8B>-1</P_8B>
  <P_9A>90.00</P_9A>
  <P_11>-90.00</P_11>
  <P_12>23</P_12>
</FaWiersz>
```

Method 2, before/after with `StanPrzed`. Recommended when changing the VAT rate or currency:

```xml
<!-- Before state -->
<FaWiersz>
  <NrWierszaFa>1</NrWierszaFa>
  <P_7>Product A</P_7>
  <P_8B>3</P_8B>
  <P_9A>90.00</P_9A>
  <P_11>270.00</P_11>
  <P_12>23</P_12>
  <StanPrzed>1</StanPrzed>
</FaWiersz>
<!-- After state (no StanPrzed) -->
<FaWiersz>
  <NrWierszaFa>1</NrWierszaFa>
  <P_7>Product A</P_7>
  <P_8B>2</P_8B>
  <P_9A>90.00</P_9A>
  <P_11>180.00</P_11>
  <P_12>23</P_12>
</FaWiersz>
```

With `StanPrzed`, duplicate `NrWierszaFa` values are expected. The validator skips
`DUPLICATE_LINE_NUMBERS` and `NEGATIVE_QUANTITY_NOT_ALLOWED` for corrective types.

Method 3, storno. Like `StanPrzed` but without the flag, using negative values:

```xml
<!-- Reversal of original (negative quantity) -->
<FaWiersz>
  <NrWierszaFa>1</NrWierszaFa>
  <P_7>Product A</P_7>
  <P_8B>-3</P_8B>
  <P_9A>90.00</P_9A>
  <P_11>-270.00</P_11>
  <P_12>23</P_12>
</FaWiersz>
<!-- Corrected state (positive) -->
<FaWiersz>
  <NrWierszaFa>2</NrWierszaFa>
  <P_7>Product A</P_7>
  <P_8B>2</P_8B>
  <P_9A>90.00</P_9A>
  <P_11>180.00</P_11>
  <P_12>23</P_12>
</FaWiersz>
```

### Wrong Buyer NIP: Two-Document Flow

A wrong NIP cannot be corrected with a standard corrective invoice. Generate two documents.

Document 1, correction to zero:

```xml
<!-- Podmiot2 = the WRONG buyer (same as original) -->
<Podmiot2>
  <DaneIdentyfikacyjne>
    <NIP>WRONG_NIP</NIP>
    <Nazwa>Wrong Buyer Name</Nazwa>
  </DaneIdentyfikacyjne>
  ...
</Podmiot2>
<!-- All amounts negated -->
<P_13_1>-1000.00</P_13_1>
<P_14_1>-230.00</P_14_1>
<P_15>-1230.00</P_15>
<RodzajFaktury>KOR</RodzajFaktury>
<PrzyczynaKorekty>Błędny NIP nabywcy</PrzyczynaKorekty>
```

Document 2, new invoice with the correct NIP:

```xml
<!-- Podmiot2 = the CORRECT buyer -->
<Podmiot2>
  <DaneIdentyfikacyjne>
    <NIP>CORRECT_NIP</NIP>
    <Nazwa>Correct Buyer Name</Nazwa>
  </DaneIdentyfikacyjne>
  ...
</Podmiot2>
<RodzajFaktury>VAT</RodzajFaktury>
<!-- Full original amounts (positive) -->
```

### Podmiot1K and Podmiot2K: Data Corrections

When correcting seller or buyer data (not NIP), use the K-variant elements:

`Podmiot1K` holds the old seller data from the original invoice:

```xml
<Podmiot1K>
  <DaneIdentyfikacyjne>
    <NIP>1234563218</NIP>
    <Nazwa>Old Company Name</Nazwa>
  </DaneIdentyfikacyjne>
  <Adres>
    <KodKraju>PL</KodKraju>
    <AdresL1>Old Address</AdresL1>
  </Adres>
</Podmiot1K>
```

`Podmiot2K` holds the old buyer data from the original invoice:

```xml
<Podmiot2K>
  <DaneIdentyfikacyjne>
    <NIP>9876543210</NIP>
    <Nazwa>Old Buyer Name</Nazwa>
  </DaneIdentyfikacyjne>
  <Adres>
    <KodKraju>PL</KodKraju>
    <AdresL1>Old Buyer Address</AdresL1>
  </Adres>
  <IDNabywcy>buyer-001</IDNabywcy>  <!-- links to Podmiot2, max 32 chars -->
</Podmiot2K>
```

When `Podmiot2K` is present, `Podmiot2` must also include `IDNabywcy` with the same value. The
correct data goes in `Podmiot1`/`Podmiot2` as usual.

### Batch Corrections (Korekta Zbiorcza)

For corrections covering multiple original invoices (e.g., quarterly rebate):

```xml
<RodzajFaktury>KOR</RodzajFaktury>
<PrzyczynaKorekty>Opust za I kwartał 2026</PrzyczynaKorekty>
<DaneFaKorygowanej>
  <DataWystFaKorygowanej>2026-01-15</DataWystFaKorygowanej>
  <NrFaKorygowanej>FV/001/01/2026</NrFaKorygowanej>
  <NrKSeF>1</NrKSeF>
  <NrKSeFFaKorygowanej>...</NrKSeFFaKorygowanej>
</DaneFaKorygowanej>
<DaneFaKorygowanej>
  <DataWystFaKorygowanej>2026-02-10</DataWystFaKorygowanej>
  <NrFaKorygowanej>FV/005/02/2026</NrFaKorygowanej>
  <NrKSeF>1</NrKSeF>
  <NrKSeFFaKorygowanej>...</NrKSeFFaKorygowanej>
</DaneFaKorygowanej>
<OkresFaKorygowanej>styczeń–marzec 2026</OkresFaKorygowanej>
```

`DaneFaKorygowanej` can appear up to 50,000 times. `OkresFaKorygowanej` is a free-text period
description.

When the correction covers all deliveries in the period, `FaWiersz` can be omitted. When it covers
only some items, include `FaWiersz` with `P_7` naming the corrected goods or services.

### KOR_ZAL: Corrective Advance Invoice

Same as KOR, plus:
- `KursWalutyZ` at `Fa` level is valid (for foreign currency advances)
- `P_15ZK`: advance amount before correction
- If correcting order details: include `Zamowienie` with before/after state
- `WartoscZamowienia` in correction = correct order value after correction

### KOR_ROZ: Corrective Settlement Invoice

Same as KOR, plus:
- `P_15ZK`: settlement amount before correction
- `FakturaZaliczkowa`: references to the advance invoice(s) remain as in the original ROZ

---

## Chaining Multiple Corrections

When correcting an already-corrected invoice:

1. `DaneFaKorygowanej` always references the original invoice, not the previous correction.
2. Deltas are relative to the current state (original plus all previous corrections).

Example: original 1000 net, correction 1 = -100 (to 900), correction 2 = -200 (to 700). Correction 2
references the original in `DaneFaKorygowanej` and has `P_13_1 = -200`.

---

## Validation

Validate the result:

```bash
npx @ksefuj/validator correction.xml
```

Validator codes that matter for corrective invoices:

- `RODZAJ_FAKTURY_SECTIONS`: KOR, KOR_ZAL and KOR_ROZ require `DaneFaKorygowanej`
- `KOR_NRKSEF_CONSISTENCY`: exactly one of `NrKSeF`/`NrKSeFN`
- `REVERSE_CHARGE_CONSISTENCY`: `P_18` must match the line-level rate codes
- `TAX_CALCULATION_MISMATCH`, `DUPLICATE_LINE_NUMBERS`, `NEGATIVE_QUANTITY_NOT_ALLOWED`: skipped for
  corrective types, because deltas, repeated line numbers and negative quantities are expected
- `PODMIOT2_JST_MISSING`, `PODMIOT2_GV_MISSING`: `Podmiot2` always needs `JST` and `GV`
- `KURS_WALUTY_Z_PLACEMENT`: `Fa/KursWalutyZ` is valid only on ZAL and KOR_ZAL

---

## Constraints

- A buyer NIP is never changed by a correction: zero the invoice and reissue.
- Noty korygujące (buyer-issued correction notes) no longer exist since 1 February 2026. All
  corrections are corrective invoices issued by the seller.
- Once in KSeF, an invoice cannot be edited or deleted. It is stored for 10 years.
- A test invoice sent to production is a real invoice. If one was sent by mistake, correct it to
  zero immediately.
- If data is ambiguous or missing, ask the user. Do not guess or insert placeholder values.
