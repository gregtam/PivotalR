# The variance inflation factor is a good measure to detect
# whether there is multicollinearity in the covariates. It 
# is defined for a covariate as 1/(1-R^2) where the R^2 
# is the R^2 that appears when a linear regression is done
# on the specified covariate against all other covariates

# For example, if we have covariates x, y, z, then the 
# VIF for x is the R^2 value when we run lm(x ~ y + z)


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

########
# VIFs #
########

vifs = matrix(, nrow=7, ncol=1)
colnames(vifs) = c("VIF")
rownames(vifs) = names(dframe[3:9])

length_fit = madlib.lm(length ~ . -rings-id-sex, data=dframe)
length_fit
vifs["length",] = 1/(1-length_fit$r2)

diameter_fit = madlib.lm(diameter ~ . -rings-id-sex, data=dframe)
diameter_fit
vifs["diameter",] = 1/(1-diameter_fit$r2)

height_fit = madlib.lm(height ~ . -rings-id-sex, data=dframe)
height_fit
vifs["height",] = 1/(1-height_fit$r2)

whole_fit = madlib.lm(whole ~ . -rings-id-sex, data=dframe)
whole_fit
vifs["whole",] = 1/(1-whole_fit$r2)

shucked_fit = madlib.lm(shucked ~ . -rings-id-sex, data=dframe)
shucked_fit
vifs["shucked",] = 1/(1-shucked_fit$r2)

viscera_fit = madlib.lm(viscera ~ . -rings-id-sex, data=dframe)
viscera_fit
vifs["viscera",] = 1/(1-viscera_fit$r2)

shell_fit = madlib.lm(shell ~ . -rings-id-sex, data=dframe)
shell_fit
vifs["shell",] = 1/(1-shell_fit$r2)

vifs


# If we have 200 variables, it would clearly be very time
# consuming to have to type each regression out. It's 
# much more advantageous to write this out in a loop or
# vectorize it.


vifs = matrix(, nrow=7, ncol=1)
colnames(vifs) = c("VIF")
rownames(vifs) = names(dframe[3:9])
vifs

vif_filler = function(i)
{
  form = as.formula(paste(rownames(vifs)[i], " ~ . -rings-id-sex", sep=""))
  temp_fit = madlib.lm(form, data=dframe)
  1/(1-temp_fit$r2)
}

vifs[,1] = sapply(1:7, vif_filler)
vifs







