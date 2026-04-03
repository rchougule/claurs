Extract and structure financial data from source documents into standardized CSVs for the finance repo.

## Context

This is a personal finance tracking repo. Source data comes from CAMS consolidated statements (PDF), Zerodha Coin screenshots, broker apps, and bank statements. Data is stored as quarterly snapshots in `source/` with the naming convention `<type>_<quarter><year>.csv` (e.g., `mf_portfolio_apr2026.csv`).

## Step 1: Check Profile

Read `source/profile.md`. If it does not exist, stop and ask the user to create it first using this template:

```
Required fields in source/profile.md:
- Personal: age, gender, location, marital status, dependents, marriage timeline
- Employment: employer, role, job stability, in-hand salary, EPF contribution
- Monthly expenses: itemized breakdown
- Insurance: health and term life details
- Investment platforms: where MFs, stocks, PPF, EPF are held
- Tax situation: regime, excess EPF, HRA status
- Life goals: with timelines and estimated costs
- Hard rules: any constraints on investment approach
```

If the profile exists but is missing critical fields (salary, expenses, or employment), ask the user to fill those in before proceeding.

## Step 2: Determine Quarter

Ask the user: **"What quarter is this data for?"** (e.g., Apr 2026, Jul 2026, Oct 2026, Jan 2027). Use this to name all output files.

## Step 3: Gather Source Documents

Ask the user what source documents they have available. For each:

| Document | What to extract | Output file |
|---|---|---|
| CAMS consolidated statement (PDF) | Fund name, category, units, NAV, cost, market value, gain/loss per folio | `mf_portfolio_<quarter>.csv` |
| Zerodha Coin SIP screenshot(s) | Fund name, SIP amount, frequency, next execution date, status | `mf_sips_<quarter>.csv` |
| US stocks screenshot (INDmoney/fi.money/broker) | Ticker, shares, avg cost, current price, invested INR, current value USD, P&L | `us_stocks_<quarter>.csv` |
| Salary slip / bank statement | In-hand salary, tax deducted, EPF, other deductions | `monthly_cashflow_<quarter>.csv` |
| EPF passbook / EPFO screenshot | EPF balance, monthly contribution (employer+employee) | `fixed_income_<quarter>.csv` |
| PPF passbook | PPF balance, monthly contribution, interest rate | Added to `fixed_income_<quarter>.csv` |

For US stocks: **Always fetch the live USD/INR exchange rate** via web search before computing INR values. Never assume a rate.

## Step 4: Extract Data

For each document provided:
1. Read/parse the document
2. Extract data into the standardized CSV format
3. Show the user a preview of the extracted data for verification
4. Ask if corrections are needed before saving

### CSV Formats

**mf_portfolio_<quarter>.csv:**
```
fund_name,category,folio,units,nav,cost_inr,market_value_inr,gain_loss_inr,gain_loss_pct,platform
```

**mf_sips_<quarter>.csv:**
```
fund_name,sip_amount,frequency,next_date,status,platform,notes
```

**us_stocks_<quarter>.csv:**
```
ticker,company,shares,avg_cost_usd,current_price_usd,invested_inr,current_value_usd,current_value_inr,pnl_inr,pnl_pct,platform,notes
```

**monthly_cashflow_<quarter>.csv:**
```
item,amount_inr,type,notes
```
Types: income, tax, epf, expense, investment, surplus

**fixed_income_<quarter>.csv:**
```
instrument,balance_inr,monthly_contribution_inr,interest_rate_pct,notes
```

## Step 5: Create Net Worth Snapshot

After all CSVs are created, generate `source/net_worth_snapshot_<quarter>.md` that combines:
- MF portfolio total (from mf_portfolio CSV)
- US stocks total (from us_stocks CSV, at live USD/INR rate)
- EPF balance (from fixed_income CSV)
- PPF balance (from fixed_income CSV)
- Bank balance / cash (ask user)
- Any other assets (ask user)

Include:
- Asset allocation breakdown by category (equity, debt, gold, international, cash)
- Monthly SIP summary
- Monthly cashflow summary
- Pending decisions (what needs action)

## Step 6: Validate

Run validation checks:
1. MF SIP total matches what user reports
2. Net worth components sum correctly
3. Monthly cashflow equation balances (income - tax - EPF = in-hand; in-hand - expenses - investments = surplus)
4. No duplicate fund entries
5. US stock values use the live exchange rate (state the rate used)

## Step 7: Compare with Previous Quarter (if exists)

If previous quarter data exists in `source/`, generate a brief comparison:
- Net worth change
- New funds added / funds removed
- SIP amount changes
- Significant P&L changes

$ARGUMENTS
