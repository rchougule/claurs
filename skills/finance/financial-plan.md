Create or review an investment plan with full multi-agent vetting. Acts as a professional financial planner for an Indian retail investor.

## Context

This repo contains personal financial data in `source/` (CSVs, snapshots) and investment plans in `plan/`. The plan goes through a rigorous build-vet-fix loop using parallel independent agents before being finalized.

## Step 1: Prerequisites Check

Read these files. If any are missing, stop and tell the user what's needed.

**Required:**
- `source/profile.md` — personal financial profile (age, salary, expenses, goals, risk tolerance, hard rules)
- `source/mf_portfolio_*.csv` — latest MF holdings
- `source/mf_sips_*.csv` — current SIPs
- `source/monthly_cashflow_*.csv` — income/expense breakdown
- `source/fixed_income_*.csv` — EPF/PPF balances
- `source/net_worth_snapshot_*.md` — combined net worth

If `source/profile.md` is missing: tell the user to run `/financial-data` first, or create `source/profile.md` with these required sections: Personal (age, location, marital status, dependents), Employment (employer, role, stability, salary breakdown), Monthly Expenses (itemized), Insurance, Investment Platforms, Tax Situation, Life Goals (with timelines and costs), Hard Rules.

If source CSVs are outdated (check the quarter suffix): tell the user to run `/financial-data` to update them first.

## Step 2: Determine Mode

Ask the user: **"Is this a new plan or a quarterly review?"**

### If quarterly review:
- Find the latest plan in `plan/` (highest version number)
- Read it alongside current source data
- Check all monitoring triggers in the plan against current data
- Identify what changed since the plan was written
- Propose specific updates (not a full rewrite)
- Then proceed to Step 4 (vetting) with the proposed changes

### If new plan:
- Check if previous plan versions exist in `plan/` — read them for context but do not copy blindly
- Proceed to Step 3

## Step 3: Build the Plan (New Plan Mode)

### 3a: Research Phase — Launch 3 parallel agents

**Agent 1: Fund Overlap Analysis**
- For every equity fund in the current portfolio (from mf_portfolio CSV), search the web for top 20-25 holdings
- Build a pairwise overlap matrix (stock count and names)
- Identify stocks in 3+ funds
- Calculate effective diversification score
- Flag any fund pairs with >40% overlap as consolidation candidates

**Agent 2: Fund Performance & Regulatory Research**
- For every fund in the portfolio, search for: latest 1yr/3yr/5yr returns, expense ratio, AUM, manager names, any recent news
- Search for latest SEBI rules on international MF investing (overseas cap status)
- Search for latest EPF interest rate, PPF interest rate
- Search for latest MF taxation rules (STCG, LTCG, debt fund, gold FoF — verify Section 112 vs 112A applicability)
- Search for current USD/INR rate
- Search for latest term insurance premiums for the user's age/gender

**Agent 3: Portfolio Simplification Analysis**
- Evaluate whether the current number of funds can be reduced
- For each potential consolidation, calculate what's lost vs gained
- Propose 2-3 portfolio options (minimal change, moderate simplification, aggressive simplification)
- Reference academic evidence on optimal fund count for Indian retail investors

### 3b: Synthesis — Build the Plan Document

Using research from all 3 agents + source data + profile, create `plan/investment_plan_<quarter>_v1.md` with these sections:

1. **Header** — date, profile summary, risk tolerance, net worth
2. **Monthly SIP Allocation** — fund table with amount, % of flow, category, rationale. Must include verification that salary = expenses + MFs + PPF + insurance + buffer.
3. **Changes from Current SIPs** — before/after table with Zerodha actions
4. **Fund Consolidation Rationale** — overlap analysis summary, what was dropped and why
5. **Lump Sum Deployment** (if applicable) — split, deployment method, timeline, tax implications
6. **US Stocks Decision** (if applicable)
7. **Goal-Based Liquidity** — marriage fund, emergency fund, with projected values
8. **Job Loss / Income Risk Contingency** — tiered response plan if income drops
9. **Risk Register** — probability, impact, mitigation for each risk. Must include: job loss, market crash, fund-specific risks, regulatory risks, platform risk, inflation, tax regime change
10. **Conditional Triggers** — what to monitor and what action to take
11. **Quarterly Review Schedule**
12. **Portfolio Composition** — by category, asset class split, active vs passive split
13. **Tax Notes** — all relevant tax rules with correct Section references
14. **Current Month Execution Reality** — which SIPs already executed, what can still be changed
15. **Action Items** — grouped by timeline (this week, this month, before next quarter, quarterly)
16. **Fund Verdicts** — one-line verdict per fund (core holding, buy the dip, sealed, eliminated, etc.)
17. **Projected Net Worth** — 12-month projection with assumptions and range

**Critical rules for the plan:**
- Always use correct tax sections: equity LTCG = Section 112A (1.25L exemption), gold FoF LTCG = Section 112 (NO exemption), debt = Section 50AA (slab rate)
- For Zerodha Coin: cannot create separate folios in same scheme. Use different funds if separation needed.
- For deployment: use parallel time-bound SIPs (auto-expire) instead of manual purchases. SIP end dates prevent reversion risk.
- All amounts in INR unless explicitly marked USD
- Distinguish between personal cost-basis returns and fund-level trailing returns
- Disclose all-in costs for FoF structures (fund ER + underlying ETF/fund ER)
- Read the user's hard rules from profile.md and enforce them throughout

## Step 4: Vetting Loop — Launch 3 parallel agents

**Agent A: Math Verification**
Verify every number in the plan:
- Budget equation (salary = all outflows)
- SIP totals
- Deployment cashflow (if applicable)
- Projected values (Kotak/debt growth, net worth projection)
- Contingency tier calculations (monthly outflows, runway months)
- Tax estimates
- Percentage calculations
- v(N-1) to v(N) change reconciliation
Output: numbered list of checks with PASS/FAIL

**Agent B: Financial Strategy Review**
Challenge every assumption:
- Fund selection: search web for latest data on each fund
- Allocation proportionality: is anything too aggressive or too conservative for the profile?
- Goal-based adequacy: will the plan actually meet the stated goals?
- Sealed holdings: is "do nothing" correct? Tax-loss harvesting opportunities?
- Contingency realism: are the tiers actionable?
- Deployment method: Zerodha-specific constraints?
- Missing risks: what's NOT in the risk register?
- Internal consistency: same numbers everywhere?
Output: 10-point review with PASS/CONCERN/FAIL per check

**Agent C: Tax & Regulatory Review**
Verify all regulatory claims:
- Fund availability (SEBI restrictions, fund closures)
- Index fund AMC names and expense ratios
- All tax rates and exemptions (search web for latest)
- Platform-specific constraints (folio creation, SIP modification)
- Insurance premium estimates
- Interest rates (PPF, EPF)
- NPS rules
Output: numbered checks with PASS/FAIL and sources

## Step 5: Fix Issues

Collect all FAIL and CONCERN items from the 3 vetting agents. Fix each one in the plan document. For CONCERNs, decide whether to fix or acknowledge as a known trade-off (document the reasoning).

If there are more than 3 FAIL items, repeat the vetting loop (Step 4) after fixes. Otherwise proceed.

## Step 6: Write Action Summary

Create `plan/action_summary_<quarter>_v<N>.md` — a one-stop execution doc with these sections:

- **A. SIP Changes** — before/after table with Zerodha actions and reasons
- **B. Lump Sum Deployment** (if applicable) — step-by-step with amounts and timing
- **C. US Stocks** (if applicable) — decisions table
- **D. Non-Investment Actions** — insurance, job search, tax, nominees, etc.
- **E. Goal-Based Liquidity** — sources table with projected values and access time
- **F. Job Loss Contingency** — condensed tier table
- **G. Monitoring Triggers** — what/when/action table
- **H. Quarterly Review Calendar**
- **I. Monthly Budget Verification** — line-by-line budget table
- **J. Tax Reference Card**
- **K. Key Risks** — condensed risk table
- **L. Fund Overlap Summary** (if applicable)
- **M. Changes from Previous Version** (if applicable) — at-a-glance table

Every number in the summary must match the plan exactly.

## Step 7: Validate Summary

Launch 2 parallel agents:

**Agent D: Summary-Plan Sync**
Compare every number, fund name, and claim in the summary against the plan. Check: fund amounts, totals, budget equation, deployment details, marriage/emergency projections, tax rates, contingency tiers, risk count, trigger count, all cross-references.

**Agent E: Summary Math**
Verify every calculation in the summary independently.

Fix any FAIL items found.

## Step 8: Commit

Stage and commit all new/modified files with a descriptive commit message summarizing what changed and the validation results.

Ask the user if they want to push to remote.

$ARGUMENTS
