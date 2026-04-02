# NIMCRUT Investment Management — Fiduciary Breach Analysis

## Background

This document concerns a **Net Income with Makeup Charitable Remainder Unitrust (NIMCRUT)**,
account number 1603387, managed by a financial advisor holding a CFA designation at a bank
running the **SEI Investments trust platform**. Quarterly brokerage statements covering
**2023-Q4 through 2025-Q4** have been parsed from PDF; all transaction and holdings data
below is drawn from those statements.

A NIMCRUT is a **tax-exempt** trust. It pays its income beneficiary based on net income
actually earned each year, with a "makeup" provision allowing deferred distributions to be
paid in later years of higher income. The trust itself pays **no federal income tax**. The
remainder ultimately passes to charity.

We are investigating two categories of potential fiduciary breach:

1. **Tax-inefficient placement**: Putting tax-exempt or tax-advantaged securities inside an
   already tax-exempt trust, where the tax benefit is worthless to the trust and where the
   lower yield that comes with that tax benefit directly harms the income beneficiary.

2. **Undisclosed compensation / revenue sharing**: Placing clients in proprietary or
   affiliated funds that pay 12b-1 fees, shareholder service fees, sub-transfer-agent fees,
   or other revenue-sharing arrangements back to the advisor or their firm — without adequate
   disclosure or a demonstrable best-interest basis for the selection.

---

## The SEI Platform Pattern

This is the central structural conflict. Nearly every fund in this account is either:
- A **SEI-branded fund** (TFCAX, TMMAX, SVOAX, COIAX, AABXX, SELV), or
- A fund **distributed through SEI's infrastructure** (Champlain Mid Cap, Champlain Small
  Company — both use SEI Investments Distribution Co. as distributor and SEI Investments
  Global Funds Services as administrator)

SEI Investments Company provides the core technology and fund platform to bank trust
departments. Banks that run on the SEI platform sell SEI Class F funds exclusively through
that platform. **SEI Class F shares are not available to the general public** — they are
only sold through authorized SEI financial institution partners.

Every SEI Class F fund in this account (TFCAX, TMMAX, SVOAX, COIAX) pays up to **0.25%
per year** in shareholder service fees to the distributing institution under the fund's
Shareholder Service Plan. This fee does not appear as a "12b-1 fee" line item — it is
buried in "Other Expenses" — but it flows economically to the managing bank as compensation
for "ongoing servicing of shareholder accounts." It is revenue sharing by another name.

The AABXX Government Fund "Wealth Class" (formerly "Sweep Class") is the SEI-designated
cash sweep vehicle for bank trust accounts. Its "Other Expenses" similarly include service
fees flowing to the custodian.

In short: the bank chose a platform (SEI) that manufactures and distributes the funds the
bank then sells to its trust clients. Every dollar in a SEI fund generates fee income for
the bank beyond the stated advisory fee.

---

## Holdings — Complete Securities List

| Our Key       | Full Name (from statements)                                        | Ticker  |
|---------------|--------------------------------------------------------------------|---------|
| AH_AABXX      | Government Fund (AABXX)                                            | AABXX   |
| AH_AEC250M2   | American Express Co 2.55% 04 Mar 2027                              | —       |
| AH_AI191A2    | Alphabet Inc 1.998% 15 Aug 2026                                    | —       |
| AH_AP         | Alexza Pharmaceuticals                                             | —       |
| AH_CC310M2    | Comcast Corp 3.15% 01 Mar 2026                                     | —       |
| AH_CC311F2    | Comcast Corp 3.15% 15 Feb 2028                                     | —       |
| AH_CI341M2    | Caterpillar Inc 3.4% 15 May 2024                                   | —       |
| AH_CI371J2    | Citigroup Inc 3.75% 16 Jun 2024                                    | —       |
| AH_CMCF       | Champlain Mid Cap Fund                                             | CIPMX   |
| AH_COIAX      | Conservative Income Fund                                           | COIAX   |
| AH_CSCF       | Champlain Small Company Fund                                       | CIPSX   |
| AH_CSI360M2   | Cisco Systems Inc 3.625% 04 Mar 2024                               | —       |
| AH_EIOWI      | Expeditors International of Washington Inc                         | EXPD    |
| AH_EMC300M2   | Exxon Mobil Corp 3.043% 01 Mar 2026                                | —       |
| AH_FTCSE      | First Trust Capital Strength ETF                                   | FTCS    |
| AH_GSGIT352J2 | Goldman Sachs Group Inc/The 3.5% 23 Jan 2025                       | —       |
| AH_GSGPIOF    | Goldman Sachs GQG Partners International Opportunities Fund        | GSIHX   |
| AH_GSI290M2   | Gilead Sciences Inc 2.95% 01 Mar 2027                              | —       |
| AH_IDC        | Insured Deposit Cash                                               | —       |
| AH_JCC312J2   | JPMorgan Chase & Co 3.125% 23 Jan 2025                             | —       |
| AH_LLSCSF     | LoCorr Long/Short Commodities Strategy Fund                        | LCSAX   |
| AH_LMSF       | LoCorr Macro Strategies Fund                                       | LFMAX   |
| AH_MC330F2    | Microsoft Corp 3.3% 06 Feb 2027                                    | —       |
| AH_NGC321J2   | Northrop Grumman Corp 3.25% 15 Jan 2028                            | —       |
| AH_PI230O2    | PepsiCo Inc 2.375% 06 Oct 2026                                     | —       |
| AH_SC         | Stryker Corp                                                       | SYK     |
| AH_SELVULCE   | SEI Enhanced Low Volatility US Large Cap ETF                       | SELV    |
| AH_SIFB321M2  | Shell International Finance BV 3.25% 11 May 2025                   | —       |
| AH_SVOAX      | U.S. Managed Volatility Fund                                       | SVOAX   |
| AH_TC191J2    | Target Corp 1.95% 15 Jan 2027                                      | —       |
| AH_TCIS371A2  | TotalEnergies Capital International SA 3.75% 10 Apr 2024           | —       |
| AH_TFCAX      | Tax-Free Conservative Income Fund                                  | TFCAX   |
| AH_TMMAX      | Tax-Managed Volatility Fund                                        | TMMAX   |
| AH_UB330F2    | US Bancorp 3.375% 05 Feb 2024                                      | —       |
| AH_VCI432S2   | Verizon Communications Inc 4.329% 21 Sep 2028                      | —       |
| AH_WI352J2    | Walmart Inc 3.55% 26 Jun 2025                                      | —       |
| AH_WSCGF      | Wasatch Small Cap Growth Fund                                       | WAAEX   |

---

## Fund Fee and Compensation Summary

Sourced from SEC EDGAR prospectus filings (485BPOS). All data verified against current filings.

| Fund | Ticker | Manager | Exp. Ratio | 12b-1 | Sales Load | Bank Revenue |
|------|--------|---------|------------|-------|------------|--------------|
| Tax-Free Conservative Income | TFCAX (F) | SEI/SIMC + BlackRock | 0.70% | None | None | 0.25%/yr service fee (Other Exp.) |
| Tax-Managed Volatility | TMMAX (F) | SEI/SIMC + Acadian | 1.14% | None | None | 0.25%/yr service fee (Other Exp.) |
| U.S. Managed Volatility | SVOAX (F) | SEI/SIMC + Acadian/Parametric | 1.14% | None | None | 0.25%/yr service fee (Other Exp.) |
| Conservative Income | COIAX (F) | SEI/SIMC + BlackRock | 0.59% | None | None | 0.25%/yr service fee (Other Exp.) |
| Government Fund | AABXX (Wealth) | SEI/SIMC + BlackRock/MetLife/Wellington | 0.45% | None | None | Service fee in Other Exp. |
| GQG Partners Intl Opportunities | GSIHX (A) | Goldman Sachs/GQG Partners | 1.14% | 0.25%/yr | 5.50% | 12b-1 + front-end load |
| Champlain Mid Cap | CIPMX (Adv) | Champlain IP / SEI dist. | 1.09% | 0.25%/yr | None | 12b-1 on Advisor shares |
| Champlain Small Company | CIPSX (Adv) | Champlain IP / SEI dist. | 1.26% | 0.25%/yr | None | 12b-1 on Advisor shares |
| First Trust Capital Strength ETF | FTCS | First Trust Advisors | 0.52% | None | None | **None** |
| LoCorr Long/Short Commodities | LCSAX (A) | LoCorr Fund Management | 2.37% | 0.25%/yr | 5.75% | 12b-1 + load + **additional cash payments** |
| LoCorr Macro Strategies | LFMAX (A) | LoCorr Fund Management | 2.13% | 0.25%/yr | 5.75% | 12b-1 + load + **additional cash payments** |
| SEI Enhanced Low Volatility ETF | SELV | SEI/SIMC | 0.15% | None | None | Proprietary; no trail |
| Wasatch Small Cap Growth | WAAEX | Wasatch Global Investors | 1.14% | None | None | **None** |

SEC EDGAR source filings:
- SEI Institutional Managed Trust (CIK 0000804239), 485BPOS 2026-01-28, acc. 0001104659-26-007454
- SEI Daily Income Trust (CIK 0000701939), 485BPOS 2025-05-30, acc. 0001104659-25-054984
- Goldman Sachs Trust II (CIK 0001557156), 485BPOS 2026-02-26, acc. 0001193125-26-076832
- Advisors' Inner Circle Fund II (CIK 0000890540), 485BPOS 2024-04-29, acc. 0001398344-24-008208
- First Trust Exchange-Traded Fund (CIK 0001329377), 485BPOS 2025-04-30, acc. 0001445546-25-003047
- LoCorr Investment Trust (CIK 0001506768), 485BPOS 2025-04-30, acc. 0000894189-25-003187
- SEI Exchange Traded Funds (CIK 0001888997), 485BPOS 2025-07-29, acc. 0001104659-25-071789
- Wasatch Funds Trust (CIK 0000806633), 485BPOS 2026-01-28, acc. 0001193125-26-026899

---

## Key Transactions

### TFCAX — Tax-Free Conservative Income Fund

| Quarter | Action | Amount     |
|---------|--------|------------|
| 2024-Q1 | Buy    | $350,000   |
| 2024-Q1 | Buy    | $100,000   |
| 2024-Q3 | Buy    | $75,000    |
| 2024-Q3 | Sell   | $100,000   |
| 2024-Q4 | Buy    | $15,000    |
| 2024-Q4 | Sell   | $50,000    |
| 2025-Q1 | Buy    | $15,000    |
| 2025-Q1 | Sell   | $350,000   |
| 2025-Q1 | Sell   | $30,000    |

Total income recorded: **$29,844** (as interest)

Peak position approximately $555,000. Fund invests ≥80% in AMT-exempt municipal
securities. 2025 return: **2.61%** vs. COIAX (taxable equivalent, same manager) at
**4.23%** and AABXX (money market) at **4.88%**. The 160–225 basis point yield
penalty on ~$555k is the direct cost to the income beneficiary of holding a tax-free
fund inside a tax-exempt trust.

### TMMAX — Tax-Managed Volatility Fund
- Sold out entirely 2024-Q1: **$119,174**
- Income before liquidation: **$24,464** (long-term cap gains + dividends)
- Expense ratio 1.14%. "Tax-managed" strategy (minimizing taxable distributions) is
  irrelevant inside a tax-exempt trust — the trust pays no tax regardless.

### SVOAX — U.S. Managed Volatility Fund
- Sold out entirely 2023-Q4: **$209,919**
- Income before liquidation: **$1,013**
- Expense ratio 1.14%. Same "tax-managed" irrelevance as TMMAX.

### COIAX — Conservative Income Fund
- Bought **$375,000** in 2025-Q1, **$115,000** in 2025-Q2
- Income: **$12,518** (interest)
- Taxable equivalent of TFCAX; yields ~160bps more inside this trust.
  Replaced TFCAX after questions were raised — possibly in response to scrutiny.

### GSIHX — Goldman Sachs GQG Partners International Opportunities Fund
- Bought **$55,000** in 2025-Q2
- Income: **$1,458**
- If Class A shares: 5.50% front-end load + 0.25%/yr 12b-1. Goldman Sachs
  proprietary wrapper around independent sub-adviser GQG Partners.

### LCSAX / LFMAX — LoCorr Funds
- Each bought **~$70,000** in 2024-Q1; combined income **$8,992**
- Class A: 5.75% front-end load + 0.25%/yr 12b-1 + **additional cash payments**
  to intermediaries explicitly disclosed in prospectus ("pay to play")
- Among the most expensive funds in the portfolio at 2.13–2.37% expense ratio

### CIPMX / CIPSX — Champlain Funds
- Champlain Small Company bought and then sold for a net ~$100k gain in 2024-Q1
- Champlain Mid Cap bought $125,000 in 2024-Q1; income $25,472 (cap gains)
- Both distributed through SEI; Advisor shares carry 0.25%/yr 12b-1
- Champlain Small Company is **closed to new investors** except through qualifying
  programs — its presence here confirms the account is in a formal SEI institutional
  program

### AABXX — Government Fund (SEI "Wealth Class")
- Permanent sweep vehicle throughout the period
- Income: **$14,322** (interest)
- "Wealth Class" (formerly "Sweep Class") explicitly designed for bank trust
  accounts on the SEI platform; service fees embedded in Other Expenses

---

## Findings

### Finding 1 — Tax-Free Fund in a Tax-Exempt Trust (TFCAX)

TFCAX is a municipal bond fund whose entire value proposition is producing income
exempt from federal income tax. Inside a NIMCRUT, which already pays no federal
income tax, this benefit is **completely worthless to the trust or its beneficiary**.

Municipal bonds yield less than comparable taxable instruments because investors
pay a premium for the tax exemption. By holding TFCAX instead of COIAX or an
equivalent taxable fund, the income beneficiary received approximately **160–225
basis points less annual yield** on a position that peaked around $555,000 — for
a tax benefit that accrued only to the trust, not the beneficiary.

The fact that COIAX (the taxable equivalent, same manager, same platform) was later
substituted into the account after questions were raised strongly suggests the
advisor or firm recognized the misplacement when scrutinized.

### Finding 2 — Revenue Sharing Across the Portfolio

Multiple funds paid direct compensation to the managing institution beyond the
stated advisory fee:

- **All SEI Class F funds** (TFCAX, TMMAX, SVOAX, COIAX): up to 0.25%/yr
  shareholder service fee to the bank, disclosed in the Shareholder Service Plan
  section of the SAI, buried in "Other Expenses" rather than labeled as 12b-1
- **LoCorr funds** (LCSAX, LFMAX): 5.75% front-end load + 0.25%/yr 12b-1 +
  additional undisclosed cash payments to intermediaries per prospectus disclosure
- **Goldman Sachs GQG (GSIHX Class A)**: 5.50% front-end load + 0.25%/yr 12b-1
- **Champlain Advisor shares** (CIPMX, CIPSX): 0.25%/yr 12b-1

### Finding 3 — Proprietary Platform Conflict

The bank managing this account runs on the SEI Investments trust platform. SEI
Class F shares are **exclusively available through SEI's authorized institution
network** — they cannot be purchased by the general public or through an
independent broker. Every dollar placed in a SEI fund (TFCAX, TMMAX, SVOAX, COIAX,
AABXX, SELV) generates fee revenue for SEI, the platform provider, which is also
the economic partner of the managing bank.

This is a structural conflict of interest: the advisor's firm chose a platform that
manufactures the products the firm then recommends to its trust clients.

### Finding 4 — "Tax-Managed" Strategy Irrelevant in Tax-Exempt Account

TMMAX and SVOAX are marketed as "tax-managed" — meaning the funds themselves try
to minimize taxable distributions to their shareholders. This strategy has zero
value inside a NIMCRUT, which pays no tax on any income or gains regardless of
character. Holding these funds (at 1.14% expense ratio each) instead of lower-cost
equivalents cost the beneficiary in both fees and potentially in return, with no
compensating benefit.

---

## Questions for Further Research / Legal Review

1. Under the **Uniform Prudent Investor Act** and the **Restatement (Third) of
   Trusts**, does placement of tax-exempt securities in a tax-exempt trust constitute
   a breach of the duty of prudent investment? Is there case law on point?

2. Under **SEC Regulation Best Interest** (Reg BI) and FINRA suitability rules,
   what disclosure obligations applied to the SEI shareholder service fees and the
   LoCorr additional cash payments? Were those disclosed in the account's Form CRS
   or advisory agreement?

3. The account switched from receiving **full consolidated statements** (all accounts)
   to **NIMCRUT-only statements** after the beneficiary raised questions about a
   payment issued after the grantor's death and an unexplained inter-account transfer.
   What obligation, if any, does the trustee or custodian have to provide complete
   account statements to a NIMCRUT income beneficiary?

4. A **$30,000 disbursement** was recorded months after the grantor's death, and a
   separate **inter-account transfer** appears on statements with no destination
   account shown. What are the reporting and accounting obligations for a trustee
   when a grantor dies mid-quarter, and what records should exist documenting where
   transferred funds went?

5. Are any of these funds, advisors, or the managing institution on **FINRA
   BrokerCheck** or SEC enforcement records for distribution-related violations?

---

## Notes on Data Provenance

All transaction and holdings data was extracted from quarterly PDF brokerage statements
using a custom OCR-to-JSON pipeline. Dollar amounts, dates, and security names are as
they appear on the statements. Minor OCR artifacts may exist in security names but all
material figures have been cross-checked against statement totals.
