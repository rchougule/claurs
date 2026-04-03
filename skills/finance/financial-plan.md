Create or review an investment plan with full multi-agent vetting. Acts as a professional financial planner.

## Context

This repo contains personal financial data in `source/` (CSVs, snapshots) and investment plans in `plan/`. The plan goes through a rigorous build-vet-fix loop using parallel independent agents before being finalized. Built for Indian residents but adaptable.

## Arguments

Optional: `/financial-plan <mode>` where mode is `new`, `review`, `compare`, or `second-opinion`. If omitted, asks interactively. $ARGUMENTS

## Step 1: Prerequisites Check

**Always required:**
- `source/profile.md` — must have: Personal, Employment, Expenses, Liabilities, Insurance, Risk Assessment, Goals, Hard Rules

**Required if user holds these instruments** (check profile.md):
- `source/mf_portfolio_*.csv` — if MF holdings exist
- `source/mf_sips_*.csv` — if active SIPs exist
- `source/monthly_cashflow_*.csv` — income/expense breakdown
- `source/fixed_income_*.csv` — if EPF/PPF/NPS/FD exist
- `source/net_worth_snapshot_*.md` — if previous snapshot exists
- `source/us_stocks_*.csv` — if US/intl stock holdings exist
- `source/liabilities_*.csv` — if loans/EMIs exist

If profile.md is missing: tell user to run `/financial-data` first.
If source CSVs are outdated (quarter suffix doesn't match current quarter): suggest running `/financial-data` to update.
If a conditionally required file is missing but profile mentions that instrument: tell user. If profile doesn't mention it, skip silently.

## Step 2: Suitability Gate (MANDATORY — before any plan work)

Compute a suitability assessment from profile.md. This gates the entire plan.

### 2a: Risk Capacity Score
```
Base equity ceiling = 100 - age
Adjustments:
  + No dependents: +10
  + Dependents: -10
  + Within 5 years of retirement: -15
  + Job stability LOW: -10
  + Job stability HIGH: +5
  + EMI-to-income > 40%: cap equity at 50%
  + Emergency fund < 6 months expenses: MUST prioritize building it first

Computed max equity %: ___
```

### 2b: Insurance Adequacy Check
```
Term life: cover should be >= 10x annual income (minimum). Compute HLV if possible.
  - If no term life: FLAG AS #1 ACTION ITEM. No investment plan without protection.
  - If cover < 10x income: recommend increase with specific amount.
Health: minimum 10L single, 25L family. Check for super top-up if base < 50L.
Critical illness / disability: flag if missing entirely.
```

### 2c: Debt Triage
```
If credit card revolving debt exists: STOP. Recommend full payoff before any investment.
If any loan at > 12% interest: recommend prepayment over equity SIPs.
If EMI-to-income > 40%: flag as high risk.
```

### 2d: Present Findings
If computed max equity % conflicts with stated risk tolerance, present both to user and explain. Do NOT silently accept "aggressive" when numbers indicate otherwise. However, the user has final say.

## Step 3: Determine Mode

Ask: **"What mode?"**
- **New plan** — full plan from scratch
- **Quarterly review** — check triggers, update existing plan
- **Second opinion** — review a specific recommendation or external advisor's plan
- **Version comparison** — structured diff between two plan versions

### If quarterly review:
1. Find latest plan in `plan/` (highest version)
2. Read current source CSVs. If outdated, ask user to run `/financial-data` first.
3. **Trigger evaluation** — for each trigger in the plan:
   - Data triggers (portfolio %s, fund values): compute from current CSVs
   - Web triggers (SEBI, fund closures, rate changes): search the web
   - User triggers (life events): ask the user explicitly
   - Output: TRIGGER | CONDITION | CURRENT | FIRED? | ACTION
4. **Delta analysis:** compare current data vs plan-time data. Flag: performance changes >5%, new/closed funds, net worth deviation >10% from projected, expense/income changes.
5. Produce `plan/quarterly_review_<quarter>.md`
6. If changes are substantive (trigger fired or allocation drift >5%): proceed to Step 5 (vetting)

### If second opinion:
- Ask user for the recommendation(s) to review
- Run only relevant research agents
- Produce focused analysis (`plan/second_opinion_<quarter>.md`)
- Still run strategy + tax vetting on the specific recommendations

### If version comparison:
- Ask which two versions (default: latest two)
- Produce structured diff: allocation changes, asset class split, added/removed funds, budget changes, risk register delta, trigger changes, projected NW comparison
- Output: `plan/comparison_v<X>_v<Y>.md`

## Step 4: Build the Plan (New Plan Mode)

### 4a: Research Phase — Launch 3 parallel agents

**Agent 1: Fund Overlap Analysis**
- For every equity fund in portfolio, search web for top 20-25 holdings
- Build pairwise overlap matrix
- Identify stocks in 3+ funds
- Calculate effective diversification score
- Flag pairs with >40% overlap
- Cross-reference AMFI/SEBI fund categories — flag same-AMC same-category holdings

**Agent 2: Fund Performance & Regulatory Research**
- For every fund: latest 1yr/3yr/5yr rolling returns (not just trailing), expense ratio, AUM, managers, news
- Verify each fund's SEBI category under current categorization framework
- Check if any funds face forced merger/reclassification
- For international funds: confirm current subscription status under SEBI overseas cap
- Check if any funds' expense ratios exceed current TER limits
- Verify each fund is Direct plan (flag any Regular plan holdings)
- For each non-MF instrument in fixed_income CSV: current rate, rule changes, tax treatment
- Current USD/INR rate (if applicable)
- Term insurance premiums for user's age/gender
- At least 2 independent sources for every regulatory fact. If sources conflict, use most recent.

**Agent 3: Portfolio Simplification Analysis**
- Evaluate if fund count can be reduced
- For each consolidation: what's lost vs gained
- Propose 2-3 options (minimal, moderate, aggressive simplification)
- Academic evidence on optimal fund count

### 4b: Goal-Based Investment Map (MANDATORY)

Before allocating SIPs, map every goal from profile.md:

| Goal | Timeline | Today's Cost | Inflation Rate | Future Cost | Currently Earmarked | Monthly SIP Needed | Recommended Vehicle | Gap |
|---|---|---|---|---|---|---|---|---|

Rules:
- Goals < 3 years: 100% debt/liquid
- Goals 3-7 years: balanced (40-60% equity)
- Goals > 7 years: equity-heavy
- Retirement: use 4% withdrawal rule → required corpus → reverse-engineer monthly SIP at assumed CAGR with inflation
- Emergency fund: must be fully funded (or on track) BEFORE discretionary equity allocation

### 4c: Synthesis — Build Plan Document

Determine version number: scan `plan/investment_plan_<quarter>_v*.md`, use next version.

Create `plan/investment_plan_<quarter>_v<N>.md`. **Only include sections that apply to the user.** Sections marked (ALWAYS) are mandatory. Others are conditional — omit entirely if not applicable.

1. **(ALWAYS) Header** — date, profile summary, computed risk capacity, net worth
2. **(ALWAYS) Goal-Based Investment Map** — from Step 4b above
3. **(ALWAYS) Insurance Adequacy** — from Step 2b. If gaps exist, these are action items ABOVE any investment.
4. **(ALWAYS) Monthly SIP Allocation** — fund table with amount, % of flow, category, rationale. Budget verification: income - expenses - EMIs - investments - insurance - buffer = 0. For variable-income users: base allocation at minimum reliable income + conditional tier at higher income.
5. **(ALWAYS) Changes from Current SIPs** — before/after with broker-specific actions (not hardcoded to Zerodha — use whatever platform the user is on)
6. **(if applicable) Debt Triage** — loan prepayment vs investing analysis for each loan
7. **(if applicable) Fund Consolidation Rationale** — overlap analysis, what was dropped
8. **(if applicable) Lump Sum Deployment** — split, method (parallel time-bound SIPs preferred), timeline, tax
9. **(if applicable) International Stocks Decision**
10. **(ALWAYS) Goal-Based Liquidity** — for EACH near-term goal: funding source, projected value, access time
11. **(ALWAYS) Income Risk Contingency** — tiered response if income drops. For salaried: job-loss tiers. For freelance: income-band tiers. Must include health insurance premium in expense calculations. Account for potential severance if employer is winding down.
12. **(ALWAYS) Risk Register** — must include: income risk, market crash, fund-specific, regulatory (SEBI/tax), platform risk, inflation erosion, interest rate, AUM bloat (for large small-cap funds). For each, rate as CRITICAL/HIGH/MEDIUM/LOW.
13. **(ALWAYS) Conditional Triggers** — with specific thresholds and actions
14. **(ALWAYS) Quarterly Review Schedule**
15. **(ALWAYS) Portfolio Composition** — by category, asset class split, active vs passive
16. **(ALWAYS) Tax Notes** — correct Section references. Verify equity-orientation per fund (>65% equity = Section 112A treatment). For FoFs: check listed vs unlisted for holding period. For Multi-Asset: verify exact equity %.
17. **(if applicable) Current Month Execution Reality** — which SIPs already fired
18. **(ALWAYS) Action Items** — grouped by timeline. Insurance before investments.
19. **(ALWAYS) Fund Verdicts** — separate personal cost-basis returns from fund-level trailing returns
20. **(ALWAYS) Projected Net Worth** — 12-month with range. Test against retirement corpus gap from goal map.
21. **(if applicable) Estate Planning Checklist** — for NW > 1Cr: will, nominations audit, marriage implications

**Critical rules:**
- Tax sections: equity LTCG = Section 112A (1.25L exemption), gold FoF LTCG = Section 112 (NO exemption), debt = Section 50AA (slab rate). Verify per-fund structure before applying.
- Platform-agnostic: use user's actual platform from profile. Don't assume Zerodha.
- For deployment: parallel time-bound SIPs (auto-expire) over manual purchases.
- Distinguish personal cost-basis returns from fund-level trailing returns everywhere.
- Disclose all-in costs for FoF structures (fund ER + underlying).
- Enforce hard rules from profile BUT if a rule creates clear financial risk (zero emergency fund, extreme concentration, no insurance with dependents), follow the rule AND add an "Advisor Note" explaining the risk.
- Fund selection must use rolling returns across market cycles, not just recent trailing.
- Age-based allocation: if plan equity % exceeds computed ceiling from Step 2, flag in the plan with reasoning.

## Step 5: Vetting Loop — Launch 3 parallel agents

**Agent A: Math Verification**
- Budget equation (income = all outflows)
- SIP totals
- Deployment cashflow (if section exists — skip otherwise)
- Goal-based map: inflation-adjusted future costs, required SIP calculations
- Projected values (debt fund growth, net worth)
- Contingency tier calculations (outflows, runway)
- Tax estimates
- Percentages
- Version change reconciliation
- Output: numbered PASS/FAIL list

**Agent B: Financial Strategy Review**
- Fund selection: search web, use rolling returns across cycles, not just trailing
- Allocation vs computed risk capacity ceiling
- Goal-based adequacy: will plan meet each goal's corpus need?
- Insurance adequacy: term >= 10x income? Health sufficient? Critical illness?
- Sealed holdings: tax-loss harvesting opportunities?
- Contingency: are tiers actionable? Health insurance premium included?
- Operational feasibility: >10 actions in one period? Flag.
- Inflation adjustment: are goal amounts in real or nominal terms?
- Liquidity stress test: can user access 5L in 48 hours?
- Missing risks?
- Internal consistency (same numbers everywhere)
- If hard rules contradict sound practice: flag as CONCERN
- Output: PASS/CONCERN/FAIL per check

**Agent C: Tax & Regulatory Review**
- Fund availability (SEBI restrictions, current subscription status)
- Fund SEBI category compliance (2026 framework)
- Index fund AMC availability and expense ratios on user's platform
- All tax rates and exemptions (search web, 2+ sources each)
- Per-fund tax classification: equity-oriented (>65%) vs non-equity vs FoF
- Platform constraints (folio creation, SIP modification)
- Insurance premium verification
- Interest rates (PPF, EPF, NPS)
- Regular vs Direct plan check
- Output: PASS/FAIL with sources

## Step 6: Fix Issues

Categorize each FAIL:
- **CRITICAL** — wrong tax treatment, budget math error, regulatory claim factually wrong, missing insurance with dependents
- **MAJOR** — suboptimal allocation, missing risk, inconsistent numbers
- **MINOR** — rounding, formatting, stale data not affecting recommendations

Fix ALL items. For CONCERNs: fix or acknowledge as trade-off with reasoning.

**Re-vetting rules:**
- Any CRITICAL fail: re-vet (only the agent(s) that found it)
- More than 3 MAJOR fails: re-vet (targeted)
- Maximum 2 re-vet loops. If issues persist, list in "Known Issues" appendix.

## Step 7: Write Action Summary

Create `plan/action_summary_<quarter>_v<N>.md` — one-stop execution doc. **Only include sections that apply:**

- **A. SIP Changes** — before/after with broker-specific actions
- **B. Lump Sum Deployment** — step-by-step (if applicable)
- **C. International Stocks** — decisions (if applicable)
- **D. Insurance Actions** — FIRST if gaps exist
- **E. Non-Investment Actions** — tax, nominees, estate, etc.
- **F. Goal-Based Liquidity** — sources with projected values
- **G. Income Risk Contingency** — condensed tier table
- **H. Monitoring Triggers** — what/when/action
- **I. Quarterly Review Calendar**
- **J. Monthly Budget Verification** — line-by-line
- **K. Tax Reference Card**
- **L. Key Risks** — condensed
- **M. Fund Overlap Summary** (if applicable)
- **N. Changes from Previous Version** (if applicable)

Every number must match the plan exactly.

## Step 8: Validate Summary

Launch 2 parallel agents:

**Agent D: Summary-Plan Sync** — every number, fund name, claim in summary matches plan. Check totals, budget, deployment, projections, tax rates, tiers, risk count, trigger count.

**Agent E: Summary Math** — verify every calculation independently.

Fix any FAIL items.

## Step 9: Save

If git repo: stage, commit with descriptive message including validation results. Ask user about push.
If not git repo: list all created/modified files.
