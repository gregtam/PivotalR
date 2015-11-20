# This script will take a schema as an input. It will then create a new schema with the format
# oldschemaname_summary. Next, it will take all the tables in the schema and create summaries 
# of them inside the oldschemaname_summary schema. 

library(RPostgreSQL)

# Connects to the database
drv = dbDriver("PostgreSQL")
con = dbConnect(drv, host = "10.68.128.150", user = "gtam",
                password = "gtam1!", dbname = "gtam")

# Specify the schema whose tables we want to summarize
schema_name = "test_schema"


# This query will create a new schema with the name oldschemaname_summary
# Then, it will create a table with all the names in schema_name. 
# This is used to loop over all the tables in a given schema.
querystring = paste(sep="",
                    "DROP SCHEMA IF EXISTS ", schema_name, "_summary CASCADE;",
                    "CREATE SCHEMA ", schema_name, "_summary \n",
                    "AUTHORIZATION gpadmin;",
                    "GRANT ALL ON SCHEMA ", schema_name, "_summary TO gpadmin;",
                    "GRANT ALL ON SCHEMA ", schema_name, "_summary TO public;",
                    "DROP TABLE IF EXISTS ", schema_name, "_summary.table_names_test;",
                    "CREATE TABLE  ", schema_name, "_summary.table_names_test 
                        AS SELECT table_name
                             FROM information_schema.tables
                            WHERE table_schema='", schema_name, "';
                     SELECT * FROM public_summary.table_names_test;")



# Execute query and put results into 'table_names'
table_names = dbGetQuery(con, querystring)
table_names

# This loops over all the tables in a given schema and 
# create a summary table of the form oldtablename_summary. 
# It is placed into the oldschename_summary schema.
for(name in table_names[,1])
{
  querystring = paste(sep="",
                      "DROP TABLE IF EXISTS public_summary.", name, "_summary; ",
                      "SELECT * FROM madlib.summary('", name, "', 'public_summary.", name, "_summary');")
  dbGetQuery(con, querystring)
}

# We can then retrieve the summary tables in R, then export them to csv files. 
summary_tables = list()
for(name in table_names[,1])
{
  querystring = paste(sep="",
                      "SELECT * FROM public_summary.", name, "_summary;")
  summary_tables[[paste(sep="", name, "_summary")]] = dbGetQuery(con, querystring)
}
names(summary_tables)

summary_tables$patients_summary
summary_tables$houses_summary

# Export each summary table into a separate csv file
for(i in 1:length(summary_tables))
  write.csv(summary_tables[i], paste(sep="", names(summary_tables)[i], ".csv"))




