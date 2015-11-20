# https://github.com/pivotalsoftware/PivotalR/wiki/Example

# PivotalR is an R library that takes advantage of the benefits of 
# MADlib, while providing a familiar R interface. This is done in 
# three steps:

# 1. Translates R model formulas into corresponding SQL statements
# 2. Executes these statements on the database
# 3. Returns summarized model output to R

library(PivotalR)
db.disconnect()

# Connect to a database
db.connect(host = "dca1-mdw1.dan.dh.greenplum.com", user = "gpadmin",
           password = "changeme", dbname = "dstraining") 

dframe = db.data.frame("madlibtestdata.dt_abalone", conn.id=1)

lookat(dframe, 10) #look at 10 rows

dim(dframe) #dimensions of the dataframe

names(dframe) #names of the columns

dframe$length #Note that this does not give the actual value. We must do lookat(dframe$length)
lookat(dframe$length)

madlib.summary(dframe)


###################################################


# Let's start off by doing a simple linear regression

start = Sys.time()
linreg.fit = madlib.lm(rings ~ . -id | sex, data = dframe)
end = Sys.time()
linreg.time = end-start #Time it took to run
linreg.time

linreg.fit
length(linreg.fit) #Note there are 3 separate fits (for sex = F, I, and M)
linreg.fit[[1]] #To index just the first fit (sex = M)

# Let's look at the mean squared error (MSE), 
# which gives us an idea of how good the fit was
lookat(mean((predict(linreg.fit, dframe) - dframe$rings)^2))


ap = cbind(dframe$rings, predict(linreg.fit, dframe)) # combine two columns
plot(lookat(sort(ap, FALSE, NULL), 100)) # plot a random sample


###############################################


# Runs the fit without considering sex
start = Sys.time()
linreg.fit2 = madlib.lm(rings ~ . -id-sex, data=dframe)
end = Sys.time()
linreg.time2 = end-start #Time it took to run
linreg.time2

linreg.fit2

# MSE
lookat(mean((dframe$rings - predict(linreg.fit2, dframe))^2))


###########################################

# Here we do a logistic regression for rings<10, that is,
# we are trying to predict whether rings < 10 or rings >=10
start = Sys.time()
log.fit = madlib.glm(rings<10 ~ . -id -sex, data=dframe, family="binomial")
end = Sys.time()
log.time = end-start #Time it took to run
log.time

# Accuracy
lookat(mean((dframe$rings<10) == predict(log.fit, dframe)))


###########################################


# Elastic net:
# Can choose lasso penalty if alpha = 1 (default value)
# or ridge penalty if alpha = 0.
# Anything in between is elastic net regularization

start = Sys.time()
elnet.fit = madlib.elnet(rings<10 ~ . -id -sex, data=dframe, family="binomial", alpha=1, lambda=0.01)
end = Sys.time()
elnet.time = end-start #Time it took to run
elnet.time


# Accuracy
lookat(mean((dframe$rings<10) == predict(elnet.fit, dframe)))



###########################################


# Does bagging (i.e. runs the model on resampled copies of the dataset)
# Doing this reduces variance and avoids overfitting
start = Sys.time()
bag.fit = generic.bagging(function(data) madlib.lm(rings ~ . -id-sex, data=data), 
                          data=dframe, nbags=5, fraction=1)
end = Sys.time()
bag.time = end-start #Time it took to run
bag.time

# Indexing each fit
bag.fit[[1]]
bag.fit[[2]]
bag.fit[[5]]

# MSE
lookat(mean((dframe$rings - predict(bag.fit, dframe))^2))

# Note that this takes quite a bit longer than doing one single fit. One reason
# is because each of the bags is done sequentially since it's being done in R. 
# In fact, it actually takes longer than just running them all in sequence since
# creating the resampled bags takes time too. Let's look into the generic.bagging
# function and edit it to look at how long each step takes

generic.bagging

generic.bagging.timed = function (train, data, nbags = 10, fraction = 1) 
{
  warnings <- PivotalR:::.suppress.warnings(conn.id(data))
  if (fraction > 1) 
    stop("fraction cannot be larger than 1!")
  if (!is(data, "db.obj")) 
    stop("data must be a db.obj!")
  n <- dim(data)[1]
  size <- as.integer(n * fraction)
  res <- list()
  time_matrix = matrix(, nrow = 2, ncol = nbags)
  rownames(time_matrix) = c("bag_creation_time", "fit_time")
  for (i in 1:nbags)
  {
    time1 = Sys.time()
    data.use <- sample(data, size, replace = TRUE)
    time2 = Sys.time()
    res[[i]] <- train(data.use)
    time3 = Sys.time()
    time_matrix[,i] = c(as.numeric(time3 - time2, units="secs"),
                        as.numeric(time2 - time1, units="secs"))
    delete(data.use)
  }
  class(res) <- "bagging.model"
  PivotalR:::.restore.warnings(warnings)
  list(res, time_matrix)
}

start = Sys.time()
bag.fit.timed = generic.bagging.timed(function(data) madlib.lm(rings ~ . -id-sex, data=data), 
                          data=dframe, nbags=5, fraction=1)
end = Sys.time()
bag.fit.timed
bag.timed.time = end - start
bag.timed.time

# Let's look at the amount of time in seconds it took
# to create each bag and run its regression:
bag.fit.timed[[2]]
# Number of minutes in total
sum(bag.fit.timed[[2]])/60







