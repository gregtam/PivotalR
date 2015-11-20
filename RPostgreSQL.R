# Source: http://pivotalsoftware.github.io/gp-r/#bestpractices

# The RPostgreSQL package provides a database interface and PostgreSQL driver 
# for R that is compatible with the Greenplum database. This connection can be 
# used to query the database in the normal fashion from within R code.

# Using RPostgreSQL with a database includes the following 3 steps:
# 1. Create a database driver for PostgreSQL,
# 2. Connect to a specific database, and
# 3. Execute the query on GPDB and return results


library(RPostgreSQL)

# Connect to the Greenplum database
drv = dbDriver("PostgreSQL")
con = dbConnect(drv, host = "dca1-mdw1.dan.dh.greenplum.com", user = "gpadmin",
                password = "changeme", dbname = "dstraining")

# Specify query
querystring = 'SELECT * FROM madlibtestdata.dt_abalone;'
# Execute query and put results into 'abalone'
abalone = dbGetQuery(con, querystring)
abalone

plot(abalone$length, abalone$rings)


# What's interesting about this is we can even use
# RPostgreSQL to write a PL/Python query, that is, 
# use R to access SQL to access Python.

# This is not entirely efficient as data will need
# to move around quite a bit, which can take a lot
# of time when there is a large amount of data.

querystring = 
"DROP FUNCTION IF EXISTS coordPy(x double precision, y integer);

CREATE OR REPLACE FUNCTION coordPy(x double precision, y integer)
                   RETURNS text as
                           $$
                             return '(' + str(x) + ', ' + str(y) + ')'
                           $$
                  LANGUAGE 'plpythonu' IMMUTABLE;

SELECT coordPy(length, rings), length, rings
  FROM madlibtestdata.dt_abalone;"

coordPyResults = dbGetQuery(con, querystring)
coordPyResults



# The main purpose of RPostGreSQL and PivotalR is to get the data 
# into R, not for the purposes of modelling (as MADlib can already
# do that), but for visualization. Obviously there is no way of
# doing any visualization within a database, so we must move it
# to R.

# ggplot2 is a very good library for doing any kind of visualization
# in R.

library(ggplot2)

# Here is a very basic plot of length vs rings
ggplot(data = abalone) +
  geom_point(aes(abalone$length, abalone$rings)) +
  ggtitle("length vs rings") + 
  xlab("length") + 
  ylab("rings")

# We can add some complexity to it by adding sex
# as a variable, where different sex is represented
# by a different colour.
cols = c("#000099", "#FFFFFF", "#663300")

ggplot(data = abalone) +
  geom_point(aes(length, rings, colour=sex)) +
  scale_color_manual(values=cols) +
  scale_size_discrete(range=c(2,4)) + 
  ggtitle("length vs rings") + 
  xlab("length") + 
  ylab("rings")


###############################################

querystring = "SELECT * FROM abalone_array;"

querystring = "SELECT * FROM madlibtestdata.dt_abalone;"

querystring =
"DROP TABLE IF EXISTS abalone_array;

  CREATE TABLE abalone_array 
      AS SELECT sex,
                array_agg(shucked) AS s_weight,
                array_agg(rings) AS rings,
                array_agg(diameter) AS diameter 
           FROM madlibtestdata.dt_abalone_test 
       GROUP BY sex
 DISTRIBUTED BY (sex);

SELECT * FROM abalone_array;"

test = dbGetQuery(con, querystring)
test




















