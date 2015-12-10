# Visualization is a key part of analyzing data. It allows us to summarize
# large amounts of data. This script is intended to take a large univariate
# vector of values and create values for a histogram, that is, create
# buckets and determine how many values go into each bucket based off the
# data. I do not believe there is a native histogram function for PostgreSQL,
# so this function is to create the necessary data. Then, we can use ggplot
# to plot the histogram. 

library(RPostgreSQL)
library(ggplot2)

# Connect to the Greenplum database
drv = dbDriver("PostgreSQL")
con = dbConnect(drv,
                host = "dca1-mdw1.dan.dh.greenplum.com",
                user = "gpadmin",
                password = "changeme",
                dbname = "dstraining")

# Specify query
querystring = 'SELECT * FROM madlibtestdata.dt_abalone;'

# Execute query and put results into 'abalone'
abalone = dbGetQuery(con, querystring)
abalone

table(head(abalone, 4000)$rings)

# Specify the number of bins we wish to have
nbins = 10

# Get the min and max of rings to specify the bin edges
querystring = 
  "SELECT min(rings), max(rings)
     FROM madlibtestdata.dt_abalone;"
rings_range = dbGetQuery(con, querystring)

# This gives the edges of all of the buckets as a vector
# (Adding 1 ensures we have nbins+1 edges, so we have enough bins)
bucket_indices = seq(rings_range$min, rings_range$max, length.out = nbins+1)


# This is where the magic of R comes in. Instead of having
# to type a long complicated case query with 10 different
# conditions, we can, instead, do this using a for loop in 
# R. By writing this complicated query as a string, we can 
# then use dbGetQuery to submit the query and obtain the 
# results. Similar techniques can be done in Python.

querystring = 
  "DROP TABLE IF EXISTS rings_hist;
   SELECT * 
     INTO rings_hist
     FROM (SELECT rings, CASE"
for(i in 1:(length(bucket_indices)-2))
  querystring = paste(querystring, "WHEN rings >=", bucket_indices[i], "AND rings <", bucket_indices[i+1], "THEN", i, "\n")
i = i + 1

# For the last one, we need a less than or equals
querystring = paste(querystring, "WHEN rings >=", bucket_indices[i], "AND rings <=", bucket_indices[i+1], "THEN", i, "\n")

querystring = paste(querystring,
                    "END AS buckets FROM madlibtestdata.dt_abalone) foo;
                     SELECT buckets, COUNT(buckets)
                       FROM rings_hist
                      GROUP BY buckets
                      ORDER BY buckets;")

hist_vals = dbGetQuery(con, querystring)

ggplot(hist_vals) + 
  geom_bar(aes(bucket_indices[buckets], count), stat="identity") + 
  xlab("Rings") + 
  ylab("Count") + 
  ggtitle("Custom Histogram for Abalone Rings")



################################################################
# Let's illustrate this using the much larger census data set. #
################################################################

# Connect to the Greenplum database
drv = dbDriver("PostgreSQL")
con = dbConnect(drv,
                host = "dca1-mdw1.dan.dh.greenplum.com",
                user = "gpadmin",
                password = "changeme",
                dbname = "pivotalr_demodb")

# Specify the number of bins we wish to have
nbins = 20

# Get the min and max of rings to specify the bin edges
querystring = 
  "SELECT min(earns), max(earns)
     FROM census1billion_rand;"
earns_range = dbGetQuery(con, querystring)

# This gives the edges of all of the buckets as a vector
# (Adding 1 ensures we have nbins+1 edges, so we have enough bins)
bucket_indices = seq(earns_range$min, earns_range$max, length.out = nbins+1)


# This is where the magic of R comes in. Instead of having
# to type a long complicated case query with 10 different
# conditions, we can, instead, do this using a for loop in 
# R. By writing this complicated query as a string, we can 
# then use dbGetQuery to submit the query and obtain the 
# results. Similar techniques can be done in Python.

querystring = 
  "DROP TABLE IF EXISTS earns_hist;
   SELECT * 
     INTO earns_hist
     FROM (SELECT earns, CASE"
for(i in 1:(length(bucket_indices)-2))
  querystring = paste(querystring, "WHEN earns >=", bucket_indices[i], "AND earns <", bucket_indices[i+1], "THEN", i, "\n")
i = i + 1

# For the last one, we need a less than or equals
querystring = paste(querystring, "WHEN earns >=", bucket_indices[i], "AND earns <=", bucket_indices[i+1], "THEN", i, "\n")

querystring = paste(querystring,
                    "END AS buckets FROM census1billion_rand) foo;
                     SELECT buckets, COUNT(buckets)
                       FROM earns_hist
                      GROUP BY buckets
                      ORDER BY buckets;")

hist_vals = dbGetQuery(con, querystring)

ggplot(hist_vals) + 
  geom_bar(aes(bucket_indices[buckets], count), stat="identity") + 
  xlab("Earns") + 
  ylab("Count") + 
  ggtitle("Custom Histogram for Earns")







