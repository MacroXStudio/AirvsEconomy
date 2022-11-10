# https://cran.r-project.org/web/packages/softImpute/vignettes/softImpute.html
library(softImpute)

df_training <- read.csv('training.csv', header = TRUE, sep = ',')
df_validate <- read.csv('validation.csv',  header = TRUE, sep = ',')
df_generate <- read.csv('generate_api_data.csv', header = TRUE, sep = ',')

# create matrix of numrical dataframe values
A_training <- as.matrix(df_training[,-1])
A_validate <- as.matrix(df_validate[,-1])
A_generate <- as.matrix(df_generate[,-1])

# set random number seed for reproducibility
set.seed(37)

# create random column index to randomize the column placement
rand_column_index <- sample.int(263)

A_training_rand <- A_training[, rand_column_index]
A_validate_rand <- A_validate[, rand_column_index]
A_generate_rand <- A_generate[, rand_column_index]

# scale the data with std deviation and mean
A_t <- scale.default(A_training_rand)
A_t_centers <- attr(x=A_t, which = "scaled:center")
A_t_scales  <- attr(x=A_t, which = "scaled:scale")

A_v <- scale.default(A_validate_rand)
A_v_centers <- attr(x=A_v, which = "scaled:center")
A_v_scales  <- attr(x=A_v, which = "scaled:scale")

A_g <- scale.default(A_generate_rand)
A_g_centers <- attr(x=A_g, which = "scaled:center")
A_g_scales  <- attr(x=A_g, which = "scaled:scale")


# randomly replace entries from the matrix with NA and then calculate
# MSE of known, but removed, entries to tune softImpute hyperparameters
# look at 269 points--create random indices
col_sample_t <- sample.int(263, size=263)
row_sample_t <- sample.int(dim(A_t)[1], size=263)
# record tha actual values of these entries that will be replaced with NA
# so that MSE or relative RMSE can be used to evaluate imputation
missing_A_t = rep(0, 263)
for(i in 1:263){
  missing_A_t[i] <- A_t[row_sample_t[i], col_sample_t[i] ]
}
# create a new matrix with all these 269 entries replaced with NA
# note: remove NA's before MSE calculation using mask !is.na 
# copy matrix
A_t_miss_entries <- A_t
# assign the random entries a value of NA
for(i in 1:263){
  A_t_miss_entries[row_sample_t[i], col_sample_t[i]] <- NA
}
# optimize the values of lambda and rank.max
# from https://cran.r-project.org/web/packages/softImpute/vignettes/softImpute.html
#  "Lets use some regularization now, choosing a value for lambda that will give
# a rank 2 solution (this required trial and error to get it right)."
mse_t <- rep(0,49)
frob_norm_t <- rep(0,49)
i <- 1
for(max_rank in 2:50){
  fits_t_rank <- softImpute(A_t_miss_entries, rank.max=max_rank, lambda=(max_rank-1.1),
                            trace=TRUE, type="svd")
  fits_complete <- complete(A_t_miss_entries, fits_t_rank)
  # extract removed initially removed entries for comparison to original entries
  missing_A_t_test = rep(0, 263)
  for(j in 1:263){
    missing_A_t_test[j] <- fits_complete[row_sample_t[j], col_sample_t[j] ]
  }
  # calculate MSE
  non_na <- length(missing_A_t[!is.na(missing_A_t)])
  mse_t[i] <- sum((missing_A_t[!is.na(missing_A_t)] - missing_A_t_test[!is.na(missing_A_t)])^2)/non_na
  # calculate the frobenius norm for the difference between matrices
  # assign the NA's from the original matrix to zero
  A_t_zero_for_na <- A_t
  A_t_zero_for_na[is.na(A_t_zero_for_na)] = 0
  A_t_complete_zero_for_na <- fits_complete
  A_t_complete_zero_for_na[is.na(A_t_zero_for_na)] = 0
  frob_norm_t[i] <- norm((A_t_zero_for_na - A_t_complete_zero_for_na), type ='F')
  
  i <- i + 1
}
# Plot MSE ve rank.max parameter for softImpute function
plot(2:50, mse_t, xlab = 'Maximum Rank', ylab = 'MSE')
# plot frobenius norm of the differnce betwwen non-NA values of the imputed matrix
# and the original matrix
plot(2:50, frob_norm_t, xlab = 'Maximum Rank', ylab = 'Frobenius Norm')
# note: to return matrix back to original numbers
# note: t(apply(mmm_s,1,function(r) r * attr(mmm_s, which = "scaled:scale") + 
#                                       attr(mmm_s, which = "scaled:center")))

# softImpute for imputation of missing values by matrix completion
# using the optimal hyperparameters
fits_t <- softImpute(A_t, rank.max=16, lambda=14.9, trace=TRUE, type="svd")
fits_v <- softImpute(A_v, rank.max=16, lambda=14.9, trace=TRUE, type="svd")
fits_g <- softImpute(A_g, rank.max=16, lambda=14.9, trace=TRUE, type="svd")

# create the complete matrix
fits_tc <- complete(A_t, fits_t)
fits_vc <- complete(A_v, fits_v)
fits_gc <- complete(A_g, fits_g)

# reverse the scaling of the matrices
A_t_complete <- t(apply(fits_tc, 1, function(r) r * A_t_scales + A_t_centers))
A_v_complete <- t(apply(fits_vc, 1, function(r) r * A_v_scales + A_v_centers))
A_g_complete <- t(apply(fits_gc, 1, function(r) r * A_g_scales + A_g_centers))

# derandomize the columns and put them back into the order that they had
# within the originally imported csv's
A_t_complete <- A_t_complete[, unlist(attr(x=A_training, which = "dimnames"))]
A_v_complete <- A_v_complete[, unlist(attr(x=A_training, which = "dimnames"))]
A_g_complete <- A_g_complete[, unlist(attr(x=A_training, which = "dimnames"))]

# output the complete (no NA's, missing values) as csv's
write.csv(A_t_complete, file='training_no_na.csv', row.names=df_training$date)
write.csv(A_v_complete, file='validation_no_na.csv', row.names=df_validate$date)
write.csv(A_g_complete, file='generate_api_data_no_na.csv', row.names=df_generate$date)
