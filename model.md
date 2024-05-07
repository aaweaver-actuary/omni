# OMNI stan model

## Introduction

**OMNI** is a Bayesian model written in stan for the analysis of property-casualty loss reserving triangles. The model models the development of paid and reported losses over time, and estimates the ultimate loss amount for each accident year.  

A Bayesian approach is appealing for the specific problem of loss reserving for several reasons:

1. The model can incorporate expert opinion in the form of prior distributions.
2. The model structure imposes constraints on the parameters that are consistent with the underlying business problem.
3. The model can be used to simultaneously estimate both the expected value and the uncertainty in the ultimate loss amounts, as well as monitor the development of the loss amounts as they are reported over time.
4. The model can be used to estimate the distribution of the ultimate loss amounts, which can be used to calculate risk measures such as Value-at-Risk and Tail Value-at-Risk.
5. The model relies on correlations between paid and reported loss development to improve the estimates of the ultimate loss amounts.

Since Small Business is fairly new, and does not have significant historical data, the model incorporates some of the structure inherent in loss reporting to improve the estimates of the ultimate losses without requiring a large amount of historical data.

Since ultimate losses will be the same regardless of whether paid or reported losses are considered, the model uses an ultimate loss ratio parameter that is parameterized by accident period. The model also includes a parameter for the development pattern of paid losses, and a parameter for the development pattern of reported losses. The ultimate loss ratio is the ratio of ultimate losses to an exposure base, usually some measure of premium. 

## Notation

* $w$ - accident period
* $d$ - development period
* $E_w$ - exposure base for accident period $w$
* $P_{wd}$ - incremental paid losses for accident period $w$ at development period $d$
* $R_{wd}$ - incremental reported losses for accident period $w$ at development period $d$
* $\hat{\alpha}_w$ - modeled ultimate loss ratio for accident period $w$
* $\hat{\beta}_d^P$ - modeled development pattern for paid losses
* $\hat{\beta}_d^R$ - modeled development pattern for reported losses

## Model

For each cell in the triangle, accident period $w$, development period $d$, the incremental paid losses $P_{wd}$ and incremental reported losses $R_{wd}$ are modeled as follows:

$$
\begin{align*}
E[P_{wd}] =& E_w \cdot \hat{\alpha}_w \cdot (\hat{\beta}_d^P - \hat{\beta}_{d-1}^P) \\
E[R_{wd}] =& E_w \cdot \hat{\alpha}_w \cdot (\hat{\beta}_d^R - \hat{\beta}_{d-1}^R)
\end{align*}
$$

Since $E_w$ is known, we will model the cumulative loss ratios as exponentially-modified normal random variables:

$$
\begin{align*}
\frac{P_{wd}}{E_w} \sim& \text{ } \text{EMN}(\mu_P, \sigma_P, \theta_P) \\
\frac{R_{wd}}{E_w} \sim& \text{ } \text{EMN}(\mu_R, \sigma_R, \theta_R)
\end{align*}
$$

where $\mu_C$ is the mean of the underlying Gaussian, $\sigma_C$ is the standard deviation of the underlying Gaussian, and $\theta_C$ is the mean of the exponential modifier. Then we have

$$
\begin{align*}
E\left[\frac{P_{wd}}{E_w}\right] =& \mu_P + \theta_P \\
\text{ } & \\
E\left[\frac{R_{wd}}{E_w}\right] =& \mu_R + \theta_R
\end{align*}
$$

and

$$
\begin{align*}
\text{Var}\left[\frac{P_{wd}}{E_w}\right] =& \sigma_P^2 + \theta_P^2 \\
\text{ } & \\
\text{Var}\left[\frac{R_{wd}}{E_w}\right] =& \sigma_R^2 + \theta_R^2
\end{align*}
$$

### Model Discussion

The exponentially-modified Gaussian distribution is chosen to serve as a distribution that meets the following criteria:

1. The distribution is continuous and skewed to the right.
2. The distribution can produce negative values.

This second criterion is important, and is why more traditional distributions such as gamma and lognormal are not used. Incremental losses can be negative for a variety of reasons, such as subrogation or salvage recoveries. The gamma and lognormal distributions are not able to produce negative values, and so are not appropriate for this model. 

## Priors

The model uses the following priors:

$$
\begin{align*}
\log \hat{\alpha}_w \sim& \text{ } \text{Normal}(0.5, 1) \\
\log \hat{\beta}_d^P \sim& \text{ } \text{Normal}(0, 1) \\
\log \hat{\beta}_d^R \sim& \text{ } \text{Normal}(0, 1) \\
\mu_P \sim& \text{ } \text{Normal}(0, 1) \\
\mu_R \sim& \text{ } \text{Normal}(0, 1) \\
\sigma_P \sim& \text{ } \text{Exponential}(1) \\
\sigma_R \sim& \text{ } \text{Exponential}(1) \\
\theta_P \sim& \text{ } \text{Exponential}(0.5) \\
\theta_R \sim& \text{ } \text{Exponential}(0.5)
\end{align*}
$$

## Application of Fitted Model
### Rating Practices

Once the Bayesian model is fitted and validated, it can be utilized to inform rating practices. The model's estimates of ultimate loss ratios and development patterns provide a refined view of the risk associated with different cohorts of policies.

1. **Incorporation into Pricing Models:** The ultimate loss ratios ($\hat{\alpha}_w$) estimated by the model can be directly used to adjust premium rates for new policies in similar cohorts or to reassess the sufficiency of rates for existing policies. This approach ensures that rates are aligned with the latest predictions of loss costs.
2. **Risk Differentiation:** By analyzing the differences in development patterns ($\hat{\beta}_d^P$ and $\hat{\beta}_d^R$) across different accident periods or policy segments, we can more accurately differentiate risk levels. This differentiation can lead to more segmented and competitive pricing strategies, reflecting the actual risk each segment presents.
3. **Dynamic Pricing:** The Bayesian framework allows for continuous updating of predictions as new data becomes available. This feature can be leveraged to implement dynamic pricing models that adjust more fluidly to emerging trends in loss data, thereby helping to stay competitive in a changing market

### Actual vs Expected Loss Emergence Studies

The fitted model also plays a crucial role in monitoring and analyzing the actual versus expected loss emergence, which is key to assessing long-term profitability as well as understanding model performance.

1. **Monitoring Loss Emergence:** By comparing the actual incremental losses ($P_{wd}$ and $R_{wd}$) to the expected losses predicted by the model, we can monitor the emergence of losses over time. Deviations from expected values can trigger deeper investigations and adjustments to assumptions or practices.
2. **Model Validation and Adjustment:** Regular actual vs. expected comparisons help validate the assumptions underlying the model. Significant and consistent deviations may indicate the need for model recalibration. This could involve adjusting priors based on new information or re-evaluating the distributional assumptions.
3. **Informing Reserve Adjustments:** Insights from actual vs. expected studies are crucial for delivering guidance on reserves or product management.
4. **Strategic Decision Making:** The results from these studies can inform strategic decisions at higher management levels, such as adjustments in underwriting criteria, changes in policy terms, or strategic shifts in target markets or product offerings.

## Development

### Proof of Concept

Before implementing the full model, we will first implement a proof of concept model that estimates the ultimate loss ratio for reported losses only. This model will serve as a starting point for the full model and will allow us to validate the implementation and assumptions.

### Full Model

The full model will incorporate both paid and reported losses, as well as the development patterns for each. The full model will be more complex and will require additional data processing and validation steps. However, the full model will provide a more comprehensive view of loss emergence and will allow for more detailed analysis and decision-making.