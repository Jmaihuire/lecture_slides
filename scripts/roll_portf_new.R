# Functions for simulating rolling portfolio optimization strategies

# library(HighFreq)  # load package HighFreq

# Simulate a rolling portfolio optimization strategy
# using the regularized inverse of the covariance matrix.

roll_portf_r <- function(ex_cess, # portfolio excess returns
                         re_turns, # portfolio returns
                         start_points, 
                         end_points, 
                         al_pha, 
                         max_eigen, 
                         end_stub=30) {

  strat_rets <- lapply(2:NROW(end_points), function(i) {
    # subset the ex_cess returns
    ex_cess <- ex_cess[start_points[i-1]:end_points[i-1], ]
    cov_mat <- cov(ex_cess)
    # perform eigen decomposition and calculate eigenvectors and eigenvalues
    ei_gen <- eigen(cov_mat)
    eigen_vec <- ei_gen$vectors
    # calculate regularized inverse
    in_verse <- eigen_vec[, 1:max_eigen] %*% (t(eigen_vec[, 1:max_eigen]) / ei_gen$values[1:max_eigen])
    # weight_s are proportional to the mean of ex_cess
    excess_mean <- colMeans(ex_cess[-((NROW(ex_cess)-end_stub+1):NROW(ex_cess)), ])
    # excess_mean <- colMeans(ex_cess[-((NROW(ex_cess)-end_stub+1):NROW(ex_cess)), ]) - colMeans(ex_cess[((NROW(ex_cess)-end_stub+1):NROW(ex_cess)), ])
    # shrink excess_mean vector to the mean of excess_mean
    excess_mean <- ((1-al_pha)*excess_mean + al_pha*mean(excess_mean))
    # apply regularized inverse to mean of ex_cess
    weight_s <- drop(in_verse %*% excess_mean)
    weight_s <- weight_s/sqrt(sum(weight_s^2))
    # subset the re_turns to out-of-sample returns
    re_turns <- re_turns[(end_points[i-1]+1):end_points[i], ]
    # calculate the out-of-sample portfolio returns
    xts(re_turns %*% weight_s, index(re_turns))
  }  # end anonymous function
  )  # end lapply
  
  # Flatten the list of xts into a single xts series
  strat_rets <- rutils::do_call(rbind, strat_rets)
  colnames(strat_rets) <- "strat_rets"
  # Add warmup period so that index(strat_rets) equals index(re_turns)
  in_dex <- index(re_turns)[index(re_turns) < start(strat_rets)]
  strat_rets <- rbind(xts(numeric(NROW(in_dex)), in_dex), strat_rets)
  # Cumulate strat_rets
  cumsum(strat_rets)
}  # end roll_portf_r

