library(dplyr)
library(magrittr)
library(PivotalR)
library(ggplot2)

db.disconnect()
db.connect(dbname="pivotalr_demodb", user="gpadmin", password="changeme", host="dca1-mdw1.dan.dh.greenplum.com")

db.list()
db.objects()


d1 = db.data.frame("census1billion_rand", conn.id=1)
dim(d1)
names(d1)

smalldf = lookat(cbind(d1$earns, d1$rooms, d1$bedrms, d1$female), 100000)
smalldf = mutate(smalldf, sex = ifelse(female==1, "F", "M"))

ggplot(smalldf, aes(as.factor(rooms), y=earns)) + 
  geom_boxplot() + 
  ggtitle("# Rooms vs. Earnings") + 
  xlab("# Rooms")

ggplot(smalldf, aes(as.factor(rooms), y=earns)) + 
  geom_violin() + 
  ggtitle("# Rooms vs. Earnings") + 
  xlab("# Rooms")


ggplot(smalldf, aes(as.factor(bedrms), earns)) + 
  geom_boxplot() + 
  ggtitle("# Bedrooms vs. Earnings") + 
  xlab("# Bedrooms")

ggplot(smalldf, aes(as.factor(bedrms), earns)) + 
  geom_violin() + 
  ggtitle("# Bedrooms vs. Earnings") + 
  xlab("# Bedrooms")


ggplot(smalldf, aes(sex, earns)) + 
  geom_boxplot() + 
  ggtitle("Female/Male vs. Earnings")

ggplot(smalldf, aes(sex, earns)) + 
  geom_violin() + 
  ggtitle("Female/Male vs. Earnings")


########################
# Other plots: Heatmap #
########################
# Reference: https://learnr.wordpress.com/2010/01/26/ggplot2-quick-heatmap-plotting/

# Takes the average earnings by number of rooms and bedrooms
smalldf_avg = group_by(smalldf, rooms, bedrms) %>%
  summarize(avg_earns = mean(earns))


# Now we can create a heatmap (x and y here are rooms and bedrms
# respectively and the darkness of the blue indicates the average
# earnings for that specific number of rooms and bedrooms)

ggplot(smalldf_avg) + 
  geom_tile(aes(factor(rooms), factor(bedrms), fill = avg_earns)) + 
  xlab("# Rooms") + 
  ylab("# Bedrooms") + 
  ggtitle("Avg earnings by # rooms and bedrooms") + 
  scale_fill_gradient(low = "black", high = "steelblue") + 
  scale_x_discrete(expand = c(0, 0)) + 
  scale_y_discrete(expand = c(0, 0)) + 
  theme_grey() + 
  theme(panel.grid = element_blank(), axis.ticks = element_blank())


# Alternatively, we can also include the size of a dot for the
# average earnings. This adds an additional visual element
# to further emphasize the point. Of course, if we had a fourth 
# feature we are trying to show, that would take precedence.

ggplot(smalldf_avg) + 
  geom_point(aes(factor(rooms), factor(bedrms), colour = avg_earns, size = avg_earns)) + 
  scale_size_continuous(range = c(10, 30)) + 
  xlab("# Rooms") + 
  ylab("# Bedrooms") + 
  ggtitle("Avg earnings by # rooms and bedrooms") + 
  scale_colour_gradient(low = "black", high = "steelblue") + 
  theme_grey() + 
  theme(panel.grid = element_blank(), axis.ticks = element_blank())


# Note that smalldf_avg is just a sample of the entire dataset.
# It only contains 100000 of the 1 billion rows. It is harder 
# to do analysis within R on so many rows. Datasets can also be
# much larger than 1 billion rows. 

# However, the smalldf_avg table is significantly smaller as it 
# summarizes the smalldf table. In the end, if we are interested 
# in plotting avg_earns as above, we would like to use the entire
# dataset. We cannot do this in R. Instead we can use PostgreSQL, 
# then import that table into R.

# In fact, we can even use RPostgreSQL so we never have to leave
# the R environment!

library(RPostgreSQL)

# Connect to the Greenplum database
drv = dbDriver("PostgreSQL")
con = dbConnect(drv, host = "dca1-mdw1.dan.dh.greenplum.com", user = "gpadmin",
                password = "changeme", dbname = "pivotalr_demodb")

# Specify query
querystring = 
"
DROP TABLE IF EXISTS census1_avg_earns;

SELECT * 
  INTO census1_avg_earns
  FROM (SELECT rooms, bedrms, AVG(earns) AS avg_earns
          FROM census1billion_rand
         GROUP BY rooms, bedrms
         ORDER BY rooms, bedrms) foo;


SELECT * FROM census1_avg_earns;
"

start = Sys.time()
fulldf_avg = dbGetQuery(con, querystring) %>%
  arrange(rooms, bedrms) # order by rooms and bedrms
end = Sys.time()
end - start

# Now we have the average earnings by room and bedroom
# over the entire 1 billion row dataset!
head(fulldf_avg)

#Let's plot the same plots as above using the full dataset:

ggplot(fulldf_avg) + 
  geom_tile(aes(factor(rooms), factor(bedrms), fill = avg_earns)) + 
  ggtitle("Avg earnings by # rooms and bedrooms (over entire dataset)") + 
  xlab("# Rooms") + 
  ylab("# Bedrooms") +
  scale_fill_gradient(low = "black", high = "steelblue") + 
  scale_x_discrete(expand = c(0, 0)) + 
  scale_y_discrete(expand = c(0, 0)) + 
  theme_grey() + 
  theme(panel.grid = element_blank(), axis.ticks = element_blank())


ggplot(fulldf_avg) + 
  geom_point(aes(factor(rooms), factor(bedrms), colour = avg_earns, size = avg_earns)) + 
  xlab("# Rooms") + 
  ylab("# Bedrooms") + 
  scale_size_continuous(range = c(10, 30)) + 
  ggtitle("Avg earnings by # rooms and bedrooms (over entire dataset)") + 
  scale_colour_gradient(low = "black", high = "steelblue") + 
  theme_grey() + 
  theme(panel.grid = element_blank(), axis.ticks = element_blank())

# These plots make a lot more sense now as a larger number of bedrooms
# and rooms should correlate with earnings.





#####################################################
# Heatmaps in both positive and negative directions #
#####################################################

# This is just a test example to show how to illustrate
# a good plot using colour for data that are both
# positive and negative.

test = data.frame(x = rep(1:11, each=11), 
                  y = rep(c(1:11), 11), 
                  z = c(-60:60))

ggplot(test, aes(x, y, fill = z)) + 
  geom_tile() + 
  geom_text(label = as.character(-60:60)) + 
  ggtitle("Illustration of Positive and Negative") + 
  scale_fill_gradient2(low = "red", mid = "white", high = "green") + 
  scale_x_continuous(expand = c(0, 0)) + 
  scale_y_continuous(expand = c(0, 0)) + 
  theme_grey() + 
  theme(panel.grid = element_blank(), axis.ticks = element_blank())























