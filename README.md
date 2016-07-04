# Macroeconometirc-Models-and-Yield-Curve-Sensitivity
Miscellaneous practical macroeconometric models and tools in analysing yield curve.

- - -
### 1. Logics

#### 1.1 Exchange Rate
**Interest rate parity:**
under the assumption of **capital mobility** and **perfect substitutability** of demostic and foreign assets.
**uncovered:**
$$
C_t \times (1+i_{A}) = \frac {C_t \times E({ER}_{t+k})\times(1+i_B)}{{ER}_t},
$$
or
$$
(1+i_{A}) = \frac {E({ER}_{t+k})}{{ER}_t}\times(1+i_B)
$$
where $i_A$ and $i_B$ are risk free rates in country A and B, ${ER}_t$ is the exchange rate from currency $A$ to $B$ at time $t$, $E()$ is expectation.
**covered:**
$$
(1+i_{A}) = \frac {F_t}{{ER}_t}\times(1+i_B),
$$
$F_t$ is the forward exchange rate at time $t$.

An approximated version:
$$
i_A = i_B + \frac {\Delta E({ER}_{t+k})} {{ER}_t},
$$
where $\frac {\Delta E({ER}_{t+k})} {{ER}_t}$ is the expected rete of deprecation of currency $A$.

### 2. Macroecomic indicators nowcasting
Important macroecomic indicatorys like GDP and CPI are always released with a substantial delay. As a matter of fact, many indicators with much more higer frequency made it possible to get a early picture of the evolution fo current economic state. Here are several methods can bridge the gap bewteen timely updated indicators and the delayed natioanal accounts.

#### 2.1 Bridge Model


business and consumer surveys 

Since indicators cover a wide range of shortterm macroeconomic phenomena, they can be used in different bridge equations for the main GDP components (namely, private consumption, government purchases of goods and services, fixed investment, inventory investment, exports, and imports), or directly at aggregate GDP level. In the first case, the model is labelled ‘demand-side’ BM(where GDP is predicted by the NA income –expenditure identity), in the second case, it is labelled ‘supply-side’ BM (where GDP is forecast by a single bridge equation 2 ).


**uinit root test**
for a random walk process, at any forcast horizon h, we have:
$$ 
E(p_{h+t})=E(E(p_{h+t}|p_{h+t-1}))=E(p_{h+t-1})=...=E(p_{h+1})=p_{h},
$$
the expectaction of any future value is simply current value, it does not show any mean reverting property(non-stationary).
MA representation of a random walk:
$$
p_t=\alpha_t+\alpha_{t-1}+\alpha_{t-2}+...,
$$
the $l$ step forcast error is:
$$
e(l)= \alpha_{h+l}+\alpha_{h+l-1}+\alpha_{h+l-2}+...+\alpha_{h+1},
$$
and $Var(e(l))=l\sigma^2$ approaches infinity as $l$ increases. The acf will also show strong memory, the model is not predicable.

**accounting indentity:**
$$ total\ supply = total\ demand $$


**brige equition:**
Let $Y_\tau$ represent the varable of interest in quarter $\tau$, $I_\tau$ is the high frequency indicor vectors in quarter $\tau$. Then we have:
$$
Y_\tau = f(I_\tau,X_\tau)+\epsilon,
$$
$I_{\tau,t}$ is the t-th month's high frequency indicor vector of quarter $\tau$, missing $I_{\tau,t}$ in $I_\tau$ can be filled with ARIMA.

**reference:**
Parigi G, Schlitzer G. Quarterly forecasts of the italian business cycle by means of monthly economic indicators[J]. Journal of Forecasting, 1995, 14(2):117–141.


