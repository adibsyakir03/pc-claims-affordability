# Findings & actuarial commentary

## Finding 1 — the 1999–2000 loss ratio crisis

**What the data shows:**
Industry paid loss ratios peaked at 74.7% in 1999 and 81.2% in 2000,
compared to a baseline of 66.2% in 1998 and a recovered position
of 61.8% by 2004.

**What it means:**
The late 1990s US auto insurance market was significantly underpriced.
Insurers were collecting insufficient premium to cover the claims they
were writing. The 2000 peak means that for every $1 of premium collected,
81 cents went to paying claims alone — before expenses or profit.

**Actuarial implication:**
This is a textbook example of a pricing inadequacy cycle. Had an actuary
run a rate adequacy test on the 1998–1999 book, the indicated rate change
would have been significantly positive. The market correction from 2001
onwards — where rates were raised and loss ratios fell — confirms that
pricing discipline, not luck, drives long-term solvency.

## Finding 2 — top 10 insurers show wide performance spread

**What the data shows:**
Among the 10 largest insurers by net earned premium, paid loss ratios
range from 50.9% (Pioneer State Mut) to 75.8% (Usauto Ins Co) —
a 25 percentage point spread.

**What it means:**
The market is not uniform. Some insurers are pricing and underwriting
conservatively while others are taking on more risk. Usauto Ins Co
is the most exposed of the large players.

**Actuarial implication:**
A loss ratio of 75.8% before expenses leaves very little margin.
Adding a typical 28% expense ratio produces a combined ratio of
over 100% — meaning Usauto is likely loss-making on an underwriting
basis and relying on investment income to stay solvent.

## Finding 3 — 2002 and 2005 were industry-wide affordability failures

**What the data shows:**
In 2002 the industry average paid loss ratio hit 100.1% and in 2005 it
reached 102.3%. Individual insurers reached loss ratios as high as 2,264%
in 2002 and 3,300% in 2005.

**What it means:**
In these two years the average US private passenger auto insurer paid out
more in claims than it collected in premium — before accounting for any
operating expenses. This is a direct affordability failure. The extreme
maximum values indicate individual insurers in severe financial distress,
likely insolvent or in run-off.

**Actuarial implication:**
These years demonstrate why reserve adequacy and rate monitoring are not
optional. An actuary reviewing the 2001 or 2004 book should have flagged
the emerging deterioration before it became a crisis. Early warning through
loss ratio monitoring is one of the primary tools a P&C actuarial analyst
uses to protect company solvency.


## Finding 4 — 1 in 8 insurer-years show affordability failure

**What the data shows:**
Of 900 insurer-year observations at full development, 71 (7.9%) show
a paid loss ratio over 100% — meaning claims exceeded premium collected.
A further 69 (7.7%) sit in the 85–100% warning zone. Combined, 15.6%
of all observations show serious financial stress.

**What it means:**
Nearly 1 in 6 insurer-years in this dataset represents a company that
could not comfortably fund its claims from premium alone in that year.
The largest group — 35.6% — sits in the healthy 55–70% band, suggesting
the majority of the market is well-run, but a significant minority
is consistently under financial pressure.

**Actuarial implication:**
The 71 over-100% observations are the core subject of this project's
affordability analysis. These are the companies where premium intake
was genuinely insufficient to fund claim obligations — the exact
scenario that actuarial pricing and reserving work is designed to prevent.

## Finding 5 — individual insurers in extreme distress

**What the data shows:**
The 20 most distressed insurer-years show loss ratios ranging from
128.8% to 3,300%. The standout cases are:

- First American Specialty Ins Co (2005): loss ratio of 3,300% —
  paid $132 in claims for every $4 of premium collected
- First Amer Ins Co (2002): loss ratio of 2,264%
- Old American Cty Mut Fire Ins Co: appeared three consecutive years
  (2001, 2002, 2003) with loss ratios of 165%, 796% and 184%
- Dorinco Rein Co (1999): the largest insurer by premium volume in
  the entire dataset, yet recorded the biggest absolute deficit —
  $22.4 million more paid out in claims than collected in premium

**What it means:**
Dorinco Rein Co is the most striking case. It was simultaneously the
largest insurer by premium volume in the dataset and the company with
the biggest absolute claims deficit in 1999. Size did not protect it.
Old American Cty Mut Fire Ins Co failing for three consecutive years
points to a structural pricing problem — not bad luck, but a
fundamentally broken underwriting model that went uncorrected.

**Actuarial implication:**
These cases represent exactly the scenario reserving actuaries are
employed to prevent. An appointed actuary reviewing Dorinco or Old
American's books would have been required under NAIC standards to flag
reserve inadequacy and recommend immediate remedial action. Three
consecutive years of crisis at Old American suggests either the actuarial
warnings were ignored, or no proper rate adequacy review was being
performed at all.

## Finding 6 — loss development curve confirms classic auto pattern

**What the data shows:**
At development lag 1, only 38% of ultimate claims costs have been paid.
By lag 2 this rises to 70.4% — a 32 percentage point jump as
straightforward claims settle. The curve then flattens, reaching 99.4%
by lag 10. Average IBNR reserves shrink from 1,775 at lag 1 to just
5 at lag 10 as uncertainty resolves.

**What it means:**
The bulk of private passenger auto claims settle within the first two
years. The remaining 30% take up to 10 years to fully resolve —
these are complex bodily injury cases, disputed liability claims, and
litigation. This long tail is why insurers must hold IBNR reserves
for years after the accident year ends.

**Actuarial implication:**
This development pattern is the foundation of the chain-ladder method
used in Phase 3 of this project. By observing how past accident years
developed from lag 1 through lag 10, we can project how immature
accident years will develop — and therefore how much reserve the
insurer needs to hold today to pay tomorrow's claims.

## Finding 7 — chain-ladder link ratios show rapid early development

**What the data shows:**
Volume-weighted link ratios from the paid loss development triangle:
- Lag 1 to 2: 1.8246 — claims nearly double in the second year
- Lag 2 to 3: 1.1823 — further 18% growth
- Lag 3 onwards: ratios fall rapidly toward 1.000
- By lag 6 the ratio is 1.0073 — less than 1% growth per year

**What it means:**
The lag 1 to 2 ratio of 1.8246 is the most critical number in the
reserving analysis. It means an insurer looking at their year-end
lag 1 paid losses is only seeing 55 cents of every ultimate claims
dollar. They must hold reserves for the remaining 45 cents — plus
all future development beyond lag 2.

**Actuarial implication:**
These link ratios are the direct input to the chain-ladder IBNR
calculation performed in Phase 3 of this project using R. Multiplied
together they produce the Cumulative Development Factor — the number
by which current paid losses are multiplied to project ultimate cost.
A lag 1 CDF of approximately 2.6 means current paid losses represent
only about 38% of ultimate — consistent with the 38% figure observed
in the C1 development curve query.

## Finding 8 — 71 confirmed affordability failures across 10 years

**What the data shows:**
71 insurer-year combinations show paid losses exceeding net earned
premium — a direct affordability failure. Key findings:

- New Jersey Citizens United was in deficit for 7 consecutive years
  (2001–2007) — the longest sustained failure in the dataset
- Pacific Ind Ins Co was in deficit for 6 years (1998–2003)
- Interboro Mut Ind Ins Co and IFA Ins Co each failed for 4 years
- Old American Cty Mut Fire Ins Co failed for 5 consecutive years
- Dorinco Rein Co accumulated a $41 million absolute deficit across
  1999 and 2000 alone
- Deficit insurers peaked at 14 in year 2000 and 13 in 2002 —
  directly corresponding to the industry crisis years identified
  in Finding 3

**What it means:**
The repeat offenders are the most alarming finding. A single bad year
can be explained by an unexpected spike in claims. But 4, 5, 6 or 7
consecutive years of paying out more than you collect is a fundamental
business model failure. These companies were structurally underpricing
their policies year after year.

**Actuarial implication:**
New Jersey Citizens United in deficit for 7 straight years is the
clearest example of what happens when rate adequacy monitoring fails.
An annual actuarial review would have flagged the inadequacy after
year 1. The fact that it continued for 7 years suggests either the
actuarial advice was ignored, or the reviews were not being performed
to the required standard. This is the core business case for rigorous
P&C actuarial analysis.

## Finding 9 — IBNR uncertainty peaked in 2003 following the crisis years

**What the data shows:**
At lag 1, IBNR reserves as a percentage of total incurred losses
ranged from 22.0% (2000) to 30.1% (2003). The 2003 peak represents
the highest reserve uncertainty in the entire dataset. Total IBNR
held across the industry rose from $129 million in 1998 to $187
million in 2003 before gradually declining.

**What it means:**
The 2003 IBNR peak is a direct consequence of the 2002 crisis year.
After experiencing severe adverse loss development, insurers
strengthened their reserves — holding more IBNR as a buffer against
further deterioration. This is standard actuarial practice following
a period of adverse experience.

**Actuarial implication:**
Rising IBNR percentages are an early warning signal. The climb from
23.4% in 1998 to 25.0% in 2001 and 2002 — before the 2003 peak —
shows the stress building in the system before it became fully visible
in paid loss ratios. A reserving actuary monitoring IBNR trends would
have seen this warning signal emerging from 2001 onwards.