data {
  int<lower=0> W;  // number of accident periods
  int<lower=0> D;  // number of development periods
  vector<lower=0>[D] exposure[W];  // exposure base for each accident period and development period
  matrix<lower=0>[W, D] reported_losses;  // reported losses matrix
}

parameters {
  vector[W] log_alpha;  // log of ultimate loss ratios for each accident period
  vector[D] log_beta_R;  // log of development factors for reported losses
  real mu_R;  // mean of the Gaussian component for reported losses
  real<lower=0> sigma_R;  // standard deviation of the Gaussian component for reported losses
  real<lower=0> theta_R;  // mean of the exponential component for reported losses
}

transformed parameters {
  vector[W] alpha = exp(log_alpha);  // ultimate loss ratios
  vector[D] beta_R = exp(log_beta_R);  // development factors for reported losses
}

model {
  // Priors
  log_alpha ~ normal(0.5, 1);
  log_beta_R ~ normal(0, 1);
  mu_R ~ normal(0, 1);
  sigma_R ~ exponential(1);
  theta_R ~ exponential(0.5);

  // Model reported losses
  for (w in 1:W) {
    for (d in 1:D) {
      if (d > 1) {
        target += normal_lpdf(reported_losses[w, d] / exposure[w][d] | 
                              alpha[w] * (beta_R[d] - beta_R[d-1]) + mu_R, 
                              sqrt(pow(sigma_R, 2) + pow(theta_R, 2)));
      } else {
        target += normal_lpdf(reported_losses[w, d] / exposure[w][d] | 
                              alpha[w] * beta_R[d] + mu_R, 
                              sqrt(pow(sigma_R, 2) + pow(theta_R, 2)));
      }
    }
  }
}

generated quantities {
  vector[W] next_period_predicted_losses;
  for (w in 1:W) {
    if (D < size(beta_R)) {
      // Project the next development period if within the bounds
      next_period_predicted_losses[w] = exposure[w][D] * alpha[w] * (beta_R[D+1] - beta_R[D]) + mu_R;
    } else {
      // Assume last development factor difference repeats
      next_period_predicted_losses[w] = exposure[w][D] * alpha[w] * (beta_R[D] - beta_R[D-1]) + mu_R;
    }
    next_period_predicted_losses[w] = normal_rng(next_period_predicted_losses[w], sqrt(pow(sigma_R, 2) + pow(theta_R, 2)));
  }
}
