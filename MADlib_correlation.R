# Sample code to get correlations of multiple columns in a table

library(PivotalR)
db.disconnect()

# Connect to a database
db.connect(host = "dca1-mdw1.dan.dh.greenplum.com", user = "gpadmin",
           password = "changeme", dbname = "dstraining")


library(RPostgreSQL)

# Connect to the Greenplum database
drv = dbDriver("PostgreSQL")
con = dbConnect(drv, host = "dca1-mdw1.dan.dh.greenplum.com", user = "gpadmin",
                password = "changeme", dbname = "dstraining")

dframe = db.data.frame("madlibtestdata.dt_abalone", conn.id=1)

names(dframe)

# Variables we wish to include in the correlation matrix
variable_names = c('length', 'diameter', 'height', 'whole', 'shucked', 'viscera', 'shell', 'rings')

# Specify query
querystring = 
  paste("SELECT madlib.correlation('madlibtestdata.dt_abalone',
                             'abalone_correlation',
                             '", paste(variable_names, collapse=", "), "');
         SELECT * 
           FROM abalone_correlation
          ORDER BY column_position;")
# Execute query and put results into 'abalone'
abalone_correlation = dbGetQuery(con, querystring)

abalone_correlation




