library(PivotalR) # Load the PivotalR library
db.disconnect()

# Connect to a database
db.connect(host = "dca1-mdw1.dan.dh.greenplum.com", user = "gpadmin",
           password = "changeme", dbname = "pivotalr_demodb") 

dframe = db.data.frame("census1", conn.id=1)

# Look at 10 random rows
lookat(dframe, 10)

# Run the regression fit
start = Sys.time()
linregr_fit = madlib.lm(earns ~ hours + bachelor + married, 
                        data = dframe)
end = Sys.time()
census1_time = end - start
dim(dframe)
census1_time

# Look at the results
linregr_fit


# Prediction
lookat(cbind(dframe$hours, dframe$bachelor, dframe$married, dframe$earns, predict(linregr_fit, dframe)), 10)

# Root Mean Squared Error (RMSE)
lookat(sqrt(sum((dframe$earns - predict(linregr_fit, dframe))^2)))


###################################################
# Run the regression on the 1 billion row dataset #
###################################################

dframe_billion = db.data.frame("census1billion_rand", conn.id=1)

# Look at 10 random rows
lookat(dframe_billion, 10)

# Run the regression fit
start = Sys.time()
linregr_fit_billion = madlib.lm(earns ~ hours + bachelor + married, 
                        data = dframe_billion)
end = Sys.time()
census1billion_time = end - start
dim(dframe_billion)
census1billion_time

# Look at the results
linregr_fit_billion


# Prediction
lookat(cbind(dframe_billion$hours, dframe_billion$bachelor, dframe_billion$married, dframe_billion$earns,
             predict(linregr_fit_billion, dframe_billion)), 10)

# Root Mean Squared Error (RMSE)
lookat(sqrt(sum((dframe_billion$earns - predict(linregr_fit_billion, dframe_billion))^2)))





