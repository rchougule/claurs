Extract and structure financial data from source documents into standardized CSVs.

## Context

Personal finance tracking repo. Data stored as quarterly snapshots in `source/` with naming convention `<type>_<quarter><year>.csv` (e.g., `mf_portfolio_apr2026.csv`). This skill is built for **Indian residents** but can adapt for other jurisdictions — see localization notes.

## Arguments

Optional: `/financial-data <quarter>` (e.g., `/financial-data jul2026`). If provided, skips the quarter prompt. $ARGUMENTS

## Step 0: First-Time Setup (skip if `source/profile.md` exists)

If `source/profile.md` does not exist:
1. Explain what this skill does and what data it produces
2. Guide the user through creating `source/profile.md` with ALL of these sections:

```
Required sections in source/profile.md:

## Personal
- Name, Age, Gender, Location, Marital status, Marriage timeline, Dependents
- Partner details (earning profile, sector) if applicable

## Employment
- Employer, Role, Job stability (HIGH/MEDIUM/LOW with reason)
- Income type: salaried / freelance / mixed
- If salaried: CTC, in-hand salary, tax deducted, EPF contribution, basic salary
- If freelance: avg monthly income, lowest month in past 6, highest, payment reliability
- If multiple income sources: list each with amount and frequency

## Monthly Expenses
- Itemized breakdown (rent, groceries, utilities, transport, health, misc)
- Total, and what it can compress to in austerity

## Liabilities
- Home loan, car loan, education loan, personal loan, credit card debt
- For each: outstanding amount, EMI, interest rate, remaining tenure

## Insurance
- Health: provider, cover amount, premium, family/individual
- Term life: provider, cover amount, premium (or "planned" / "none")
- Critical illness, disability: if any

## Risk Assessment
- Behavioral: "If portfolio dropped 20% in a month, I would: sell / hold / continue SIPs / increase SIPs"
- Emergency fund months target
- Years to retirement

## Investment Platforms
- Where MFs, stocks, PPF, EPF, NPS, FDs etc. are held

## Tax Situation
- Tax regime (Old / New / TBD), HRA claim, excess EPF details

## Life Goals & Priorities
- Each goal: timeline, estimated cost (your share), priority (CRITICAL/HIGH/MEDIUM/LOW)
- Common: emergency fund, marriage, house, children's education, retirement, sabbatical

## Hard Rules
- Any constraints the financial plan MUST follow
```

If the profile exists but is missing critical fields (income, expenses, or goals), ask the user to fill those before proceeding.

## Step 1: Determine Quarter

If quarter was passed as argument, use it. Otherwise ask: **"What quarter is this data for?"** (e.g., Apr 2026, Jul 2026). Use this to suffix all output files.

## Step 2: Gather Source Documents

Ask the user what documents they have. **Accept any format** — PDF, screenshot/image, Excel, CSV, copy-pasted text, or a Google Sheet link.

| Data needed | Accepted sources | Output file |
|---|---|---|
| MF holdings | CAMS CAS, KFintech CAS, MFCentral CAS, individual AMC statements, broker exports (Zerodha/Groww/Kuvera/INDmoney/Paytm Money), or copy-pasted text | `mf_portfolio_<quarter>.csv` |
| Active SIPs/STPs | Broker app screenshot, export, or self-reported list from any platform | `mf_sips_<quarter>.csv` |
| International/US stocks | Screenshot or export from any broker (Vested, INDmoney, Interactive Brokers, Groww, ICICI Global, etc.) | `us_stocks_<quarter>.csv` |
| Indian direct stocks | Broker portfolio export or screenshot (Zerodha, Groww, etc.) | `indian_stocks_<quarter>.csv` |
| Income & expenses | Salary slip, bank statement, freelance invoice summary, or self-reported | `monthly_cashflow_<quarter>.csv` |
| EPF/PPF/NPS/FDs/other fixed income | Passbook, EPFO screenshot, bank FD receipt, NPS statement | `fixed_income_<quarter>.csv` |
| Liabilities | Loan statements, EMI schedules, or self-reported | `liabilities_<quarter>.csv` |
| Other assets | Gold (physical/digital/SGB), real estate, crypto, ULIPs, etc. | `other_assets_<quarter>.csv` |

**Important notes:**
- **Partial data is fine.** Only create CSVs for data the user actually provides. Do not block on missing categories.
- If previous quarter data exists for a missing category, offer to carry it forward with a note.
- **Demat vs non-demat MFs:** A CAMS/KFintech CAS only shows non-demat holdings. If user holds MFs in demat mode (through Zerodha, Groww, etc.), ask if they have broker export too.
- **CAMS vs KFintech:** CAMS covers CAMS-serviced AMCs only. KFintech covers others (SBI, Nippon, HDFC, etc.). MFCentral CAS covers both (preferred). If user provides CAMS-only, warn about potentially missing KFintech-serviced funds.

### Handling Screenshots and Images
- Read image files directly (Claude supports JPEG, PNG, etc.)
- **Flag uncertain values** with `[?]` and ask user to verify
- If data spans multiple screenshots, ask: "This looks partial. Do you have more screenshots?"
- For WhatsApp images: compression makes digits ambiguous (3 vs 8, 1 vs 7). Flag any ambiguous digits.

### Handling Excel/Google Sheets
- Claude cannot parse Excel binaries directly. Ask user to export as CSV or paste contents as text.
- For Google Sheets: ask user to paste the data or share via Google Workspace MCP tools.

## Step 3: Extract Data

For each document:
1. Read/parse the document
2. Extract into the CSV format below
3. **Before writing any file:** check if a file with the same name exists. If yes, ask: "File exists (last modified <date>). Overwrite, create _v2, or show diff?"
4. Show preview to user for verification
5. Save after user confirms

### CSV Schemas

**mf_portfolio_<quarter>.csv:**
```
fund_name,category,sub_category,platform,folio,units,nav_inr,cost_inr,market_value_inr,gain_loss_inr,gain_loss_pct,notes
```
- `category`: Equity, Debt, Hybrid, Gold, Others
- `sub_category`: Small Cap, Large & Mid Cap, Index/Momentum, Sectoral, Multi Asset, Corporate Bond, Fund of Funds, Liquid, etc.
- `notes`: use for STP source, demat/non-demat, or other context
- Verify: `market_value_inr ≈ units × nav_inr` (allow 1% tolerance)
- Verify: `gain_loss_inr = market_value_inr - cost_inr`
- Multiple folios for the same fund are valid — do not deduplicate

**mf_sips_<quarter>.csv:**
```
fund_name,category,sip_amount_inr,frequency,next_date,status,platform,notes
```
- `notes`: for STPs, include source fund (e.g., "STP from UTI Liquid"). For AMC SIPs vs platform SIPs, note the distinction.

**us_stocks_<quarter>.csv:** (or `intl_stocks_<quarter>.csv` if non-US included)
```
stock,ticker,shares,avg_cost_usd,current_price_usd,invested_usd,current_value_usd,gain_loss_usd,gain_loss_pct,invested_inr,current_value_inr,platform,status,notes
```
- **Always fetch live exchange rate** via web search before computing INR values. Never assume.
- Record rate in first row notes: `USD/INR = XX.X as of YYYY-MM-DD`
- For non-USD holdings: use appropriate currency columns and note the rate

**indian_stocks_<quarter>.csv:** (only if user holds direct Indian equities)
```
ticker,company,exchange,shares,avg_cost_inr,current_price_inr,invested_inr,current_value_inr,gain_loss_inr,gain_loss_pct,platform,notes
```

**monthly_cashflow_<quarter>.csv:**
```
category,item,amount_inr,frequency,notes
```
- Categories: Income, Freelance_Income, Rental_Income, Dividend, Interest, Tax, Advance_Tax, GST, EPF, VPF, Expense, EMI, Insurance_Premium, Investment, Surplus
- For variable-income users: use average monthly income and note the range

**fixed_income_<quarter>.csv:**
```
instrument,type,provider,current_balance_inr,invested_amount_inr,monthly_contribution_inr,interest_rate_pct,maturity_date,lock_in_end,tax_treatment,notes
```
- Types: epf, vpf, ppf, nps, fd, rd, scss, sgb, nsc, kvp, sukanya, corporate_bond, govt_bond, tax_free_bond, other

**liabilities_<quarter>.csv:** (only if user has loans/debt)
```
liability,type,lender,outstanding_inr,emi_inr,interest_rate_pct,start_date,end_date,notes
```
- Types: home_loan, car_loan, education_loan, personal_loan, credit_card, other

**other_assets_<quarter>.csv:** (only if user has gold/real estate/crypto/etc.)
```
asset,type,description,acquisition_date,cost_inr,current_value_inr,valuation_method,notes
```
- Types: physical_gold, digital_gold, sgb, real_estate, crypto, ulip, endowment, other

## Step 4: Create Net Worth Snapshot

Generate `source/net_worth_snapshot_<quarter>.md` combining all CSVs:

Include:
- **Asset summary table:** Each asset class with cost, current value, gain/loss
- **Liability summary:** Total outstanding, total EMI/month
- **Net worth = Total assets - Total liabilities**
- **Asset allocation breakdown** by category (equity, debt, gold, international, real estate, cash)
- **Monthly SIP summary** with total
- **Monthly cashflow summary** with surplus/deficit
- **Emergency fund status:** Which instruments serve as emergency fund (per profile), current value, months of expenses covered
- **Allocation compliance:** Check profile hard rules against actuals (e.g., "ICICI Multi Asset cap 35%" → actual 31.8% → OK)
- **Pending decisions** (what needs action)

## Step 5: Validate

1. MF: `market_value ≈ units × NAV` for each row (1% tolerance)
2. MF: `gain_loss = market_value - cost` for each row
3. MF: No row with negative units or zero units
4. SIPs: Every SIP fund should have a corresponding portfolio entry (warn if missing — may be new)
5. SIPs: Total SIP matches Investment rows in cashflow
6. Cashflow: Income - deductions - expenses - investments = surplus (must balance)
7. Net worth: All components sum correctly
8. US/intl stocks: Exchange rate stated and used consistently
9. US/intl stocks: `gain_loss = current_value - invested` for each row
10. Cross-check: If previous quarter exists, flag any fund that disappeared (may indicate missed data, not a sale)

## Step 6: Compare with Previous Quarter (if exists)

If previous quarter data exists:
- Check if schemas match. If different, map old columns to new and compare only shared columns.
- Generate comparison: net worth change, new/removed funds, SIP changes, significant P&L movements
- Flag anything that looks wrong (e.g., net worth dropped 30% without any market crash)

## Step 7: Progress Summary

Output what was created:
```
--- Data extraction complete for <quarter> ---
Files created: [list]
Files carried forward: [list]
Files not created (no data provided): [list]
Next step: Run /financial-plan to build or review your investment plan.
```
