# remove all objects
rm(list=ls())

# Load packages 
library(pacman)
pacman::p_unload(all)

library(pacman)
p_load(tidyverse, data.table, rmarkdown, knitr, tinytex, magrittr,
       gplots, viridis, RColorBrewer, scales, grDevices, graphics,
       mapproj, ggmap, rgdal, tmap, maptools, tmaptools, foreign, skimr, lubridate
       )

#This package helps me read in shapefiles
library("sf")

#PART ONE: Reading, Developing, and Cleaning the Data

#First I read in my primary data of interest on provinces in Burkina Faso
#The primary variable of interest (the DV) is the # of defections per province that occurred during a mass defection of 75+ party officials who left the party in January 2014 and formed the basis for a new opposition party, which was eventually swept to power after BF President Compaore's ouster in October 2014.
#The data also includes a dummy variable for whether or not defections occurred, as well as province-level covariates, including ethnicity, language, urban/rural, and some data from the 2008 Afrobarometer survey on % of respondents who reported support for democracy and % of respondents who claimed they did not trust the ruling party.
#The goal of the project is to (a) display and map data on defections and (b) determine whether the distribution of defections by provinces is correlated with any of these province-level covariates.
setwd("C:/Users/awojt/Documents/Berkeley/Classes Spring 2020/Computational Methods")
provdata <- read.csv("Province data.csv")

#Here's some specs on the data
class(provdata)
#Province variable (unit of analysis)
class(provdata$�..province)
#Defector data (outcome variable)
class(provdata$defector_number)
#Sample of covariates
class(provdata$primary_ethnicity)
class(provdata$percent_demsupport2008)
#Running dim reveals the data has 45 rows (provinces) and 9 columns (variables)
dim(provdata)
#The primary variable of interest is the # of defectors by province. A basic histogram reveals that most provinces had 1-2 defectors, but some had far more)
hist(provdata$defector_number)
#Viewing the data reveals that the provinces with the highest # of defectors were Kadiogo, Yatenga, and Sanmatenga
View(provdata)
#Here's a summary of all the variables
summary(provdata)

#The provdata dataset did not fall magically out of the sky. It had to be created by merging data from a variety of sources.
#The first is data on 68 of the 75 defectors for which I have data on their home province (I lacked data on home province on 7 of them). This data comes from a signed letter by the 75 defectors when they announced their resignation: https://lefaso.net/spip.php?article57333 .
#From this I created a new csv file with data on the first and last names of the defectors and their reported province
#See this data below
defectordata <- read.csv("defector_data.csv")
#Some specs on the data
head(defectordata)
class(defectordata)
class(defectordata$Province)
dim(defectordata)
summary(defectordata) #P.S. Ouedraogo is one of the most common last names in BF; this also shows that Kadiogo has the most defectors (and there are 7 whose province is unknown)

#From this defector data, I created a column in the main province data (provdata) titled defector_number, which adds the number of defectors by province.
#Here we see that there were 68 total defectors.
sum(provdata$defector_number)
#Summary stats reveal the mean, median, and quartiles for the defection data
summary(provdata$defector_number)
#A histogram reveals that most provinces had only 1-2 defectors, but some (e.g., Kadiogo, Yatenga, and Sanmatenga) had a lot.
hist(provdata$defector_number)

#The province data also includes several additional columns, including:
#1) province: the names of the 45 provinces in BF
head(provdata$�..province)
#2) region: the region (next largest administrative unit) for each province
summary(provdata$region)
#3) binary_defector: a binary variable that reveals whether or not the province experienced defections
summary(provdata$binary_defector)
#4) urban: another dichotomous variable coded whether the province is urban/rural. (It is coded as urban if it has a city of at least 50,000, rural otherwise)
sum(provdata$urban)
#5) primary_language: factor variable for the predominant language spoken in the province (assembled from Afrobarometer data and other sources)
summary(provdata$primary_language)
#6) primary_ethnicity: factor variable for predominant ethnicity of residents in provinces (ibid)
summary(provdata$primary_ethnicity)
#7) percent_demsupport2008: integer data on the % of residents who claimed that they supported democracy from the 2008 Afrobarometer survey data (the latest survey with province-level data before the 2014 defection)
#Note that I constructed this variable by merging and cleaning data from the original survey (see below)
summary(provdata$percent_demsupport2008)
#Note that 5 provinces were not surveyed so are recorded as missing
#8) percent_donottrust2008: integer data on the % of residents who claimed in the 2008 Afrobarometer survey that they did not trust the ruling party
summary(provdata$percent_demsupport2008)
#Note that I also constructed this variable by merging and cleaning data from the original survey (see below)


#PART ONE ADDENDUM: How I constructed the percent_demsupport2008 and percent_donottrust2008 variables

#I constructed the two Afrobarometer variables by adapting them from the original survey data
#First I read in the data:
library(haven)
setwd("C:/Users/awojt/Documents/Berkeley/Classes Spring 2020/Computational Methods")
afro2008data <- read.spss("bfo_r4_data.sav", to.data.frame = TRUE)
#Then I kept only the questions that I wanted, created a new dataset titled afro2008datanew
afro2008dataupdate <- subset(afro2008data, select = c(REGION, PROVINCE, DISTRICT, Q3, Q29A, Q29B, Q29C, Q30, Q31, Q32, Q34, Q35, Q37, Q38, Q40A, Q40B, Q42A, Q42B, Q42C, Q42D, Q43, Q44A, Q45B, Q49A, Q49E, Q49F, Q79, Q88E, Q89, Q90, Q97, Q101, Q102)) 
View(afro2008dataupdate)

#From here I created some new variables using mutate()
afro2008dataupdate %<>%
  #produces new logical variable based on Q30 (do you support democracy?)
  mutate(demsupport = ifelse(Q30 == "STATEMENT 1: Democracy preferable.", T, F)) %>%
  #converts Q89 (what is highest level of education you have received?) to numeric
  mutate(education = as.numeric(Q89)) %>%
  #converts Q49E (how much do you trust the ruling party?) into numeric
  mutate(rulingpartytrust = as.numeric(Q49E))

# Then I checked for missing data
# Remove white space
afro2008dataupdate %<>%
  mutate_if(is.character, list(str_trim))
# Check for empty cells
afro2008dataupdate %>%
  # Keep only character variables 
  select_if(is.character) %>%
  # Recode character variables as 1 if cell is empty 
  mutate_all(list(~ifelse(.=="",1,0))) %>%
  # Add up empty cells for each character variable 
  summarise_all(sum, na.rm=T) %>%
  # Transpose data for visibility 
  t()

#Then I generated summary statistics for the variables of interest, sorted by province:
# I found the mean of the "rulingpartytrust" variable by province to get a sense of where the ruling party is more/less trusted.
afro2008dataupdate %>%
  group_by(PROVINCE) %>%
  summarise(rulingpartytrust_mean = mean(rulingpartytrust, na.rm=T))
# I also found the sum of total respondents who claim they supported democracy (699)
afro2008dataupdate %>%
  summarise(sum(demsupport==T))
# I then generated the # of respondents who claim they supported democracy for each province.
afro2008dataupdate %>%
  group_by(PROVINCE) %>%
  summarise(sum(demsupport==T))
#Then I found the % of respondents who claimed they support democracy for each province. This became the basis for the percent_demsupport2008 variable in the main province data!
percentdemsupport <- afro2008dataupdate %>%
  group_by(PROVINCE) %>%
  summarise((sum(demsupport==T)/n())*100)
print(percentdemsupport)
#I did the same for the % of respondents who do not "trust" the ruling party, by province (respondents who claimed that they trusted the ruling party "not at all" OR "just a little", meaning a response of 2 or 3 in my new rulingpartytrust variable)
#This became the percent_donottrust2008 variable in provdata!
percentdonottrust <- afro2008dataupdate %>%
  group_by(PROVINCE) %>%
  summarise((sum(rulingpartytrust<4)/n())*100)
print(percentdonottrust)
#For fun, I could also calculate the percentage of Burkinabe who do not "trust" the ruling party based on education levels:
afro2008dataupdate %>%
  group_by(Q89) %>%
  summarise(sum(rulingpartytrust<4)/n())
#This suggests that better educated people have less trust in the ruling party!



#PART TWO: Data Visualization I (Graphs and Plots)

#set dimensions and load themes
knitr::opts_chunk$set(fig.width=12, fig.height=8)
source("C:/Users/awojt/Documents/Berkeley/Classes Spring 2020/Computational Methods/PS239T_Spring2020 new/PS239T_Spring2020/09_r-analysis-visualization/06_setup/visualisation.R")
library(ggplot2)

#In this section, I set out to create some basic bivariate and multivariate plots to display some of my data
#First, I plot the # of defectors per province (note that I flip the x and y-axis (h/t Julia) and change the labels and scale):
plotbyprovince <- ggplot(data = provdata, aes(x = reorder(�..province, defector_number), y = defector_number)) +
  geom_bar(fill="purple", stat="identity") + labs(title="Defectors by Province, Jan 2014", x="Province", y="Number of Defectors") + coord_flip() + scale_y_continuous(breaks = c(0:10))
plotbyprovince

#Second, I test the # of defections against a few covariates. For example, I plot the # of defectors by primary ethnicity:
plotbyethnicity <- ggplot(data = provdata, aes(x = primary_ethnicity, y = defector_number)) +
  geom_bar(fill="red", stat="identity") + labs(title="Defectors by Ethnicity, Jan 2014", x="Primary Ethnicity of Home Province", y="Number of Defectors") + scale_y_continuous(breaks = c(5, 10, 15, 20, 25, 30, 35, 40, 45))
plotbyethnicity
#Here we see that ethnic Mossi account for most of the defectors. This is not surprising, however, because it is the largest ethnic group in Burkina Faso.
#We see a similar trend with primary_language, with Moore speakers (the language of the Mossi) as most prominent:
plotbylanguage <- ggplot(data = provdata, aes(x = primary_language, y = defector_number)) +
  geom_bar(fill="blue", stat="identity") + labs(title="Defectors by Primary Language, Jan 2014", x="Primary Language of Home Province", y="Number of Defectors") + scale_y_continuous(breaks = c(5, 10, 15, 20, 25, 30, 35, 40, 45))
plotbylanguage

#Third, I look at defections against the ruling party support data in a multivariate plot.
#First I create a new logical variable (defectors_yes_or_no) to stand-in for whether a province had defectors or not.
provdata %<>%
  mutate(Defections = ifelse(binary_defector==1, T, F))

#Then I use this new variable as the "color" for the bar graph that maps % of respondents who do not trust ruling party by province
plotbyrpsupport <- ggplot(data = provdata, aes(x = reorder(�..province, percent_donottrust2008), y = percent_donottrust2008, by = percent_donottrust2008, fill = Defections, color = Defections)) + geom_bar(colour="white", stat="identity") + labs(title= "Levels of Disapproval of Ruling Party by Province", x="Province", y="% of Respondents Who Do Not Trust Ruling Party") + coord_flip() + scale_y_continuous(breaks = c(5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60))
plotbyrpsupport

#Fourth, I also do the same for the variable that tracks % of respondents who support democracy
plotbydemsupport <- ggplot(data = provdata, aes(x = reorder(�..province, percent_demsupport2008), y = percent_demsupport2008, by = percent_demsupport2008, fill = Defections, color = Defections)) + geom_bar(colour="white", stat="identity") + labs(title= "Levels of Support for Democracy by Province", x="Province", y="% of Respondents Who Support Democracy") + coord_flip() + scale_y_continuous(breaks = c(5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 90))
plotbydemsupport

#Finally, I also create a boxplot that shows the divide between urban and rural areas. Here we see a pretty big bump in the # of defectors if the province is largely urban.
plotbyurban <- ggplot(provdata, fill = "Defectors") + geom_boxplot(aes(urban, defector_number, group = urban, fill = "Defectors")) + labs(title="Defectors by Urban/Rural, Jan 2014", x="Urban/Rural", y="Number of Defectors") + scale_y_continuous(breaks = c(1:10)) + scale_x_continuous(breaks = 0:1)
plotbyurban

#What have we learned? Defectors seem to come largely from ethnic Mossi, Moore-speaking, and urban provinces, but there is no obvious correlation between local levels of support for democracy or disapproval of the ruling party and defections.
#In other words, it is not clear whether defectors are "reflecting" the attitudes of the population in their home provinces (with the exception of maybe Kadiogo (where the capital Ouagadougou is located), the outlier)
#To test the significance of these variables, I ran a series of simply linear regressions (on both # of defectors and a binary of whether or not there were defections in the province)
lm(provdata$defector_number ~ provdata$percent_donottrust2008)
lm(provdata$binary_defector ~ provdata$percent_donottrust2008)
#Note that the relationship is also not significant if we test by predominant ethnicity or language, whether the province was primarily urban/rural, or based on % who support democracy in the province.
lm(provdata$defector_number ~ provdata$primary_ethnicity)
lm(provdata$defector_number ~ provdata$primary_language)
lm(provdata$defector_number ~ provdata$urban)
lm(provdata$defector_number ~ provdata$percent_demsupport2008)
lm(provdata$binary_defector ~ provdata$percent_demsupport2008)
#None are significant (although of course I didn't spend much time on the specifications)



#PART THREE: Data Visualization II (Maps!)

#Finally, I also seek to display the data I have spatially, so I make a series of maps. I use R to merge the shapefile of BF with my provdata dataset but then move to QGIS to complete the maps.

#First I download the shapefile of Burkina Faso provincial boundaries (acquired from https://data.humdata.org/dataset/burkina-faso-administrative-boundaries )
setwd("C:/Users/awojt/Documents/Berkeley/Classes Spring 2020/Computational Methods/BF_shapefile")
BFshapefile <- read.dbf("C:/Users/awojt/Documents/Berkeley/Classes Spring 2020/Computational Methods/BF_shapefile/bfa_admbnda_adm2_igb_20200323.dbf", as.is = T)

#Some specs on the shapefile
class(BFshapefile)
dim(BFshapefile)
plot(BFshapefile)
names(BFshapefile)
slotNames(BFshapefile)

#Then I prepare to merge the province data with the shapefile by creating a common syntax
write.csv(provdata, "province_data.csv") #Save dataset to file
#I then manually added a column (ADM2_PCODE) to match it with the shapefile and reloaded the data
province_data <- read.csv("province_data.csv")
View(province_data)
#Then I merged the shapefile with the province data (h/t to Juan for help on this)
mergedBurkina <- dplyr::inner_join(province_data, BFshapefile, by = "ADM2_PCODE")
View(mergedBurkina)
#Finally, I overwrote the original shapefile with the new one. 
write.dbf(mergedBurkina, "bfa_admbnda_adm2_igb_20200323.dbf")
#From here, I mapped the rest in QGIS!
